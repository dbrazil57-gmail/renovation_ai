import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:renovision_ai/app_access.dart';
import 'package:renovision_ai/secret_store.dart';

/// Synthetic authority only. No real key, receipt, hosting or payment.
class AccessFixture {
  late SimpleKeyPairData issuer;
  late AccessConfiguration configuration;
  final SessionSecretStore vault = SessionSecretStore();
  DateTime now = DateTime.utc(2026, 11, 28, 12);
  late DateTime entitlementExpires;
  int calls = 0, responseStatus = 200;
  bool badGrant = false, failNetwork = false;
  Map<String, dynamic>? lastRequest;
  String? lastToken;

  Future<void> initialise() async {
    entitlementExpires = now.add(const Duration(days: 30));
    issuer = await (await Ed25519().newKeyPair()).extract();
    configuration = AccessConfiguration(
      mode: 'licensed',
      service: Uri.parse('https://access.example.test'),
      verificationKeys: {'test-key': issuer.publicKey},
    );
  }

  Future<String> token(
    String device, {
    Map<String, Object?> overrides = const {},
  }) async {
    int seconds(DateTime value) => value.millisecondsSinceEpoch ~/ 1000;
    final data = {
      'v': 1,
      'kid': 'test-key',
      'iss': 'renovision-access',
      'aud': 'renovision',
      'device': device,
      'licence': 'synthetic-licence',
      'plan': 'standard',
      'iat': seconds(now),
      'nbf': seconds(now),
      'exp': seconds(entitlementExpires),
      'refreshBy': seconds(
        now.add(const Duration(hours: 24)).isBefore(entitlementExpires)
            ? now.add(const Duration(hours: 24))
            : entitlementExpires,
      ),
      ...overrides,
    };
    final payload = accessBase64(utf8.encode(jsonEncode(data)));
    final signature = await Ed25519().sign(
      utf8.encode('RV1.$payload'),
      keyPair: issuer,
    );
    return 'RV1.$payload.${accessBase64(signature.bytes)}';
  }

  AppAccess create({SecretStore? storage}) => AppAccess(
    configuration: configuration,
    vault: storage ?? vault,
    clock: () => now,
    clientFactory: () => MockClient((request) async {
      calls++;
      if (failNetwork) throw Exception('synthetic offline');
      final envelope = jsonDecode(request.body) as Map;
      final payload = envelope['payload'] as String;
      lastRequest = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(payload))),
      ) as Map<String, dynamic>;
      final public = SimplePublicKey(
        base64Url.decode(
          base64Url.normalize(lastRequest!['publicKey'] as String),
        ),
        type: KeyPairType.ed25519,
      );
      if (!await Ed25519().verify(
        utf8.encode('RVREQ1.$payload'),
        signature: Signature(
          base64Url.decode(
            base64Url.normalize(envelope['signature'] as String),
          ),
          publicKey: public,
        ),
      )) {
        throw StateError('Bad installation proof');
      }
      if (responseStatus != 200) return http.Response('{}', responseStatus);
      lastToken = await token(
        lastRequest!['device'] as String,
        overrides: request.url.path.endsWith('/trial')
            ? {'plan': 'trial'}
            : const {},
      );
      return http.Response(
        jsonEncode({'grant': badGrant ? 'forged' : lastToken}),
        200,
      );
    }),
  );
}
