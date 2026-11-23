import 'dart:async';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../constants/app_constants.dart';
import '../storage/storage_service.dart';

/// In-App Purchase service architecture.
class PurchaseService {
  static final PurchaseService _instance = PurchaseService._internal();
  factory PurchaseService() => _instance;
  PurchaseService._internal();

  InAppPurchase? _inAppPurchase;
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  bool _isAvailable = false;
  StorageService? _storage;

  bool get isAvailable => _isAvailable;

  Future<void> initialize(StorageService storage, {InAppPurchase? iapInstance}) async {
    _storage = storage;
    try {
      _inAppPurchase = iapInstance ?? InAppPurchase.instance;
      _isAvailable = await _inAppPurchase!.isAvailable();
      if (_isAvailable) {
        _subscription = _inAppPurchase!.purchaseStream.listen(
          _handlePurchaseUpdates,
          onDone: () => _subscription?.cancel(),
          onError: (_) {},
        );
      }
    } catch (_) {
      _isAvailable = false;
    }
  }

  void _handlePurchaseUpdates(List<PurchaseDetails> purchaseDetailsList) {
    if (_inAppPurchase == null) return;
    for (final purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.purchased ||
          purchaseDetails.status == PurchaseStatus.restored) {
        if (purchaseDetails.productID == AppConstants.iapRemoveAds ||
            purchaseDetails.productID == AppConstants.iapPremiumPass) {
          _storage?.setPremium(true);
        } else if (purchaseDetails.productID == AppConstants.iapUnlimitedHints) {
          _storage?.setPremium(true);
          _storage?.addHints(999);
        }
      }

      if (purchaseDetails.pendingCompletePurchase) {
        _inAppPurchase!.completePurchase(purchaseDetails);
      }
    }
  }

  /// Initiates buy for product.
  Future<bool> buyProduct(String productId) async {
    if (!_isAvailable || _inAppPurchase == null) return false;
    try {
      final response = await _inAppPurchase!.queryProductDetails({productId});
      if (response.notFoundIDs.isNotEmpty || response.productDetails.isEmpty) {
        return false;
      }
      final product = response.productDetails.first;
      final purchaseParam = PurchaseParam(productDetails: product);
      return await _inAppPurchase!.buyNonConsumable(purchaseParam: purchaseParam);
    } catch (_) {
      return false;
    }
  }

  /// Restores previous purchases.
  Future<void> restorePurchases() async {
    if (!_isAvailable || _inAppPurchase == null) return;
    try {
      await _inAppPurchase!.restorePurchases();
    } catch (_) {}
  }

  void dispose() {
    _subscription?.cancel();
  }
}
