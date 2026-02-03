import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/ingredient.dart';

/// NIH DSLD API 클라이언트
///
/// 외국 영양제의 성분 데이터를 NIH Dietary Supplement Label Database에서 조회한다.
/// API Key 불필요, 무료 사용 가능.
/// Rate Limit: 1,000 requests/hour/IP
///
/// 데이터 특성:
/// - ingredientRows[]: 활성 성분이 구조화되어 있음 → 직접 파싱 가능
/// - ingredientGroup 필드가 규칙 엔진의 카테고리 비교 키로 직접 사용됨
/// - otheringredients: 부형제이므로 중복 비교에서 반드시 제외
class NihDsldService {
  static const String _baseUrl = 'https://api.ods.od.nih.gov/dsld/v9';

  /// 제품명으로 DSLD 검색
  ///
  /// [productName] OCR 결과에서 추출한 제품명/브랜드
  /// 반환: 검색된 제품 목록 (id, fullName, brandName)
  ///
  /// 검색 결과에서 id(dsld_id)를 추출하여 [getProductIngredients]에 전달
  static Future<List<DsldSearchResult>> searchProducts(
      String productName) async {
    if (productName.isEmpty) {
      return [];
    }

    try {
      final encodedQuery = Uri.encodeComponent(productName);
      final url = '$_baseUrl/browse-products?query=$encodedQuery&pagesize=10';

      final response = await http.get(
        Uri.parse(url),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        return [];
      }

      final data = jsonDecode(response.body);
      final hits = data['hits'] as List<dynamic>? ?? [];

      return hits
          .map((hit) {
            final source = hit['_source'] as Map<String, dynamic>? ?? {};
            return DsldSearchResult(
              id: (hit['_id'] ?? source['id'])?.toString() ?? '',
              fullName: source['fullName'] as String? ?? '',
              brandName: source['brandName'] as String? ?? '',
            );
          })
          .where((r) => r.id.isNotEmpty)
          .toList();
    } catch (e) {
      // API 실패 시 빈 리스트 반환 (graceful degradation)
      return [];
    }
  }

  /// 특정 제품의 성분 목록 조회
  ///
  /// [dsldId] DSLD 제품 ID (searchProducts 결과에서 획득)
  /// 반환: Ingredient 리스트 (otheringredients 제외)
  ///
  /// 응답의 ingredientRows[]만 파싱한다 (otheringredients 제외).
  static Future<List<Ingredient>> getProductIngredients(String dsldId) async {
    if (dsldId.isEmpty) {
      return [];
    }

    try {
      final url = '$_baseUrl/label/$dsldId';

      final response = await http.get(
        Uri.parse(url),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        return [];
      }

      final data = jsonDecode(response.body);

      // ingredientRows 배열 추출 (otheringredients 제외)
      final ingredientRows = data['ingredientRows'] as List<dynamic>? ?? [];

      return ingredientRows.map((row) {
        return Ingredient.fromNihDsld(
          row as Map<String, dynamic>,
          productId: dsldId,
        );
      }).toList();
    } catch (e) {
      // API 실패 시 빈 리스트 반환 (graceful degradation)
      return [];
    }
  }

  /// 제품 기본 정보 조회 (이름, 브랜드 등)
  ///
  /// [dsldId] DSLD 제품 ID
  /// 반환: 제품 기본 정보 또는 null
  static Future<DsldProductInfo?> getProductInfo(String dsldId) async {
    if (dsldId.isEmpty) {
      return null;
    }

    try {
      final url = '$_baseUrl/label/$dsldId';

      final response = await http.get(
        Uri.parse(url),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        return null;
      }

      final data = jsonDecode(response.body);

      return DsldProductInfo(
        id: dsldId,
        fullName: data['fullName'] as String? ?? '',
        brandName: data['brandName'] as String? ?? '',
        upcSku: data['upcSku'] as String?,
      );
    } catch (e) {
      return null;
    }
  }
}

/// DSLD 검색 결과
class DsldSearchResult {
  final String id;
  final String fullName;
  final String brandName;

  const DsldSearchResult({
    required this.id,
    required this.fullName,
    required this.brandName,
  });
}

/// DSLD 제품 기본 정보
class DsldProductInfo {
  final String id;
  final String fullName;
  final String brandName;
  final String? upcSku;

  const DsldProductInfo({
    required this.id,
    required this.fullName,
    required this.brandName,
    this.upcSku,
  });
}
