import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ReportPurchaseService {
  static const String _kReportSingleId = 'supplecut_report_single';
  static const String _kPurchasedReportsKey = 'purchased_report_ids';

  // Make _iap nullable or late, but safeguard access
  InAppPurchase? _iap;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  bool _isAvailable = false;

  // Callback to notify UI of status changes
  Function(String analysisId)? onPurchaseSuccess;
  Function(String error)? onPurchaseError;

  // Track the currently processing analysis ID
  String? _pendingAnalysisId;

  ReportPurchaseService() {
    _initialize();
  }

  void _initialize() {
    try {
      // 1. Web Check: IAP on web is not supported by default plugin in the same way
      if (kIsWeb) {
        if (kDebugMode) print("ReportPurchaseService: IAP disabled on Web");
        _isAvailable = false;
        return;
      }

      // 2. Instance Check: Accessing instance might throw on some platforms if not ready
      _iap = InAppPurchase.instance;
      _isAvailable = true;

      // 3. Listen to stream
      final purchaseUpdated = _iap!.purchaseStream;
      _subscription = purchaseUpdated.listen((purchaseDetailsList) {
        _listenToPurchaseUpdated(purchaseDetailsList);
      }, onDone: () {
        _subscription?.cancel();
      }, onError: (error) {
        if (kDebugMode) print("ReportPurchaseService Stream Error: $error");
      });
    } catch (e) {
      // Catch LateInitializationError or PlatformException
      if (kDebugMode) print("ReportPurchaseService Initialization Failed: $e");
      _isAvailable = false;
      _iap = null;
    }
  }

  void dispose() {
    _subscription?.cancel();
  }

  /// Check if a specific report analysis ID has been purchased locally
  Future<bool> isReportPurchased(String analysisId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final purchasedIds = prefs.getStringList(_kPurchasedReportsKey) ?? [];
      return purchasedIds.contains(analysisId);
    } catch (e) {
      if (kDebugMode) print("Error checking purchase status: $e");
      return false;
    }
  }

  /// Initiate purchase flow
  Future<void> buyReport(String analysisId) async {
    _pendingAnalysisId = analysisId;

    // Safety check
    if (!_isAvailable || _iap == null) {
      if (kDebugMode) {
        // Dev Mode: Simulate success for testing on Windows/Web
        print("IAP not available (Dev Mode). Simulating success...");
        await Future.delayed(const Duration(seconds: 1));
        await _savePurchaseLocally(analysisId);
        onPurchaseSuccess?.call(analysisId);
        return;
      }
      onPurchaseError?.call('이 기기에서는 결제 기능을 사용할 수 없습니다.');
      return;
    }

    try {
      final bool available = await _iap!.isAvailable();
      if (!available) {
        onPurchaseError?.call('스토어에 연결할 수 없습니다.');
        return;
      }

      // Query Products
      const Set<String> _kIds = {_kReportSingleId};
      final ProductDetailsResponse response =
          await _iap!.queryProductDetails(_kIds);

      if (response.notFoundIDs.isNotEmpty) {
        // Even if ID is not found, we might still have products if one was found
        if (kDebugMode) {
          print('Product not found: ${response.notFoundIDs}');
        }
      }

      final List<ProductDetails> products = response.productDetails;
      if (products.isEmpty) {
        // If no product configured in store, show error
        if (kDebugMode) {
          print("No products found. Using Mock Purchase for Dev.");
          await Future.delayed(const Duration(seconds: 1));
          await _savePurchaseLocally(analysisId);
          onPurchaseSuccess?.call(analysisId);
          return;
        }
        onPurchaseError?.call('판매 가능한 상품이 없습니다.');
        return;
      }

      final ProductDetails productDetails = products.first;
      final PurchaseParam purchaseParam =
          PurchaseParam(productDetails: productDetails);

      _iap!.buyConsumable(purchaseParam: purchaseParam, autoConsume: true);
    } catch (e) {
      onPurchaseError?.call('결제 시작 중 오류가 발생했습니다: $e');
    }
  }

  Future<void> _listenToPurchaseUpdated(
      List<PurchaseDetails> purchaseDetailsList) async {
    for (final PurchaseDetails purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        // Show pending UI if needed
      } else {
        if (purchaseDetails.status == PurchaseStatus.error) {
          onPurchaseError
              ?.call(purchaseDetails.error?.message ?? '결제 중 오류가 발생했습니다.');
        } else if (purchaseDetails.status == PurchaseStatus.purchased ||
            purchaseDetails.status == PurchaseStatus.restored) {
          if (_pendingAnalysisId != null) {
            await _savePurchaseLocally(_pendingAnalysisId!);
            onPurchaseSuccess?.call(_pendingAnalysisId!);
            _pendingAnalysisId = null;
          }
        }

        if (purchaseDetails.pendingCompletePurchase) {
          if (_iap != null) {
            await _iap!.completePurchase(purchaseDetails);
          }
        }
      }
    }
  }

  Future<void> _savePurchaseLocally(String analysisId) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> purchasedIds =
        prefs.getStringList(_kPurchasedReportsKey) ?? [];
    if (!purchasedIds.contains(analysisId)) {
      purchasedIds.add(analysisId);
      await prefs.setStringList(_kPurchasedReportsKey, purchasedIds);
    }
  }

  /// Debug/Dev: Clear purchase history
  Future<void> clearPurchases() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kPurchasedReportsKey);
  }
}
