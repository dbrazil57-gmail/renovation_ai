import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart' as hashes;
import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'secret_store.dart';

enum AccessPlan { trial, standard }

class AccessFailure implements Exception {
  final String message;
  const AccessFailure(this.message);
  @override
  String toString() => message;
}

/// Private builds retain the owner's existing access. A store build must opt in
/// explicitly; an unknown mode fails closed rather than becoming a private build.
class AccessConfiguration {
  final String mode, audience, issuer;
  final Uri? service;
  final Map<String, SimplePublicKey> verificationKeys;
  const AccessConfiguration({
    this.mode = 'private',
    this.audience = 'renovision',
    this.issuer = 'renovision-access',
    this.service,
    this.verificationKeys = const {},
  });

  factory AccessConfiguration.fromEnvironment() {
    const mode = String.fromEnvironment(
      'RENOVISION_ACCESS_MODE',
      defaultValue: 'private',
    );
    const url = String.fromEnvironment('RENOVISION_ACCESS_URL');
    const keysJson = String.fromEnvironment(
      'RENOVISION_ACCESS_PUBLIC_KEYS',
      defaultValue: '{}',
    );
    final keys = <String, SimplePublicKey>{};
    try {
      final decoded = jsonDecode(keysJson) as Map;
      for (final entry in decoded.entries) {
        final bytes = base64Url.decode(
          base64Url.normalize(entry.value as String),
        );
        if (entry.key is! String || bytes.length != 32) {
          throw const FormatException();
        }
        keys[entry.key as String] = SimplePublicKey(
          bytes,
          type: KeyPairType.ed25519,
        );
      }
    } catch (_) {
      keys.clear();
    }
    return AccessConfiguration(
      mode: mode,
      service: Uri.tryParse(url),
      verificationKeys: Map.unmodifiable(keys),
    );
  }

  bool get privateBuild => mode == 'private';
  bool get configured =>
      mode == 'licensed' &&
      service != null &&
      service!.scheme == 'https' &&
      service!.host.isNotEmpty &&
      service!.userInfo.isEmpty &&
      !service!.hasQuery &&
      !service!.hasFragment &&
      verificationKeys.isNotEmpty;
}

class VerifiedAccess {
  final String licenceId, device;
  final AccessPlan plan;
  final DateTime issued, starts, expires, refreshBy;
  const VerifiedAccess({
    required this.licenceId,
    required this.device,
    required this.plan,
    required this.issued,
    required this.starts,
    required this.expires,
    required this.refreshBy,
  });
  bool permits(DateTime now) =>
      !now.isBefore(starts) && now.isBefore(expires) && now.isBefore(refreshBy);
}

String accessBase64(List<int> bytes) =>
    base64Url.encode(bytes).replaceAll('=', '');

/// `RV1.<base64url JSON>.<Ed25519 signature over "RV1.<JSON segment>">`.
/// The pinned key and fixed algorithm cannot be supplied by a licence response.
Future<VerifiedAccess> verifyAccessGrant(
  String token, {
  required AccessConfiguration configuration,
  required String device,
}) async {
  try {
    if (token.length > 8192) throw const FormatException();
    final parts = token.split('.');
    if (parts.length != 3 || parts.first != 'RV1') {
      throw const FormatException();
    }
    final data = jsonDecode(
      utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
    ) as Map;
    final key = configuration.verificationKeys[data['kid']];
    if (key == null ||
        data['v'] != 1 ||
        data['iss'] != configuration.issuer ||
        data['aud'] != configuration.audience ||
        data['device'] != device ||
        data['licence'] is! String ||
        (data['licence'] as String).isEmpty ||
        !['trial', 'standard'].contains(data['plan'])) {
      throw const FormatException();
    }
    final signature = base64Url.decode(base64Url.normalize(parts[2]));
    if (signature.length != 64 ||
        !await Ed25519().verify(
          utf8.encode('RV1.${parts[1]}'),
          signature: Signature(signature, publicKey: key),
        )) {
      throw const FormatException();
    }
    DateTime time(String key) {
      final value = data[key];
      if (value is! int || value <= 0 || value > 4102444800) {
        throw const FormatException();
      }
      return DateTime.fromMillisecondsSinceEpoch(value * 1000, isUtc: true);
    }

    final grant = VerifiedAccess(
      licenceId: data['licence'] as String,
      device: device,
      plan: data['plan'] == 'trial' ? AccessPlan.trial : AccessPlan.standard,
      issued: time('iat'),
      starts: time('nbf'),
      expires: time('exp'),
      refreshBy: time('refreshBy'),
    );
    if (grant.starts.isAfter(grant.issued) ||
        !grant.expires.isAfter(grant.issued) ||
        !grant.refreshBy.isAfter(grant.issued) ||
        grant.refreshBy.isAfter(grant.expires) ||
        grant.refreshBy.difference(grant.issued) > const Duration(hours: 48)) {
      throw const FormatException();
    }
    return grant;
  } catch (_) {
    throw const AccessFailure(
      'The app licence could not be verified. Restore access in Settings.',
    );
  }
}

/// Software access is independent of BYO AI credentials and AI credit budgets.
/// Store purchase callbacks alone never unlock work: the service must verify the
/// receipt/subscription and return a signed, installation-bound entitlement.
class AppAccess extends ChangeNotifier {
  final AccessConfiguration configuration;
  final SecretStore vault;
  final http.Client Function() clientFactory;
  final DateTime Function() clock;
  VerifiedAccess? _grant;
  VerifiedAccess? get grant => _grant;
  String? notice;
  bool ready = false, busy = false;
  SimpleKeyPairData? _installationKey;
  String? _token;
  DateTime? _highWater;
  Future<void>? _loading;
  bool _disposed = false;

  AppAccess({
    AccessConfiguration? configuration,
    SecretStore? vault,
    http.Client Function()? clientFactory,
    DateTime Function()? clock,
  }) : configuration = configuration ?? AccessConfiguration.fromEnvironment(),
       vault = vault ?? createSecretStore(provider: 'access'),
       clientFactory = clientFactory ?? http.Client.new,
       clock = clock ?? DateTime.now;

  bool get privateBuild => configuration.privateBuild;
  String? get deviceId {
    final key = _installationKey;
    return key == null
        ? null
        : hashes.sha256.convert(key.publicKey.bytes).toString();
  }

  bool get clockMovedBack =>
      _highWater != null &&
      clock().toUtc().isBefore(
        _highWater!.subtract(const Duration(minutes: 5)),
      );
  bool get canCreate =>
      privateBuild ||
      (ready &&
          !clockMovedBack &&
          grant != null &&
          !grant!.issued.isAfter(
            clock().toUtc().add(const Duration(minutes: 5)),
          ) &&
          grant!.permits(clock().toUtc()));
  String get status => privateBuild
      ? 'Private test build'
      : !ready
      ? 'Checking app access'
      : clockMovedBack
      ? 'Check device date and restore access'
      : grant == null
      ? 'Trial or Standard access required'
      : !clock().toUtc().isBefore(grant!.expires)
      ? 'Access expired'
      : !grant!.permits(clock().toUtc())
      ? 'Connect to refresh access'
      : grant!.plan == AccessPlan.trial
      ? 'Trial active'
      : 'Standard active';

  void _changed() {
    if (!_disposed) notifyListeners();
  }

  Future<void> load() => _loading ??= _load();
  Future<void> _load() async {
    if (privateBuild) {
      ready = true;
      _changed();
      return;
    }
    try {
      if (!configuration.configured) {
        throw const AccessFailure(
          'Licensing is not configured for this build. Existing projects can still be opened and exported.',
        );
      }
      final saved = await vault.read();
      if (saved != null) {
        final data = jsonDecode(saved) as Map;
        final seed = base64Url.decode(
          base64Url.normalize(data['seed'] as String),
        );
        if (seed.length != 32) throw const FormatException();
        _installationKey = await (await Ed25519().newKeyPairFromSeed(seed))
            .extract();
        final high = data['lastSeen'];
        if (high is String) _highWater = DateTime.parse(high).toUtc();
        if (data['grant'] is String) {
          _token = data['grant'] as String;
          _grant = await verifyAccessGrant(
            _token!,
            configuration: configuration,
            device: deviceId!,
          );
        }
      } else {
        _installationKey = await (await Ed25519().newKeyPair()).extract();
      }
      await _persist();
    } catch (error) {
      _grant = null;
      notice = error is AccessFailure ? error.message : 'App access could not be restored. Check device storage and restore access in Settings.';
      // Never silently replace a damaged installation identity or grant.
    } finally {
      ready = true;
      _changed();
    }
  }

  Future<void> _persist() async {
    final key = _installationKey;
    if (key == null) return;
    final now = clock().toUtc();
    if (_highWater == null || now.isAfter(_highWater!)) _highWater = now;
    await vault.write(
      jsonEncode({
        'v': 1,
        'seed': accessBase64(key.bytes),
        'grant': _token,
        'lastSeen': _highWater!.toIso8601String(),
      }),
    );
  }

  /// Called before a paid AI request, not after a provider could have billed it.
  Future<void> requireCreation({bool online = false}) async {
    if (privateBuild) {
      return;
    }
    await load();
    if (!privateBuild && online && grant != null && !clockMovedBack) {
      // AI already needs the internet: check device/revocation state before a
      // provider can charge. Offline leases cover local work, not online AI.
      await refresh();
    } else if (!canCreate &&
        configuration.configured &&
        grant != null &&
        !clockMovedBack &&
        clock().toUtc().isBefore(grant!.expires)) {
      await refresh();
    }
    if (!canCreate) {
      throw AccessFailure(
        '$status. Open App access in Settings. Your saved work remains available.',
      );
    }
    if (!privateBuild) {
      try {
        await _persist();
      } catch (_) {
        throw const AccessFailure(
          'App access could not be saved. Check storage before starting new work.',
        );
      }
    }
  }

  /// No card is collected. Eligibility and original trial expiry belong to the
  /// service, never a reinstall-resettable local counter.
  Future<void> startTrial() => _request('trial', const {});
  Future<void> refresh() => _request('refresh', const {});

  /// Only the native Samsung purchase/owned-list integration calls this method.
  /// The receipt is checked by the service; it is not proof by itself.
  Future<void> verifySamsungPurchase(String purchaseId) =>
      _request('samsung', {'purchaseId': purchaseId});

  Future<void> _request(String operation, Map<String, Object?> details) async {
    await load();
    if (busy) {
      throw const AccessFailure('An access request is already running.');
    }
    if (!configuration.configured || _installationKey == null || privateBuild) {
      throw const AccessFailure(
        'App activation is not configured in this build.',
      );
    }
    busy = true;
    notice = null;
    _changed();
    http.Client? client;
    try {
      client = clientFactory();
      final key = _installationKey!;
      final random = Random.secure();
      final nonce = accessBase64(List.generate(24, (_) => random.nextInt(256)));
      final payload = accessBase64(
        utf8.encode(
          jsonEncode({
            'v': 1,
            'operation': operation,
            'aud': configuration.audience,
            'device': deviceId,
            'publicKey': accessBase64(key.publicKey.bytes),
            'time': clock().toUtc().millisecondsSinceEpoch ~/ 1000,
            'nonce': nonce,
            ...details,
          }),
        ),
      );
      final signature = await Ed25519().sign(
        utf8.encode('RVREQ1.$payload'),
        keyPair: key,
      );
      final base = configuration.service!.toString().replaceFirst(
        RegExp(r'/+$'),
        '',
      );
      final request =
          http.Request('POST', Uri.parse('$base/v1/access/$operation'))
            ..followRedirects = false
            ..headers['Content-Type'] = 'application/json'
            ..body = jsonEncode({
              'payload': payload,
              'signature': accessBase64(signature.bytes),
            });
      final streamed = await client
          .send(request)
          .timeout(const Duration(seconds: 20));
      if ([401, 403, 410].contains(streamed.statusCode)) {
        _grant = null;
        _token = null;
        await _persist();
        throw const AccessFailure(
          'Access is unavailable or has ended. Restore the purchase or contact support.',
        );
      }
      if (streamed.statusCode == 409) {
        throw const AccessFailure(
          'This licence is active on another device. Use the verified device-transfer process.',
        );
      }
      if (streamed.statusCode != 200) {
        throw const AccessFailure(
          'The access service could not complete the request. Try again later.',
        );
      }
      final bytes = <int>[];
      await for (final chunk in streamed.stream.timeout(
        const Duration(seconds: 20),
      )) {
        bytes.addAll(chunk);
        if (bytes.length > 12000) throw const FormatException();
      }
      final body = jsonDecode(utf8.decode(bytes)) as Map;
      final token = body['grant'] as String;
      final checked = await verifyAccessGrant(
        token,
        configuration: configuration,
        device: deviceId!,
      );
      final now = clock().toUtc();
      if (!checked.permits(now) ||
          checked.issued.isAfter(now.add(const Duration(minutes: 5))) ||
          now.difference(checked.issued) > const Duration(minutes: 5) ||
          (grant != null && checked.issued.isBefore(grant!.issued))) {
        throw const AccessFailure(
          'Access could not be refreshed. Check your device date and time.',
        );
      }
      // Publish only after the verified grant has been durably saved.
      final oldToken = _token;
      final oldHighWater = _highWater;
      _token = token;
      // A fresh signed online response also permits recovery after correcting
      // an accidentally advanced device clock. A cached token cannot do this.
      _highWater = now;
      try {
        await _persist();
      } catch (_) {
        _token = oldToken;
        _highWater = oldHighWater;
        rethrow;
      }
      _grant = checked;
    } catch (error) {
      notice = error is AccessFailure ? error.message : 'App access could not be checked. Try again when connected. If you have already paid, use Restore purchase.';
      throw AccessFailure(notice!);
    } finally {
      client?.close();
      busy = false;
      _changed();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
