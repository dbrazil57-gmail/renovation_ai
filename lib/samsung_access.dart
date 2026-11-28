import 'package:flutter/services.dart';

import 'app_access.dart';

class SamsungPurchase {
  final String productId, purchaseId;
  const SamsungPurchase(this.productId, this.purchaseId);
}

/// Adapter contract for the official Samsung SDK. The SDK requires a Samsung
/// developer download/login; it is not bundled in private APKs. A missing native
/// adapter reports unavailable and can never grant a simulated purchase.
abstract class SamsungBilling {
  Future<bool> available();
  Future<SamsungPurchase?> purchase(String productId);
  Future<List<SamsungPurchase>> owned();
}

class SamsungMethodChannel implements SamsungBilling {
  static const channel = MethodChannel('renovision/samsung_iap');
  @override
  Future<bool> available() async {
    try {
      return await channel.invokeMethod<bool>('available') == true;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }

  SamsungPurchase _read(Map value) {
    if (value['productId'] is! String ||
        value['purchaseId'] is! String ||
        (value['purchaseId'] as String).isEmpty) {
      throw const AccessFailure('Samsung did not return a purchase to verify.');
    }
    return SamsungPurchase(
      value['productId'] as String,
      value['purchaseId'] as String,
    );
  }

  @override
  Future<SamsungPurchase?> purchase(String productId) async {
    final response = await channel.invokeMapMethod<String, dynamic>(
      'purchase',
      {'productId': productId},
    );
    return response == null ? null : _read(response);
  }

  @override
  Future<List<SamsungPurchase>> owned() async {
    final response = await channel.invokeListMethod<dynamic>('owned');
    return (response ?? []).map((item) => _read(item as Map)).toList();
  }
}

class SamsungAppAccess {
  final AppAccess access;
  final SamsungBilling billing;
  final String productId;
  const SamsungAppAccess({
    required this.access,
    required this.billing,
    this.productId = const String.fromEnvironment(
      'RENOVISION_SAMSUNG_STANDARD_PRODUCT',
    ),
  });
  Future<bool> available() async =>
      !access.privateBuild &&
      access.configuration.configured &&
      productId.isNotEmpty &&
      await billing.available();

  Future<void> purchase() async {
    if (!await available()) {
      throw const AccessFailure(
        'Samsung checkout is not configured in this build.',
      );
    }
    final result = await billing.purchase(productId);
    if (result == null) return; // Cancelled: retain the current access state.
    await _verify(result);
  }

  Future<void> restore() async {
    if (!await available()) {
      throw const AccessFailure(
        'Samsung purchase recovery is not configured in this build.',
      );
    }
    final purchases = (await billing.owned())
        .where((p) => p.productId == productId)
        .toList();
    if (purchases.isEmpty) {
      throw const AccessFailure(
        'No active Standard purchase was found for this Samsung account.',
      );
    }
    // A service error is not a reason to silently try charging for another item.
    await _verify(purchases.first);
  }

  Future<void> _verify(SamsungPurchase purchase) async {
    if (purchase.productId != productId) {
      throw const AccessFailure('The purchase does not match Standard access.');
    }
    await access.verifySamsungPurchase(purchase.purchaseId);
  }
}
