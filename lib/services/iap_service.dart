import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

class IAPService {
  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  bool _isAvailable = false;
  List<ProductDetails> _products = [];

  static const String detailedReportProductId = 'supplecut_detailed_report';

  final _purchaseStatusController =
      StreamController<PurchaseStatus>.broadcast();
  Stream<PurchaseStatus> get purchaseStatusStream =>
      _purchaseStatusController.stream;

  bool get isAvailable => _isAvailable;

  Future<void> init() async {
    _isAvailable = await _iap.isAvailable();
    if (!_isAvailable) {
      debugPrint('IAP not available');
      return;
    }

    _subscription = _iap.purchaseStream.listen(
      _onPurchaseUpdate,
      onDone: () {
        _subscription?.cancel();
      },
      onError: (error) {
        debugPrint('IAP error: $error');
        _purchaseStatusController.add(PurchaseStatus.error);
      },
    );

    await _loadProducts();
  }

  Future<void> _loadProducts() async {
    final response = await _iap.queryProductDetails({detailedReportProductId});
    if (response.notFoundIDs.isNotEmpty) {
      debugPrint('Product not found: ${response.notFoundIDs}');
    }
    _products = response.productDetails;
  }

  Future<bool> buyDetailedReport() async {
    if (!_isAvailable || _products.isEmpty) {
      debugPrint('IAP not initialized or product empty');
      return false;
    }

    try {
      final ProductDetails productDetails = _products.firstWhere(
        (p) => p.id == detailedReportProductId,
        orElse: () => throw Exception('Product not found in list'),
      );
      final PurchaseParam purchaseParam =
          PurchaseParam(productDetails: productDetails);

      // 소모성 상품 구매
      return await _iap.buyConsumable(
          purchaseParam: purchaseParam, autoConsume: true);
    } catch (e) {
      debugPrint('Buy error: $e');
      return false;
    }
  }

  void _onPurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) async {
    for (var purchaseDetails in purchaseDetailsList) {
      _purchaseStatusController.add(purchaseDetails.status);

      if (purchaseDetails.status == PurchaseStatus.pending) {
        debugPrint('Purchase pending');
      } else {
        if (purchaseDetails.status == PurchaseStatus.error) {
          debugPrint('Purchase error: ${purchaseDetails.error}');
        } else if (purchaseDetails.status == PurchaseStatus.purchased ||
            purchaseDetails.status == PurchaseStatus.restored) {
          debugPrint('Purchase successful: ${purchaseDetails.productID}');
        }

        if (purchaseDetails.pendingCompletePurchase) {
          await _iap.completePurchase(purchaseDetails);
        }
      }
    }
  }

  void dispose() {
    _subscription?.cancel();
    _purchaseStatusController.close();
  }
}
