import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/supplecut_analysis_result.dart';

/// OCR 추출 제품명 목록 기반 분석 결과 캐시 서비스 (7일 TTL)
class AnalysisCacheService {
  static const Duration _ttl = Duration(days: 7);
  static const String _prefix = 'analysis_cache_v1_';

  /// 캐시 조회. 유효한 캐시가 없으면 null 반환.
  static Future<SuppleCutAnalysisResult?> get(List<String> productNames) async {
    final key = _prefix + _cacheKey(productNames);
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw == null) return null;

    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final cachedAt = DateTime.parse(map['cachedAt'] as String);
      if (DateTime.now().difference(cachedAt) > _ttl) {
        await prefs.remove(key); // 만료 항목 정리
        return null;
      }
      return SuppleCutAnalysisResult.fromJson(
          map['result'] as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  /// 분석 결과 캐시 저장.
  static Future<void> put(
      List<String> productNames, SuppleCutAnalysisResult result) async {
    final key = _prefix + _cacheKey(productNames);
    final prefs = await SharedPreferences.getInstance();
    final payload = jsonEncode({
      'cachedAt': DateTime.now().toIso8601String(),
      'result': result.toJson(),
    });
    await prefs.setString(key, payload);
  }

  /// 제품명 목록 → 정렬 후 join → hashCode 문자열 (결정적 해시)
  static String _cacheKey(List<String> names) {
    final sorted = List<String>.from(names)
      ..sort()
      ..map((s) => s.toLowerCase().trim());
    return sorted.join('|').hashCode.toString();
  }
}
