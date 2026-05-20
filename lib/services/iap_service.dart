import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

class IAPService {
  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  static final IAPService _instance = IAPService._internal();
  factory IAPService() => _instance;
  IAPService._internal();

  void initialize() {
    final Stream<List<PurchaseDetails>> purchaseUpdated = _iap.purchaseStream;
    _subscription?.cancel();
    _subscription = purchaseUpdated.listen(
      (purchaseDetailsList) {
        _listenToPurchaseUpdated(purchaseDetailsList);
      },
      onDone: () {
        _subscription?.cancel();
        _subscription = null;
      },
      onError: (error) {
        debugPrint('Purchase stream error: $error');
      },
    );
  }

  Future<void> _listenToPurchaseUpdated(
    List<PurchaseDetails> purchaseDetailsList,
  ) async {
    for (var purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        // Pending — UI can reflect this state if needed.
      } else if (purchaseDetails.status == PurchaseStatus.error) {
        debugPrint('Purchase error: ${purchaseDetails.error}');
      } else if (purchaseDetails.status == PurchaseStatus.purchased ||
          purchaseDetails.status == PurchaseStatus.restored) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('is_premium', true);
        if (purchaseDetails.pendingCompletePurchase) {
          await _iap.completePurchase(purchaseDetails);
        }
      }
    }
  }

  Future<bool> buyPro() async {
    final bool available = await _iap.isAvailable();
    if (!available) return false;

    const Set<String> kIds = <String>{'chaos_pro_v1'};
    final ProductDetailsResponse response = await _iap.queryProductDetails(
      kIds,
    );
    if (response.notFoundIDs.isNotEmpty) {
      debugPrint('IAP product not found: ${response.notFoundIDs}');
    }

    if (response.productDetails.isEmpty) return false;

    final PurchaseParam purchaseParam = PurchaseParam(
      productDetails: response.productDetails.first,
    );
    return _iap.buyNonConsumable(purchaseParam: purchaseParam);
  }

  Future<void> restorePurchases() async {
    final bool available = await _iap.isAvailable();
    if (!available) return;
    await _iap.restorePurchases();
  }

  void dispose() {
    _subscription?.cancel();
    _subscription = null;
  }
}
