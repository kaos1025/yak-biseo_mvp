import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String kBasicMonthly = 'basic_monthly';
const String kBasicYearly = 'basic_yearly';
const String kFamilyMonthly = 'family_monthly';
const String kFamilyYearly = 'family_yearly';
const String kDetailedReport199 = 'detailed_report_199';

enum SubscriptionTier { free, basic, family }

enum PurchaseResult { success, cancelled, error, alreadyOwned }

class SubscriptionService {
  static const String _cacheKey = 'v1_subscription_tier';
  static const String _trialExpiryKey = 'v1_trial_expiry';
  static const String _trialGrantedKey = 'v1_trial_granted';
  static const Set<String> _subscriptionIds = {
    kBasicMonthly,
    kBasicYearly,
    kFamilyMonthly,
    kFamilyYearly,
  };

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

    // Trial 만료 체크
    if (_currentTier == SubscriptionTier.basic) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final expiryStr = prefs.getString(_trialExpiryKey);
        if (expiryStr != null) {
          final expiry = DateTime.tryParse(expiryStr);
          if (expiry != null && DateTime.now().isAfter(expiry)) {
            // Trial 만료 → free로 전환
            final cachedRaw = prefs.getString(_cacheKey);
            if (cachedRaw == 'basic_trial') {
              _currentTier = SubscriptionTier.free;
              await prefs.remove(_cacheKey);
              await prefs.remove(_trialExpiryKey);
              _tierController.add(_currentTier);
            }
          }
        }
      } catch (_) {}
    }

    return _currentTier;
  }

  Future<bool> isPaid() async {
    final tier = await getCurrentTier();
    return tier == SubscriptionTier.basic || tier == SubscriptionTier.family;
  }

  /// Trial(basic_trial) 기간이 현재 활성 중인지 여부.
  /// 정식 구독자는 false를 반환 — 체험 ↔ 정식 구독을 구분하기 위한 헬퍼.
  Future<bool> isTrialActive() async {
    if (!_initialized) await initialize();
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getString(_cacheKey) != 'basic_trial') return false;
      final expiryStr = prefs.getString(_trialExpiryKey);
      if (expiryStr == null) return false;
      final expiry = DateTime.tryParse(expiryStr);
      if (expiry == null) return false;
      return DateTime.now().isBefore(expiry);
    } catch (_) {
      return false;
    }
  }

  // ── 기능 게이트 헬퍼 ──

  Future<bool> canUseMyStack() async => isPaid();

  Future<bool> canUseQuickCheck() async => isPaid();

  Future<bool> hasUnlimitedReports() async => isPaid();

  // ── $1.99 첫 구매 → 30일 Basic 체험 자동 부여 ──

  Future<void> grantTrialFromReport() async {
    final prefs = await SharedPreferences.getInstance();
    final trialGranted = prefs.getBool(_trialGrantedKey) ?? false;
    if (!trialGranted) {
      final trialExpiry = DateTime.now().add(const Duration(days: 30));
      await prefs.setString(_trialExpiryKey, trialExpiry.toIso8601String());
      await prefs.setBool(_trialGrantedKey, true);
      await prefs.setString(_cacheKey, 'basic_trial');
      _currentTier = SubscriptionTier.basic;
      _tierController.add(_currentTier);
    }
  }

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

  /// Family 월간 구독 상품의 Play Store 가격 문자열
  String? get familyMonthlyPrice {
    try {
      return _products.firstWhere((p) => p.id == kFamilyMonthly).price;
    } catch (_) {
      return null;
    }
  }

  /// Family 연간 구독 상품의 Play Store 가격 문자열
  String? get familyYearlyPrice {
    try {
      return _products.firstWhere((p) => p.id == kFamilyYearly).price;
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

  Future<PurchaseResult> purchaseFamilyMonthly() async {
    return _purchase(kFamilyMonthly);
  }

  Future<PurchaseResult> purchaseFamilyYearly() async {
    return _purchase(kFamilyYearly);
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

      final tierForProduct =
          (details.productID == kFamilyMonthly ||
                  details.productID == kFamilyYearly)
              ? SubscriptionTier.family
              : SubscriptionTier.basic;

      switch (details.status) {
        case PurchaseStatus.pending:
          break;
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          await _setTier(tierForProduct);
          _completePendingPurchase(PurchaseResult.success);
          break;
        case PurchaseStatus.error:
          final message = details.error?.message ?? '';
          if (message.contains('already owned') ||
              message.contains('AlreadyOwned')) {
            await _setTier(tierForProduct);
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
      switch (raw) {
        case 'family':
          _currentTier = SubscriptionTier.family;
          break;
        case 'basic':
        case 'basic_trial':
          _currentTier = SubscriptionTier.basic;
          break;
        default:
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
      String value;
      switch (tier) {
        case SubscriptionTier.family:
          value = 'family';
          break;
        case SubscriptionTier.basic:
          value = 'basic';
          break;
        case SubscriptionTier.free:
          value = 'free';
          break;
      }
      await prefs.setString(_cacheKey, value);
    } catch (_) {}
  }

  // ── 정리 ──

  void dispose() {
    _purchaseSubscription?.cancel();
    _tierController.close();
  }
}
