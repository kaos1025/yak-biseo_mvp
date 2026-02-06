import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../models/supplement_analysis.dart';

class GeminiAnalyzerService {
  late final String _apiKey;

  static const _systemPrompt = """
당신은 영양제/건강기능식품 라벨 분석 전문가입니다.

## 작업
첨부된 이미지에서 영양제 제품 정보와 성분을 추출하세요.

## 규칙
1. 라벨에 명시적으로 표기된 정보만 추출하세요.
2. **중요: 라벨에서 성분 함량을 찾을 수 없는 경우, Google Search를 사용하여 해당 제품의 일반적인 정보를 찾아 채우세요.** (더 이상 0으로 남기지 마세요)
3. 읽을 수 없는 정보는 null로 표기하세요.
4. 함량 단위는 라벨 그대로 유지하세요.

## 출력 형식 (JSON)
{
  "products": [
    {
      "brand": "브랜드명",
      "name": "제품명",
      "name_ko": "한글 제품명 (있는 경우)",
      "serving_size": "1회 섭취량",
      "ingredients": [
        {
          "name": "성분명 (영문)",
          "name_ko": "성분명 (한글)",
          "amount": 숫자,
          "unit": "단위",
          "daily_value_percent": % 또는 null
        }
      ]
    }
  ],
  "confidence": "high | medium | low",
  "notes": "특이사항 및 검색된 정보 출처"
}
""";

  GeminiAnalyzerService() {
    _apiKey = dotenv.env['GEMINI_API_KEY'] ?? dotenv.env['API_KEY'] ?? '';
    if (_apiKey.isEmpty) {
      throw Exception('API Key not found in .env');
    }
  }

  /// 표준 분석 (JSON) - REST API + Grounding 적용
  Future<AnalyzeResult> analyzeImage(Uint8List imageBytes) async {
    try {
      // Tool(Google Search) 사용 시 application/json 모드 지원되지 않음 -> text/plain으로 요청 후 파싱
      final jsonText = await _sendRestRequest(
        prompt: _systemPrompt,
        imageBytes: imageBytes,
        responseMimeType: 'text/plain',
      );

      final cleanJson = _cleanJsonString(jsonText);
      final json = jsonDecode(cleanJson);
      return AnalyzeResult.fromJson(json);
    } catch (e) {
      throw Exception('Standard Analysis (REST) Failed: $e');
    }
  }

  /// 컨설턴트 모드 (Markdown Report + Google Search)
  Future<String> analyzeImageWithConsultantMode(Uint8List imageBytes) async {
    const consultantPrompt = """
당신은 약사(Pharmacist)이자 헬스케어 재무 전문가입니다.
사용자의 영양제 사진을 보고 다음을 분석하여 **마크다운(Markdown)** 리포트를 작성하세요.
Google Search 도구를 사용하여 최신 가격 정보와 효능을 확인하세요.

## 분석 내용
1.  **영양제 성분 분석 및 필요성 평가**
    - 각 제품의 주요 성분과 효능 요약
    - 일반적인 건강한 성인 남성 기준으로 섭취 필요성 등급 (필수/권장/선택/불필요) 매기기
    - 중복되거나 과도한 성분이 있다면 지적

2.  **섭취 제외 권장 및 비용 절감액 (추정)**
    - 줄여도 되는 영양제 선정 및 이유
    - 해당 제품 제외 시 월간/연간 절약 가능 금액 추정 (현재 온라인 최저가 기준 검색)

3.  **전문가 조언**
    - 섭취 타이밍, 주의사항, 시너지 효과 등

## 보고서 스타일
- 친절하고 전문적인 어조
- 가독성 좋은 마크다운 포맷 (볼드체, 리스트, 헤더 사용)
- 결론적으로 "어떻게 조합해 먹는 것이 가성비와 건강 모두 챙기는 길인지" 제안
""";

    try {
      return await _sendRestRequest(
        prompt: consultantPrompt,
        imageBytes: imageBytes,
        responseMimeType: 'text/plain',
      );
    } catch (e) {
      throw Exception('Consultant Analysis (REST) Failed: $e');
    }
  }

  /// 공통 REST API 요청 헬퍼 (Retry + Grounding)
  Future<String> _sendRestRequest({
    required String prompt,
    required Uint8List imageBytes,
    required String responseMimeType,
  }) async {
    final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$_apiKey');

    int retryCount = 0;
    const maxRetries = 3;

    while (true) {
      try {
        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            "contents": [
              {
                "parts": [
                  {"text": prompt},
                  {
                    "inline_data": {
                      "mime_type": "image/jpeg",
                      "data": base64Encode(imageBytes)
                    }
                  }
                ]
              }
            ],
            "tools": [
              {
                "google_search": {} // Google Search Grounding Enable
              }
            ],
            "generationConfig": {
              "temperature": 0.0,
              "response_mime_type": responseMimeType
            }
          }),
        );

        if (response.statusCode == 200) {
          final json = jsonDecode(response.body);

          if (json['candidates'] == null ||
              (json['candidates'] as List).isEmpty) {
            if (json['promptFeedback'] != null) {
              throw Exception(
                  'Blocked by safety settings: ${json['promptFeedback']}');
            }
            throw Exception('No candidates returned');
          }

          final candidate = json['candidates'][0];
          final content = candidate['content'];
          if (content == null || content['parts'] == null) {
            throw Exception('분석 결과를 생성할 수 없습니다.');
          }

          final parts = content['parts'] as List;
          final textPart = parts.firstWhere((p) => p.containsKey('text'),
              orElse: () => null);

          if (textPart != null) {
            return textPart['text'];
          } else {
            throw Exception('텍스트 응답이 없습니다.');
          }
        }

        if (response.statusCode == 429) {
          if (retryCount >= maxRetries) {
            throw Exception('현재 이용량이 많아 분석이 지연되고 있습니다. 잠시 후 다시 시도해주세요. (429)');
          }
          retryCount++;
          final waitSeconds = 4 * (1 << (retryCount - 1));
          await Future.delayed(Duration(seconds: waitSeconds));
          continue;
        }

        throw Exception(
            'Gemini REST API Failed: ${response.statusCode} - ${response.body}');
      } catch (e) {
        if (e.toString().contains('429')) rethrow;
        rethrow;
      }
    }
  }

  /// JSON 문자열 정리 (Markdown 코드 블록 제거)
  String _cleanJsonString(String text) {
    String clean = text.trim();
    if (clean.startsWith('```json')) {
      clean = clean.replaceAll('```json', '').replaceAll('```', '');
    } else if (clean.startsWith('```')) {
      clean = clean.replaceAll('```', '');
    }
    return clean.trim();
  }

  /// 일관성 테스트 (Consistency Test)
  /// [iterations] 횟수만큼 반복 요청하여 결과의 일관성을 검증합니다.
  Future<Map<String, dynamic>> consistencyTest(Uint8List imageBytes,
      {int iterations = 5}) async {
    final results = <AnalyzeResult>[];
    final errors = <String>[];
    int successCount = 0;

    final startTime = DateTime.now();

    for (var i = 0; i < iterations; i++) {
      try {
        final result = await analyzeImage(imageBytes);
        results.add(result);
        successCount++;
      } catch (e) {
        errors.add('Iteration ${i + 1} failed: $e');
      }
    }

    final duration = DateTime.now().difference(startTime);

    // 간단한 일관성 점수 계산 (성분 개수가 동일하면 +점수)
    double consistencyScore = 0.0;
    if (successCount > 1) {
      int consistentCount = 0;
      final baselineCount =
          results[0].products.firstOrNull?.ingredients.length ?? 0;

      for (var i = 1; i < results.length; i++) {
        final count = results[i].products.firstOrNull?.ingredients.length ?? 0;
        if (count == baselineCount) {
          consistentCount++;
        }
      }
      consistencyScore = (consistentCount + 1) / results.length * 100;
    } else if (successCount == 1) {
      consistencyScore = 100.0; // 비교 대상이 없으므로 일단 100
    }

    return {
      'total_attempts': iterations,
      'success_count': successCount,
      'consistency_score': consistencyScore,
      'average_duration_ms': duration.inMilliseconds / iterations,
      'errors': errors,
      'results': results,
    };
  }
}
