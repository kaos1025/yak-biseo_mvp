import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../models/supplement_analysis.dart';

class GeminiAnalyzerService {
  final List<String> _apiKeys = [];
  int _currentKeyIndex = 0;

  String get _currentApiKey => _apiKeys[_currentKeyIndex];

  void _rotateApiKey() {
    _currentKeyIndex = (_currentKeyIndex + 1) % _apiKeys.length;
  }

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
      "serving_size": "1회 섭취량 (예: 2 Tablets)",
      "efficacy": "제품 주요 효능 (예: 혈류 개선, 면역력 강화)",
      "ingredients": [
        {
          "name": "성분명 (영문)",
          "name_ko": "성분명 (한글)",
          "amount": 숫자,
          "unit": "단위",
          "daily_value_percent": % 또는 null,
          "efficacy": "성분 효능 (예: 에너지 대사 지원)"
        }
      ],
      "estimated_price": 숫자 (KRW, null이면 검색하여 채움),
      "supply_period_months": 숫자 (개월 수, 총 용량을 1회 섭취량으로 나눈 값, 기본 1),
      "monthly_price": 숫자 (KRW, estimated_price / supply_period_months)
    }
  ],
  "confidence": "high | medium | low",
  "notes": "특이사항 및 검색된 정보 출처"
}
""";

  GeminiAnalyzerService() {
    // Load multiple API keys (GEMINI_API_KEY_1, GEMINI_API_KEY_2, etc.)
    for (int i = 1; i <= 10; i++) {
      final key = dotenv.env['GEMINI_API_KEY_$i'];
      if (key != null && key.isNotEmpty) {
        _apiKeys.add(key);
      }
    }

    // Fallback: try GEMINI_API_KEY or API_KEY if no numbered keys found
    if (_apiKeys.isEmpty) {
      final fallbackKey =
          dotenv.env['GEMINI_API_KEY'] ?? dotenv.env['API_KEY'] ?? '';
      if (fallbackKey.isNotEmpty) {
        _apiKeys.add(fallbackKey);
      }
    }

    if (_apiKeys.isEmpty) {
      throw Exception(
          'API Key not found in .env (GEMINI_API_KEY_1, GEMINI_API_KEY, or API_KEY)');
    }

    // API keys loaded
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

  /// 컨설턴트 모드 (Markdown Report - JSON 데이터 기반)
  Future<String> analyzeImageWithConsultantMode(Uint8List imageBytes,
      {required AnalyzeResult previousAnalysis}) async {
    final jsonString = jsonEncode(previousAnalysis.toJson());

    String prompt = """
당신은 약사(Pharmacist)이자 헬스케어 재무 전문가입니다.
아래 제공된 영양제 분석 데이터(JSON)를 기반으로 **마크다운(Markdown)** 리포트를 작성하세요.

## 📋 분석할 영양제 데이터 (JSON)
다음 JSON 데이터는 이미지 분석과 가격 검색을 통해 추출된 정보입니다.
**이 데이터만을 기준으로** 리포트를 작성하세요. 추가 검색은 하지 마세요.

```json
$jsonString
```

## 🛑 중요: 일관된 판단 기준 (Decision Logic)
분석 시 반드시 다음 기준을 엄격하게 따르세요.

1.  **중복 판정 (Redundancy Check)**
    - 같은 성분(예: Vitamin D, Magnesium 등)이 2개 이상의 제품에 중복 포함된 경우, **반드시 지적**하세요.
    - 총 함량이 상한 섭취량(UL)을 초과하면 **"위험"**으로 경고하세요.
    - 단순히 겹치는 정도라면 **"과다/낭비"**로 분류하세요.

2.  **제외 권장 순위 (Priority)**
    제외할 영양제를 선택할 때 다음 우선순위를 따르세요:
    1순위: **부작용 위험** (상한 섭취량 초과)
    2순위: **단순 중복** (종합비타민과 단일제 중복 시, 가성비가 떨어지는 단일제를 제외 권장)
    3순위: **효능 입증 부족** (일반적인 건강한 성인에게 불필요한 성분)

##  이름 표기 규칙:
- **제외 권장** 제품을 언급할 때는, 반드시 위 **JSON 데이터의 'name' 필드 값**을 **그대로** 사용하세요.
- 임의로 한국어로 번역하거나 줄여 쓰지 마세요. (정확한 매칭을 위해 필수)

## 분석 내용
1.  **영양제 성분 분석 및 필요성 평가**
    - 각 제품의 주요 성분과 효능 요약
    - 일반적인 건강한 성인 남성 기준으로 섭취 필요성 등급 (필수/권장/선택/불필요) 매기기
    - **중복 점검**: 중복된 성분만 따로 모아서 명시

2.  **섭취 제외 권장 및 비용 절감액 (추정)**
    - 줄여도 되는 영양제 선정 및 이유 (위 판정 기준 근거)
    - 해당 제품 제외 시 월간/연간 절약 가능 금액 추정 (JSON의 monthly_price 필드 활용)

3.  **전문가 조언**
    - 섭취 타이밍, 주의사항, 시너지 효과 등

## 보고서 스타일
- 친절하고 전문적인 어조
- 가독성 좋은 마크다운 포맷 (볼드체, 리스트, 헤더 사용)
- 결론적으로 "어떻게 조합해 먹는 것이 가성비와 건강 모두 챙기는 길인지" 제안
""";

    try {
      return await _sendRestRequest(
        prompt: prompt,
        imageBytes: imageBytes,
        responseMimeType: 'text/plain',
      );
    } catch (e) {
      throw Exception('Consultant Analysis (REST) Failed: $e');
    }
  }

  /// 공통 REST API 요청 헬퍼 (Retry + Key Rotation + Grounding)
  Future<String> _sendRestRequest({
    required String prompt,
    required Uint8List imageBytes,
    required String responseMimeType,
  }) async {
    int keysTriedCount = 0;
    final totalKeys = _apiKeys.length;

    while (keysTriedCount < totalKeys) {
      final url = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$_currentApiKey');

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
              "temperature": 0.1,
              "maxOutputTokens": 8192,
              // "responseMimeType": responseMimeType
            }
          }),
        );

        if (response.statusCode == 200) {
          final json = jsonDecode(response.body);
          final candidates = json['candidates'] as List?;

          if (candidates == null || candidates.isEmpty) {
            throw Exception('AI 분석 응답이 비어있습니다.');
          }

          final content = candidates[0]['content'];
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
          keysTriedCount++;
          if (keysTriedCount < totalKeys) {
            _rotateApiKey();
            await Future.delayed(
                const Duration(seconds: 1)); // Brief delay before retry
            continue;
          } else {
            throw Exception('모든 API 키가 비율 제한에 걸렸습니다. 잠시 후 다시 시도해주세요. (429)');
          }
        }

        throw Exception(
            'Gemini REST API Failed: ${response.statusCode} - ${response.body}');
      } catch (e) {
        if (e.toString().contains('429') && keysTriedCount < totalKeys - 1) {
          keysTriedCount++;
          _rotateApiKey();
          continue;
        }
        rethrow;
      }
    }

    throw Exception('API 요청 실패: 모든 키 시도 완료');
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
