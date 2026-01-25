import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../core/utils/keyword_cleaner.dart';
import '../models/pill.dart';

class ApiService {
  static const String _serviceId = 'C003'; // 건강기능식품 정보 (User Requested)
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
        final body = response.body;
        // Check for HTML error response (common with FoodSafetyKorea API for invalid key/auth)
        if (body.trim().startsWith('<')) {
          // API Key or Auth error
          return [];
        }

        final data = jsonDecode(body);

        // 3. Parse Response
        if (data[_serviceId] != null && data[_serviceId]['row'] != null) {
          final List<dynamic> rows = data[_serviceId]['row'];

          return rows.map((row) {
            return KoreanPill(
              id: row['PRDLST_REPORT_NO'] ?? '', // 품목보고번호
              name: row['PRDLST_NM'] ?? '정보 없음', // 제품명
              brand: row['BSSH_NM'] ?? '정보 없음', // 제조사
              imageUrl: '', // API doesnt provide image
              dailyDosage: row['NTK_MTHD'] ?? // 섭취방법 (C003 Priority)
                  row['POG_DAYCNT'] ?? // 유통기한
                  '서빙 사이즈 정보 없음', // 유통기한 or 섭취방법 mapping
              category: '건강기능식품', // Default category
              ingredients: row['RAWMTRL_NM'] ?? '원재료 정보 없음', // 원재료
            );
          }).toList();
        }
      } else {
        // API Error
      }
    } catch (e) {
      // Log error properly in production
    }

    return [];
  }

  static Future<String> analyzeDrugImage(XFile image) async {
    final apiKey = dotenv.env['API_KEY'] ?? '';
    if (apiKey.isEmpty) {
      return '''
      {
        "detected_items": [],
        "summary": "API Key가 설정되지 않았습니다. .env 파일을 확인해주세요.",
        "total_saving_amount": 0
      }
      ''';
    }

    try {
      final model = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: apiKey,
        generationConfig:
            GenerationConfig(responseMimeType: 'application/json'),
      );

      const prompt = '''
Analyze these health supplements in the image.
1. Identify each product's name (in Korean if possible) and key ingredients.
2. **CRITICAL STEP**: Check for **DUPLICATE** or **OVERLAPPING** ingredients between the detected items.
   - Example: If two products both contain 'Vitamin C' or 'Omega-3', mark the cheaper or less comprehensive one as "REDUNDANT".
   - Example: If a 'Multivitamin' and a separate 'Vitamin D' are present, check if the Multivitamin already has enough Vitamin D. If so, mark the separate Vitamin D as "REDUNDANT".
3. Estimate the price (in KRW) for each item.
4. If "REDUNDANT" items are found, sum their prices into `total_saving_amount`.

Provide the result in the following JSON format ONLY:
{
  "detected_items": [
    {
      "id": "Unique ID",
      "name": "Product Name (e.g., 고려은단 비타민C 1000)",
      "status": "SAFE" or "REDUNDANT" or "WARNING",
      "desc": "Short description of efficacy. If REDUNDANT, explain why (e.g., '종합비타민과 성분 중복').",
      "price": 0
    }
  ],
  "summary": "Summarize the analysis. Mention if the combination is safe or if there are duplicates.",
  "total_saving_amount": 0
}
''';

      final imageBytes = await image.readAsBytes();
      final content = [
        Content.multi([
          TextPart(prompt),
          DataPart('image/jpeg', imageBytes),
        ])
      ];

      final response = await model.generateContent(content);
      return response.text ?? '{}';
    } catch (e) {
      return '''
      {
        "detected_items": [],
        "summary": "분석 중 오류가 발생했습니다: $e",
        "total_saving_amount": 0
      }
      ''';
    }
  }
}
