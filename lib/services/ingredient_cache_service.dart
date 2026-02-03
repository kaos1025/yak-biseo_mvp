import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/ingredient.dart';

/// 성분 데이터 로컬 캐싱 서비스 (TTL 지원)
///
/// API에서 조회한 성분 데이터를 로컬에 저장하여 반복 조회를 최소화한다.
/// 캐시 키: 제품 식별자 (NIH: dsld_id / KR: PRDLST_REPORT_NO)
///
/// TTL: 7일 후 캐시 만료
class IngredientCacheService {
  static const String _cacheKeyPrefix = 'ingredient_cache_';
  static const String _timestampKeyPrefix = 'ingredient_cache_ts_';

  /// 캐시 유효 기간 (7일)
  static const Duration cacheTtl = Duration(days: 7);

  static SharedPreferences? _prefs;

  /// SharedPreferences 초기화
  static Future<void> _ensureInitialized() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// 캐시에서 제품 성분 조회 (TTL 체크 포함)
  ///
  /// [productId] 제품 식별자 (NIH: dsld_id / KR: PRDLST_REPORT_NO)
  /// 반환: 캐시된 Ingredient 리스트 또는 null (캐시 미스/만료)
  static Future<List<Ingredient>?> getIngredients(String productId) async {
    await _ensureInitialized();

    final key = '$_cacheKeyPrefix$productId';
    final timestampKey = '$_timestampKeyPrefix$productId';

    // TTL 체크
    final cachedAtMs = _prefs?.getInt(timestampKey);
    if (cachedAtMs != null) {
      final cachedAt = DateTime.fromMillisecondsSinceEpoch(cachedAtMs);
      final age = DateTime.now().difference(cachedAt);
      if (age > cacheTtl) {
        // 캐시 만료 → 삭제 후 null 반환
        await invalidate(productId);
        return null;
      }
    }

    final jsonString = _prefs?.getString(key);

    if (jsonString == null || jsonString.isEmpty) {
      return null; // 캐시 미스
    }

    try {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList
          .map((json) => Ingredient.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      // 파싱 실패 시 캐시 삭제 후 null 반환
      await invalidate(productId);
      return null;
    }
  }

  /// API 응답을 캐시에 저장 (타임스탬프 포함)
  ///
  /// [productId] 제품 식별자
  /// [ingredients] 통합 Ingredient 모델로 변환된 데이터
  static Future<void> saveIngredients(
    String productId,
    List<Ingredient> ingredients,
  ) async {
    await _ensureInitialized();

    final key = '$_cacheKeyPrefix$productId';
    final timestampKey = '$_timestampKeyPrefix$productId';

    final jsonList = ingredients.map((i) => i.toJson()).toList();
    final jsonString = jsonEncode(jsonList);

    await _prefs?.setString(key, jsonString);
    await _prefs?.setInt(timestampKey, DateTime.now().millisecondsSinceEpoch);
  }

  /// 특정 제품 캐시 삭제
  ///
  /// [productId] 제품 식별자
  static Future<void> invalidate(String productId) async {
    await _ensureInitialized();

    final key = '$_cacheKeyPrefix$productId';
    final timestampKey = '$_timestampKeyPrefix$productId';

    await _prefs?.remove(key);
    await _prefs?.remove(timestampKey);
  }

  /// 모든 성분 캐시 삭제
  static Future<void> clearAll() async {
    await _ensureInitialized();

    final keys = _prefs?.getKeys() ?? {};
    for (final key in keys) {
      if (key.startsWith(_cacheKeyPrefix) ||
          key.startsWith(_timestampKeyPrefix)) {
        await _prefs?.remove(key);
      }
    }
  }

  /// 캐시된 제품 ID 목록 조회
  static Future<List<String>> getCachedProductIds() async {
    await _ensureInitialized();

    final keys = _prefs?.getKeys() ?? {};
    return keys
        .where((key) => key.startsWith(_cacheKeyPrefix))
        .map((key) => key.substring(_cacheKeyPrefix.length))
        .toList();
  }

  /// 캐시에 특정 제품이 있는지 확인 (만료 여부 무시)
  static Future<bool> hasCache(String productId) async {
    await _ensureInitialized();

    final key = '$_cacheKeyPrefix$productId';
    return _prefs?.containsKey(key) ?? false;
  }

  /// 캐시 만료까지 남은 시간 조회
  ///
  /// 반환: 남은 시간 또는 null (캐시 없음)
  static Future<Duration?> getRemainingTtl(String productId) async {
    await _ensureInitialized();

    final timestampKey = '$_timestampKeyPrefix$productId';
    final cachedAtMs = _prefs?.getInt(timestampKey);

    if (cachedAtMs == null) {
      return null;
    }

    final cachedAt = DateTime.fromMillisecondsSinceEpoch(cachedAtMs);
    final expiresAt = cachedAt.add(cacheTtl);
    final remaining = expiresAt.difference(DateTime.now());

    return remaining.isNegative ? Duration.zero : remaining;
  }
}
