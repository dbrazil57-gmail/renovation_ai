import 'package:flutter_test/flutter_test.dart';
import 'package:renovision_ai/app_access.dart';
import 'package:renovision_ai/samsung_access.dart';

import 'support/access_fixture.dart';

class FakeSamsungBilling implements SamsungBilling {
  bool ready = true;
  SamsungPurchase? result = const SamsungPurchase(
    'standard-monthly',
    'synthetic-receipt',
  );
  List<SamsungPurchase> products = const [];
  int purchaseCalls = 0;
  @override
  Future<bool> available() async => ready;
  @override
  Future<SamsungPurchase?> purchase(String productId) async {
    purchaseCalls++;
    return result;
  }

  @override
  Future<List<SamsungPurchase>> owned() async => products;
}

void main() {
  late AccessFixture fixture;
  late AppAccess access;
  late FakeSamsungBilling billing;
  late SamsungAppAccess samsung;
  setUp(() async {
    fixture = AccessFixture();
    await fixture.initialise();
    access = fixture.create();
    billing = FakeSamsungBilling();
    samsung = SamsungAppAccess(
      access: access,
      billing: billing,
      productId: 'standard-monthly',
    );
  });
  tearDown(() => access.dispose());
  test(
    'purchase callback unlocks only after signed receipt verification',
    () async {
      fixture.badGrant = true;
      await expectLater(samsung.purchase(), throwsA(isA<AccessFailure>()));
      expect(access.canCreate, isFalse);
      fixture.badGrant = false;
      await samsung.purchase();
      expect(access.grant!.plan, AccessPlan.standard);
      expect(fixture.lastRequest!['purchaseId'], 'synthetic-receipt');
    },
  );
  test(
    'cancelling checkout preserves access and does not call the service',
    () async {
      await access.startTrial();
      final before = fixture.calls;
      billing.result = null;
      await samsung.purchase();
      expect(fixture.calls, before);
      expect(access.grant!.plan, AccessPlan.trial);
    },
  );
  test(
    'restore filters owned products and verifies the matching receipt',
    () async {
      billing.products = const [
        SamsungPurchase('different-product', 'ignore'),
        SamsungPurchase('standard-monthly', 'restore-receipt'),
      ];
      await samsung.restore();
      expect(access.canCreate, isTrue);
      expect(fixture.lastRequest!['purchaseId'], 'restore-receipt');
      expect(billing.purchaseCalls, 0);
    },
  );
  test(
    'wrong product and unavailable SDK cannot unlock or start checkout',
    () async {
      billing.result = const SamsungPurchase('different-product', 'ignore');
      await expectLater(samsung.purchase(), throwsA(isA<AccessFailure>()));
      expect(fixture.calls, 0);
      billing.ready = false;
      await expectLater(samsung.purchase(), throwsA(isA<AccessFailure>()));
      expect(billing.purchaseCalls, 1);
      expect(access.canCreate, isFalse);
    },
  );
  test('missing native SDK is reported unavailable', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    expect(await SamsungMethodChannel().available(), isFalse);
  });
}
