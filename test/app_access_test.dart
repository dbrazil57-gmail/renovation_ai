import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:renovision_ai/app_access.dart';
import 'package:renovision_ai/secret_store.dart';

import 'support/access_fixture.dart';

class FailingAccessVault extends SessionSecretStore {
  bool fail = false;
  @override
  Future<void> write(String key) async {
    if (fail) throw StateError('synthetic full disk');
    await super.write(key);
  }
}

void main() {
  late AccessFixture fixture;
  late AppAccess access;
  setUp(() async {
    fixture = AccessFixture();
    await fixture.initialise();
    access = fixture.create();
  });
  tearDown(() => access.dispose());

  test('private builds do not read the licence vault or expire', () async {
    final vault = FailingAccessVault()..fail = true;
    final private = AppAccess(vault: vault);
    await private.requireCreation(online: true);
    expect(private.canCreate, isTrue);
    expect(await vault.read(), isNull);
    private.dispose();
  });
  test('unknown mode and missing config fail closed', () async {
    for (final mode in ['licenced-typo', 'licensed']) {
      final locked = AppAccess(
        configuration: AccessConfiguration(mode: mode),
        vault: SessionSecretStore(),
      );
      await expectLater(
        locked.requireCreation(),
        throwsA(isA<AccessFailure>()),
      );
      expect(locked.canCreate, isFalse);
      locked.dispose();
    }
  });
  test('HTTP or credential-bearing services cannot be configured', () {
    for (final address in [
      'http://access.example.test',
      'https://key@access.example.test',
      'https://access.example.test/?key=x',
    ]) {
      expect(
        AccessConfiguration(
          mode: 'licensed',
          service: Uri.parse(address),
          verificationKeys: fixture.configuration.verificationKeys,
        ).configured,
        isFalse,
      );
    }
  });
  test(
    'trial requires a signed server grant; installation signs its request',
    () async {
      await access.load();
      expect(access.canCreate, isFalse);
      await access.startTrial();
      expect(access.grant!.plan, AccessPlan.trial);
      expect(access.canCreate, isTrue);
      expect(fixture.lastRequest!['operation'], 'trial');
      expect(fixture.lastRequest!.keys, isNot(contains('email')));
      expect(fixture.lastRequest!.keys, isNot(contains('imei')));
      expect(fixture.lastRequest!['device'], access.deviceId);
    },
  );
  test('edited payload and wrong installation cannot unlock', () async {
    await access.load();
    final token = await fixture.token(access.deviceId!);
    final parts = token.split('.');
    final edited = jsonDecode(
      utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
    ) as Map;
    edited['exp'] = 4000000000;
    final forged =
        'RV1.${accessBase64(utf8.encode(jsonEncode(edited)))}.${parts[2]}';
    for (final candidate in [forged, token]) {
      await expectLater(
        verifyAccessGrant(
          candidate,
          configuration: fixture.configuration,
          device: candidate == forged ? access.deviceId! : 'another-device',
        ),
        throwsA(isA<AccessFailure>()),
      );
    }
  });
  test(
    'rejects wrong audience, issuer, key, plan and excessive offline lease',
    () async {
      await access.load();
      for (final overrides in <Map<String, Object?>>[
        {'aud': 'different-app'},
        {'iss': 'untrusted'},
        {'kid': 'remote-key'},
        {'plan': 'unlimited'},
        {'v': 2},
        {'exp': 'tomorrow'},
        {
          'refreshBy':
              fixture.now
                  .add(const Duration(hours: 49))
                  .millisecondsSinceEpoch ~/
              1000,
        },
      ]) {
        final token = await fixture.token(
          access.deviceId!,
          overrides: overrides,
        );
        await expectLater(
          verifyAccessGrant(
            token,
            configuration: fixture.configuration,
            device: access.deviceId!,
          ),
          throwsA(isA<AccessFailure>()),
        );
      }
    },
  );
  test('a different signing key does not verify', () async {
    await access.load();
    final other = await (await Ed25519().newKeyPair()).extractPublicKey();
    await expectLater(
      verifyAccessGrant(
        await fixture.token(access.deviceId!),
        configuration: AccessConfiguration(
          verificationKeys: {'test-key': other},
        ),
        device: access.deviceId!,
      ),
      throwsA(isA<AccessFailure>()),
    );
  });
  test(
    'licence, identity and bounded offline access survive restart',
    () async {
      await access.startTrial();
      final originalDevice = access.deviceId;
      final reopened = fixture.create();
      await reopened.load();
      expect(reopened.deviceId, originalDevice);
      expect(reopened.canCreate, isTrue);
      expect(fixture.calls, 1);
      reopened.dispose();
    },
  );
  test('each online AI action checks the service; offline local lease remains bounded', () async {
    await access.startTrial();
    await access.requireCreation(online: true);
    expect(fixture.calls, 2);
    fixture.failNetwork = true;
    await access.requireCreation();
    await expectLater(
      access.requireCreation(online: true),
      throwsA(isA<AccessFailure>()),
    );
    fixture.now = fixture.now.add(const Duration(hours: 25));
    await expectLater(access.requireCreation(), throwsA(isA<AccessFailure>()));
    expect(access.canCreate, isFalse);
  });
  test(
    'expiry and clock rollback deny new work without deleting the grant',
    () async {
      await access.startTrial();
      fixture.now = fixture.now.subtract(const Duration(hours: 1));
      expect(access.clockMovedBack, isTrue);
      await expectLater(
        access.requireCreation(),
        throwsA(isA<AccessFailure>()),
      );
      fixture.now = fixture.now.add(const Duration(days: 32));
      expect(access.status, 'Access expired');
      expect(access.grant, isNotNull);
    },
  );
  test('revoked access is cleared and stays revoked after restart', () async {
    await access.startTrial();
    fixture.responseStatus = 410;
    await expectLater(access.refresh(), throwsA(isA<AccessFailure>()));
    expect(access.canCreate, isFalse);
    final reopened = fixture.create();
    await reopened.load();
    expect(reopened.grant, isNull);
    reopened.dispose();
  });
  test(
    'fresh online verification recovers after fixing a wrongly advanced clock',
    () async {
      await access.startTrial();
      final saved = jsonDecode((await fixture.vault.read())!) as Map;
      saved['lastSeen'] = fixture.now
          .add(const Duration(days: 2))
          .toIso8601String();
      await fixture.vault.write(jsonEncode(saved));
      final reopened = fixture.create();
      await reopened.load();
      expect(reopened.clockMovedBack, isTrue);
      expect(reopened.canCreate, isFalse);
      await reopened.refresh();
      expect(reopened.clockMovedBack, isFalse);
      expect(reopened.canCreate, isTrue);
      reopened.dispose();
    },
  );
  test('device conflict never unlocks an installation', () async {
    fixture.responseStatus = 409;
    await expectLater(
      access.verifySamsungPurchase('synthetic-receipt'),
      throwsA(isA<AccessFailure>()),
    );
    expect(access.canCreate, isFalse);
  });
  test('forged service reply does not replace a valid licence', () async {
    await access.startTrial();
    fixture.badGrant = true;
    await expectLater(access.refresh(), throwsA(isA<AccessFailure>()));
    expect(access.grant!.plan, AccessPlan.trial);
    expect(access.canCreate, isTrue);
  });
  test('storage failure cannot publish a paid entitlement', () async {
    final vault = FailingAccessVault();
    final failing = fixture.create(storage: vault);
    await failing.load();
    vault.fail = true;
    await expectLater(
      failing.verifySamsungPurchase('synthetic-receipt'),
      throwsA(isA<AccessFailure>()),
    );
    expect(failing.canCreate, isFalse);
    failing.dispose();
  });
}
