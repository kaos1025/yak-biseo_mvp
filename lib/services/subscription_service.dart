import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String kBasicMonthly = 'basic_monthly';
const String kBasicYearly = 'basic_yearly';

enum SubscriptionTier { free, basic }

enum PurchaseResult { success, cancelled, error, alreadyOwned }

class SubscriptionService {
  static const String _cacheKey = 'v1_subscription_tier';
  static const Set<String> _subscriptionIds = {kBasicMonthly, kBasicYearly};

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;

  SubscriptionTier _currentTier = SubscriptionTier.free;
  List<ProductDetails> _products = [];
  bool _isAvailable = false;
  bool _initialized = false;

  final _tierController = StreamController<SubscriptionTier>.broadcast();
  Stream<SubscriptionTier> get tierStream => _tierController.stream;

  final _purchaseResultCompleter = <Completer<PurchaseResult>>[];

  // ── 초기화 ──

  Future<void> initialize() async {
    if (_initialized) return;

    try {
      if (kIsWeb) {
        debugPrint('SubscriptionService: IAP disabled on Web');
        await _loadCachedTier();
        _initialized = true;
        return;
      }

      _isAvailable = await _iap.isAvailable();
      if (!_isAvailable) {
        debugPrint('SubscriptionService: IAP not available');
        await _loadCachedTier();
        _initialized = true;
        return;
      }

      _purchaseSubscription = _iap.purchaseStream.listen(
        _onPurchaseUpdate,
        onDone: () => _purchaseSubscription?.cancel(),
        onError: (error) {
          debugPrint('SubscriptionService stream error: $error');
          _completePendingPurchase(PurchaseResult.error);
        },
      );

      await _loadProducts();
      await _refreshTierFromStore();
    } catch (e) {
      debugPrint('SubscriptionService init error: $e');
      await _loadCachedTier();
    }

    _initialized = true;
  }

  // ── Tier 조회 ──

  Future<SubscriptionTier> getCurrentTier() async {
    if (!_initialized) await initialize();
    return _currentTier;
  }

  Future<bool> isBasic() async {
    return await getCurrentTier() == SubscriptionTier.basic;
  }

  // ── 기능 게이트 헬퍼 ──

  Future<bool> canUseMyStack() async => isBasic();

  Future<bool> canUseQuickCheck() async => isBasic();

  Future<bool> hasUnlimitedReports() async => isBasic();

  // ── 상품 정보 ──

  /// 월간 구독 상품의 Play Store 가격 문자열
  String? get monthlyPrice {
    try {
      return _products.firstWhere((p) => p.id == kBasicMonthly).price;
    } catch (_) {
      return null;
    }
  }

  /// 연간 구독 상품의 Play Store 가격 문자열
  String? get yearlyPrice {
    try {
      return _products.firstWhere((p) => p.id == kBasicYearly).price;
    } catch (_) {
      return null;
    }
  }

  // ── 구매 ──

  Future<PurchaseResult> purchaseBasicMonthly() async {
    return _purchase(kBasicMonthly);
  }

  Future<PurchaseResult> purchaseBasicYearly() async {
    return _purchase(kBasicYearly);
  }

  Future<PurchaseResult> _purchase(String productId) async {
    if (!_isAvailable) {
      debugPrint('SubscriptionService: IAP not available for purchase');
      return PurchaseResult.error;
    }

    final ProductDetails product;
    try {
      product = _products.firstWhere((p) => p.id == productId);
    } catch (_) {
      debugPrint('SubscriptionService: product $productId not found');
      return PurchaseResult.error;
    }

    final completer = Completer<PurchaseResult>();
    _purchaseResultCompleter.add(completer);

    try {
      final param = PurchaseParam(productDetails: product);
      await _iap.buyNonConsumable(purchaseParam: param);
    } catch (e) {
      debugPrint('SubscriptionService purchase error: $e');
      _completePendingPurchase(PurchaseResult.error);
    }

    return completer.future;
  }

  // ── 복원 ──

  Future<void> restorePurchases() async {
    if (!_isAvailable) return;
    await _iap.restorePurchases();
  }

  // ── 내부: 구매 스트림 처리 ──

  void _onPurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) async {
    for (final details in purchaseDetailsList) {
      // 구독 상품이 아니면 무시 (기존 IAP 서비스가 처리)
      if (!_subscriptionIds.contains(details.productID)) continue;

      switch (details.status) {
        case PurchaseStatus.pending:
          break;
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          await _setTier(SubscriptionTier.basic);
          _completePendingPurchase(PurchaseResult.success);
          break;
        case PurchaseStatus.error:
          final message = details.error?.message ?? '';
          if (message.contains('already owned') ||
              message.contains('AlreadyOwned')) {
            await _setTier(SubscriptionTier.basic);
            _completePendingPurchase(PurchaseResult.alreadyOwned);
          } else {
            _completePendingPurchase(PurchaseResult.error);
          }
          break;
        case PurchaseStatus.canceled:
          _completePendingPurchase(PurchaseResult.cancelled);
          break;
      }

      if (details.pendingCompletePurchase) {
        await _iap.completePurchase(details);
      }
    }
  }

  void _completePendingPurchase(PurchaseResult result) {
    if (_purchaseResultCompleter.isNotEmpty) {
      final completer = _purchaseResultCompleter.removeAt(0);
      if (!completer.isCompleted) {
        completer.complete(result);
      }
    }
  }

  // ── 내부: 상품 로드 ──

  Future<void> _loadProducts() async {
    try {
      final response = await _iap.queryProductDetails(_subscriptionIds);
      if (response.notFoundIDs.isNotEmpty) {
        debugPrint(
            'SubscriptionService: products not found: ${response.notFoundIDs}');
      }
      _products = response.productDetails;
    } catch (e) {
      debugPrint('SubscriptionService loadProducts error: $e');
    }
  }

  // ── 내부: Tier 관리 ──

  Future<void> _refreshTierFromStore() async {
    // 캐시에서 먼저 로드
    await _loadCachedTier();

    // Play Store에서 활성 구매 확인은 purchaseStream 복원으로 처리
    // restorePurchases 호출 시 _onPurchaseUpdate에서 갱신됨
  }

  Future<void> _loadCachedTier() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_cacheKey);
      if (raw == 'basic') {
        _currentTier = SubscriptionTier.basic;
      } else {
        _currentTier = SubscriptionTier.free;
      }
    } catch (_) {
      _currentTier = SubscriptionTier.free;
    }
  }

  Future<void> _setTier(SubscriptionTier tier) async {
    _currentTier = tier;
    _tierController.add(tier);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          _cacheKey, tier == SubscriptionTier.basic ? 'basic' : 'free');
    } catch (_) {}
  }

  // ── 정리 ──

  void dispose() {
    _purchaseSubscription?.cancel();
    _tierController.close();
  }
}
