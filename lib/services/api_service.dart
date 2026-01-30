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
      return [];
    }

    // 2. Build URLs (Parallel Search: Product Name & Manufacturer)
    final urlProduct =
        '$_baseUrl/$apiKey/$_serviceId/json/1/20/PRDLST_NM=$encodedQuery';
    final urlBrand =
        '$_baseUrl/$apiKey/$_serviceId/json/1/20/BSSH_NM=$encodedQuery';

    try {
      // 3. Parallel API Calls
      final responses = await Future.wait([
        http.get(Uri.parse(urlProduct)).timeout(const Duration(seconds: 5)),
        http.get(Uri.parse(urlBrand)).timeout(const Duration(seconds: 5)),
      ]);

      final Map<String, KoreanPill> resultMap = {};

      for (var response in responses) {
        if (response.statusCode == 200) {
          final body = response.body;
          if (body.trim().startsWith('<')) continue;

          final data = jsonDecode(body);
          if (data[_serviceId] != null && data[_serviceId]['row'] != null) {
            final List<dynamic> rows = data[_serviceId]['row'];
            for (var row in rows) {
              final pill = KoreanPill(
                id: row['PRDLST_REPORT_NO'] ?? '',
                name: row['PRDLST_NM'] ?? '정보 없음',
                brand: row['BSSH_NM'] ?? '정보 없음',
                imageUrl: '',
                dailyDosage:
                    row['NTK_MTHD'] ?? row['POG_DAYCNT'] ?? '서빙 사이즈 정보 없음',
                category: '건강기능식품',
                ingredients: row['RAWMTRL_NM'] ?? '원재료 정보 없음',
              );
              resultMap[pill.id] = pill; // Deduplicate by ID
            }
          }
        }
      }

      // 4. Sort Results (Newest First)
      // 품목보고번호(PRDLST_REPORT_NO)는 연도+일련번호 형식이므로 내림차순 정렬 시 최신순이 됨
      final sortedList = resultMap.values.toList();
      sortedList.sort((a, b) => b.id.compareTo(a.id));

      return sortedList;
    } catch (e) {
      // Log error properly in production
    }

    return [];
  }

  static Future<String> analyzeDrugImage(XFile image, String locale) async {
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

      final isEnglish = locale == 'en';
      final languageInstruction = isEnglish
          ? "**IMPORTANT: Respond ONLY in English.** Output all fields (name, desc, summary, dosage) in English."
          : "**IMPORTANT: Respond ONLY in Korean (한국어).**";

      final currencyInstruction = isEnglish
          ? "Estimate the price in USD (integer, e.g. 25)."
          : "Estimate the price in KRW (integer, e.g. 30000).";

      final prompt = '''
Analyze these health supplements in the image.

$languageInstruction

1. Identify each product's name and key ingredients.
2. Identify the **Recommended Dosage & Usage** (e.g., "1 tablet daily").
3. **CRITICAL STEP**: Check for **DUPLICATE** or **OVERLAPPING** ingredients between the detected items.
   - Example: If two products both contain 'Vitamin C', mark the cheaper or less comprehensive one as "REDUNDANT".
4. $currencyInstruction
5. If "REDUNDANT" items are found, sum their prices into `total_saving_amount`.

Provide the result in the following JSON format ONLY:
{
  "detected_items": [
    {
      "id": "Unique ID",
      "name": "Product Name",
      "dosage": "Dosage Info",
      "status": "SAFE" or "REDUNDANT" or "WARNING",
      "desc": "Short description of efficacy. If REDUNDANT, explain why.",
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
        "summary": "Error during analysis: $e",
        "total_saving_amount": 0
      }
      ''';
    }
  }
}
