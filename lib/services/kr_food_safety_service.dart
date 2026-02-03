import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../models/ingredient.dart';
import 'kr_food_safety_parser.dart';

/// 식품안전나라 API 상세 조회 서비스
///
/// 건강기능식품 제품의 STDR_STND(기준규격) 필드를 조회하여
/// 활성 성분 정보를 파싱한다.
class KrFoodSafetyService {
  static const String _serviceId = 'C003';
  static const String _baseUrl = 'http://openapi.foodsafetykorea.go.kr/api';

  /// 제품명으로 건강기능식품 검색
  ///
  /// [productName] 검색할 제품명
  /// 반환: 검색된 제품 목록
  static Future<List<KrProductSearchResult>> searchProducts(
      String productName) async {
    if (productName.isEmpty) {
      return [];
    }

    final apiKey = dotenv.env['FOOD_SAFETY_KEY'] ?? '';
    if (apiKey.isEmpty) {
      return [];
    }

    try {
      final encodedQuery = Uri.encodeComponent(productName);
      final url =
          '$_baseUrl/$apiKey/$_serviceId/json/1/10/PRDLST_NM=$encodedQuery';

      final response = await http.get(Uri.parse(url)).timeout(
            const Duration(seconds: 10),
          );

      if (response.statusCode != 200) {
        return [];
      }

      final body = response.body;
      if (body.trim().startsWith('<')) {
        return []; // HTML 에러 응답
      }

      final data = jsonDecode(body);
      if (data[_serviceId] == null || data[_serviceId]['row'] == null) {
        return [];
      }

      final List<dynamic> rows = data[_serviceId]['row'];
      return rows
          .map((row) {
            return KrProductSearchResult(
              id: row['PRDLST_REPORT_NO'] ?? '',
              name: row['PRDLST_NM'] ?? '',
              brand: row['BSSH_NM'] ?? '',
              stdrStnd: row['STDR_STND'] ?? '', // 기준규격 (핵심!)
              rawMaterials: row['RAWMTRL_NM'] ?? '',
            );
          })
          .where((r) => r.id.isNotEmpty)
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// 품목보고번호로 제품 상세 조회
  ///
  /// [productId] PRDLST_REPORT_NO (품목보고번호)
  /// 반환: 제품 상세 정보 또는 null
  static Future<KrProductDetail?> getProductDetail(String productId) async {
    if (productId.isEmpty) {
      return null;
    }

    final apiKey = dotenv.env['FOOD_SAFETY_KEY'] ?? '';
    if (apiKey.isEmpty) {
      return null;
    }

    try {
      final encodedId = Uri.encodeComponent(productId);
      final url =
          '$_baseUrl/$apiKey/$_serviceId/json/1/1/PRDLST_REPORT_NO=$encodedId';

      final response = await http.get(Uri.parse(url)).timeout(
            const Duration(seconds: 10),
          );

      if (response.statusCode != 200) {
        return null;
      }

      final body = response.body;
      if (body.trim().startsWith('<')) {
        return null;
      }

      final data = jsonDecode(body);
      if (data[_serviceId] == null || data[_serviceId]['row'] == null) {
        return null;
      }

      final List<dynamic> rows = data[_serviceId]['row'];
      if (rows.isEmpty) {
        return null;
      }

      final row = rows.first;
      return KrProductDetail(
        id: row['PRDLST_REPORT_NO'] ?? '',
        name: row['PRDLST_NM'] ?? '',
        brand: row['BSSH_NM'] ?? '',
        stdrStnd: row['STDR_STND'] ?? '',
        rawMaterials: row['RAWMTRL_NM'] ?? '',
        dosage: row['NTK_MTHD'] ?? row['POG_DAYCNT'] ?? '',
        functionality: row['PRIMARY_FNCLTY'] ?? '',
      );
    } catch (e) {
      return null;
    }
  }

  /// 제품의 활성 성분 목록 조회 (STDR_STND 파싱)
  ///
  /// [productId] PRDLST_REPORT_NO
  /// 반환: 파싱된 Ingredient 리스트
  static Future<List<Ingredient>> getProductIngredients(
      String productId) async {
    final detail = await getProductDetail(productId);
    if (detail == null || detail.stdrStnd.isEmpty) {
      return [];
    }

    // STDR_STND 텍스트를 파싱하여 활성 성분 추출
    return KrFoodSafetyParser.parseStdrStnd(
      detail.stdrStnd,
      productId: productId,
    );
  }
}

/// 식약처 제품 검색 결과
class KrProductSearchResult {
  /// 품목보고번호
  final String id;

  /// 제품명
  final String name;

  /// 제조사/업체명
  final String brand;

  /// 기준규격 (STDR_STND) - 활성 성분 정보 포함
  final String stdrStnd;

  /// 원재료명 (RAWMTRL_NM) - 부형제 포함
  final String rawMaterials;

  const KrProductSearchResult({
    required this.id,
    required this.name,
    required this.brand,
    required this.stdrStnd,
    required this.rawMaterials,
  });

  /// STDR_STND에서 활성 성분 파싱
  List<Ingredient> parseIngredients() {
    if (stdrStnd.isEmpty) {
      return [];
    }
    return KrFoodSafetyParser.parseStdrStnd(stdrStnd, productId: id);
  }
}

/// 식약처 제품 상세 정보
class KrProductDetail {
  final String id;
  final String name;
  final String brand;
  final String stdrStnd;
  final String rawMaterials;
  final String dosage;
  final String functionality;

  const KrProductDetail({
    required this.id,
    required this.name,
    required this.brand,
    required this.stdrStnd,
    required this.rawMaterials,
    required this.dosage,
    required this.functionality,
  });

  /// STDR_STND에서 활성 성분 파싱
  List<Ingredient> parseIngredients() {
    if (stdrStnd.isEmpty) {
      return [];
    }
    return KrFoodSafetyParser.parseStdrStnd(stdrStnd, productId: id);
  }
}
