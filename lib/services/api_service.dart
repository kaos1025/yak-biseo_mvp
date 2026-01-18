import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../core/utils/keyword_cleaner.dart';
import '../models/pill.dart';

class ApiService {
  static const String _serviceId = 'I0030'; // 품목제조신고(원재료)
  static const String _baseUrl = 'http://openapi.foodsafetykorea.go.kr/api';

  /// Searches for pills using the Food Safety Korea API.
  ///
  /// [rawQuery] is the user's input search term.
  /// Returns a list of [KoreanPill].
  static Future<List<KoreanPill>> searchPill(String rawQuery) async {
    // 1. Pre-process the query
    final cleaningResult = KeywordCleaner.clean(rawQuery);
    if (cleaningResult.isEmpty) {
      return [];
    }

    // Encode for URL
    final encodedQuery = Uri.encodeComponent(cleaningResult);

    // Get API Key
    final apiKey = dotenv.env['FOOD_SAFETY_KEY'] ?? '';
    if (apiKey.isEmpty) {
      // In production, might want to log this or throw exception.
      // For MVP, return empty list.
      // print('Error: FOOD_SAFETY_KEY not found in .env');
      return [];
    }

    // 2. Build URL
    // Format: http://openapi.foodsafetykorea.go.kr/api/{KEY}/{SERVICE_ID}/json/1/5/PRDLST_NM={KEYWORD}
    final url =
        '$_baseUrl/$apiKey/$_serviceId/json/1/5/PRDLST_NM=$encodedQuery';

    try {
      final response =
          await http.get(Uri.parse(url)).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // 3. Parse Response
        if (data[_serviceId] != null && data[_serviceId]['row'] != null) {
          final List<dynamic> rows = data[_serviceId]['row'];

          return rows.map((row) {
            return KoreanPill(
              id: row['PRDLST_REPORT_NO'] ?? '', // 품목보고번호
              name: row['PRDLST_NM'] ?? '정보 없음', // 제품명
              brand: row['BSSH_NM'] ?? '정보 없음', // 제조사
              imageUrl: '', // API doesnt provide image
              dailyDosage: row['POG_DAYCNT'] ??
                  row['NTK_MTHD'] ??
                  '서빙 사이즈 정보 없음', // 유통기한 or 섭취방법 mapping
              category: '건강기능식품', // Default category
              ingredients: row['RAWMTRL_NM'] ?? '원재료 정보 없음', // 원재료
            );
          }).toList();
        }
      } else {
        // print('API Error: ${response.statusCode}');
      }
    } catch (e) {
      // print('Exception during API call: $e');
    }

    return [];
  }
}
