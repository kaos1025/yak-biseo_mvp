import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../models/analysis_input.dart';
import '../models/supplement_analysis.dart';
import '../models/consultant_result.dart';
import '../models/supplement_product.dart';
import '../models/supplecut_analysis_result.dart';
import '../models/unified_analysis_result.dart';
import '../data/repositories/local_supplement_repository.dart';

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

  /// 컨설턴트 모드 (JSON 응답 + 마크다운 리포트 포함)
  Future<ConsultantResult> analyzeImageWithConsultantMode(Uint8List imageBytes,
      {required AnalyzeResult previousAnalysis}) async {
    final jsonString = jsonEncode(previousAnalysis.toJson());

    String prompt = """
당신은 약사(Pharmacist)이자 헬스케어 재무 전문가입니다.
아래 제공된 영양제 분석 데이터(JSON)를 기반으로 분석 결과를 **JSON 형식**으로 반환하세요.

## 📋 분석할 영양제 데이터
다음 JSON 데이터는 이미지 분석과 가격 검색을 통해 추출된 정보입니다.
**이 데이터만을 기준으로** 분석하세요. 추가 검색은 하지 마세요.

```json
$jsonString
```

## 🛑 판단 기준 (Decision Logic)
1.  **중복 판정**: 같은 성분이 2개 이상 제품에 포함되면 중복 지적
2.  **제외 우선순위**:
    - 1순위: 부작용 위험 (상한 섭취량 초과)
    - 2순위: 단순 중복 (종합비타민과 단일제 중복 시 단일제 제외)
    - 3순위: 효능 입증 부족

## ⚠️ 중요: name 필드 규칙
- excluded_products의 "name" 값은 **반드시 위 JSON 데이터의 products[].name 필드 값을 그대로 복사**하세요.
- 한글로 번역하거나 줄여 쓰지 마세요. 정확한 매칭을 위해 필수입니다.

## 출력 형식 (JSON)
다음 형식으로 정확히 반환하세요:
{
  "excluded_products": [
    {
      "name": "제품의 name 필드 값 (영문 그대로)",
      "reason": "제외 권장 이유 (한글, 1-2문장)",
      "original_price": 숫자 (제품의 판매 가격 추정치. 모르면 30000 등 평균가 입력. 절대 0이나 null 금지),
      "duration_months": 숫자 (섭취 기간 추정치. 모르면 1 입력),
      "monthly_savings": 숫자 (original_price / duration_months)
    }
  ],
  "total_monthly_savings": 숫자 (제외 제품들의 monthly_savings 합계),
  "exclusion_reason": "전체적인 제외 권장 이유 요약 (한글, 100자 이내)",
  "report_markdown": "상세 마크다운 리포트 (성분 분석, 중복 점검, 전문가 조언 포함)",
  "products_ui": [
    {
      "name": "제품의 name 필드 값 (영문 그대로)",
      "status": "danger | safe",
      "reason": "status가 danger일 경우, 제외 권장 이유 (한글, 1-2문장)"
    }
  ]
}

### products_ui[].status
- "danger": 명확한 중복이거나 심각한 상한 초과로 **제외를 강력히 권장**하는 경우.
- "safe": 섭취해도 무방한 경우.

## 🛑 최종 확인 (Final Check)
- 당신의 응답은 반드시 `{` 문자로 시작해야 합니다.
- `report_markdown` 내용은 JSON 내부의 "문자열(String)"이어야 합니다. 마크다운을 JSON 밖으로 꺼내지 마세요.
- 인사말이나 부연 설명을 절대 추가하지 마세요.

report_markdown 내용:
1. 영양제 성분 분석 및 필요성 평가 (필수/권장/선택/불필요)
2. 중복 성분 분석 및 제외 권장 이유
3. 월간/연간 절약 금액
4. 전문가 조언 (섭취 타이밍, 시너지 효과 등)

## 주의사항
- 제외할 제품이 없으면 excluded_products를 빈 배열 []로 반환
- JSON만 반환하세요. 다른 텍스트를 추가하지 마세요.
""";

    try {
      final responseText = await _sendRestRequest(
        prompt: prompt,
        imageBytes: imageBytes,
        responseMimeType: 'text/plain',
      );

      // Parse the JSON response
      final cleanedJson = _cleanJsonString(responseText);
      final Map<String, dynamic> jsonResult = jsonDecode(cleanedJson);
      return ConsultantResult.fromJson(jsonResult);
    } catch (e) {
      throw Exception('Consultant Analysis Failed: $e');
    }
  }

  /// 공통 REST API 요청 헬퍼 (Retry + Key Rotation + Grounding)
  Future<String> _sendRestRequest({
    required String prompt,
    Uint8List? imageBytes, // Changed to nullable
    required String responseMimeType,
    bool enableGrounding = false, // Grounding 옵션화 (디폴트: 강제 종료로 속도 최적화)
  }) async {
    int keysTriedCount = 0;
    final totalKeys = _apiKeys.length;

    while (keysTriedCount < totalKeys) {
      final url = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$_currentApiKey');

      try {
        final List<Map<String, dynamic>> parts = [
          {"text": prompt}
        ];

        if (imageBytes != null && imageBytes.isNotEmpty) {
          parts.add({
            "inline_data": {
              "mime_type": "image/jpeg",
              "data": base64Encode(imageBytes)
            }
          });
        }

        final Map<String, dynamic> requestBody = {
          "contents": [
            {"parts": parts}
          ],
          "generationConfig": {
            "temperature": 0.1,
            "maxOutputTokens": 8192,
            // "responseMimeType": responseMimeType
          }
        };

        if (enableGrounding) {
          requestBody["tools"] = [
            {
              "google_search": {} // Google Search Grounding Enable
            }
          ];
        }

        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(requestBody),
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

  /// JSON 문자열 정리 (Markdown 코드 블록 제거 및 순수 JSON 추출)
  /// + Trailing Comma 제거
  String _cleanJsonString(String text) {
    String clean = text
        .replaceAll(RegExp(r'```json', caseSensitive: false), '')
        .replaceAll(RegExp(r'```', caseSensitive: false), '');

    // 2. Find the first '{' or '[' and last '}' or ']'
    final objectStart = clean.indexOf('{');
    final arrayStart = clean.indexOf('[');
    final start = (objectStart != -1 && arrayStart != -1)
        ? (objectStart < arrayStart ? objectStart : arrayStart)
        : (objectStart != -1 ? objectStart : arrayStart);

    final objectEnd = clean.lastIndexOf('}');
    final arrayEnd = clean.lastIndexOf(']');
    final end = (objectEnd != -1 && arrayEnd != -1)
        ? (objectEnd > arrayEnd ? objectEnd : arrayEnd)
        : (objectEnd != -1 ? objectEnd : arrayEnd);

    // 3. Extract JSON block
    if (start != -1 && end != -1 && end > start) {
      clean = clean.substring(start, end + 1);
    } else {
      clean = clean.trim();
    }

    // 4. Remove trailing commas (e.g. "a": 1, } -> "a": 1 })
    final trailingCommaRegex = RegExp(r',\s*([\]}])');
    clean = clean.replaceAll(trailingCommaRegex, r'$1');

    return clean;
  }

  /// 일관성 테스트 (Consistency Test)
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
      consistencyScore = 100.0;
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

  static const String _unifiedPrompt = '''
당신은 건강기능식품 분석 AI 어시스턴트입니다.
첨부된 영양제 라벨 이미지를 분석하여 **오직 JSON 형식**으로만 출력하세요.

## 🎯 분석 목표
사용자가 복용 중인 영양제들의 성분을 분석하여 **중복 섭취**, **상한량 초과** 가능성을 알리고, 불필요한 제품을 제외했을 때의 **경제적 이득(절감액)**을 계산해줍니다.

## ⚠️ 필수 규칙 (Strict Rules)
1.  **순수 JSON 반환**: 
    -   출력 결과의 **첫 글자는 반드시 `{`** 여야 합니다.
    -   Markdown 코드 블록(```json)을 사용하지 마세요. 그냥 raw text로 JSON만 출력하세요.
    -   "안녕하세요", "분석 결과입니다" 등의 사족을 절대 달지 마세요.
    -   **중요**: 문자열 내의 큰따옴표(")는 반드시 역슬래시(\\)로 이스케이프 처리하세요.
    -   배열(List)의 마지막 항목 뒤에 쉼표(,)를 남기지 마세요 (No Trailing Commas).
2.  **화폐 단위**: 모든 가격 정보(`original_price`, `monthly_price`, `monthly_savings` 등)는 반드시 **대한민국 원화(KRW)** 기준입니다.
    -   **절대 주의**: "4원", "15원" 같은 비현실적인 소액은 허용하지 않습니다.
    -   가격 정보가 없으면 Google Search를 통해 한국 내 일반적인 판매가를 검색하여 추정하세요. (예: 1개월분 30,000원 등)
    -   최소 단위는 100원 단위로 반올림하세요. (예: 32450 -> 32500)
3.  **상한량 판단**: 
    -   특정 수치에 기계적으로 얽매이지 말고, **성인의 일반적인 일일 상한 섭취량(UL)**을 기준으로 유연하게 판단하세요.
    -   단순히 성분이 겹친다고 무조건 제외하지 말고, 총 함량이 건강에 위해를 줄 수 있는 수준인지 고려하세요.
4.  **성분 추출**:
    -   라벨에 "Ingredients" 또는 "Supplement Facts"가 보이면 최대한 상세히 추출하세요.
    -   라벨이 잘 안 보이면 Google Search를 통해 해당 제품명(`brand` + `name`)의 성분 정보를 보완하세요.
5.  **언어 및 표현 (중요)**:
    -   **금지 표현**: "전문 약사", "의사가", "약사가", "강력히 권장", "반드시", "꼭". (전문가 사칭 및 의료 조언성 표현 금지)
    -   **권장 표현**: "분석 결과에 따르면...", "~를 고려해보실 수 있습니다", "~가 도움이 될 수 있습니다".
    -   **면책**: "정확한 판단은 의사/약사와 상담하세요"라는 뉘앙스를 유지하세요.
    -   분석 리포트(`premium_report`)와 이유(`exclusion_reason`)는 한국어로 작성하세요.
    -   `premium_report` 내용은 JSON 문자열 값 내부여야 합니다.

## 출력 JSON 구조 (Strict)

```json
{
  "products": [
    {
      "brand": "브랜드명 (영어/한글)",
      "name": "제품명 (영어/한글)",
      "ingredients": [
        {"name": "성분명", "amount": 숫자, "unit": "mg/mcg/IU 등"}
      ],
      "estimated_monthly_price": 월환산가격(KRW_숫자),
      "original_price": 제품판매가격(KRW_숫자, 검색 또는 추정, 최소 1000원 이상),
      "duration_months": 섭취기간(숫자, 예: 2개월분이면 2),
      "dosage": "섭취방법 (예: 1일 1회 1정)"
    }
  ],
  "analysis": {
    "banner_type": "savings 또는 good",
    "has_duplicate": true/false,
    "has_over_limit": true/false,
    "excluded_product": "제외권장 제품명 또는 null",
    "monthly_savings": 월환산_월절감총액(KRW_숫자),
    "yearly_savings": 연간절감총액(KRW_숫자),
    "exclusion_reason": "핵심 제외 이유 1문장 요약 (중립적 표현 사용)",
    "duplicate_ingredients": ["중복성분명1", "중복성분명2"],
    "over_limit_ingredients": [
      {"name": "성분명", "total": 총함량, "limit": 상한기준, "unit": "단위"}
    ]
  },
  "products_ui": [
    {
      "name": "제품명",
      "brand": "브랜드명", 
      "status": "danger 또는 safe",
      "tag": "중복 또는 null",
      "monthly_price": 월환산가격(KRW_숫자)
    }
  ]
}
```

## 필드 가이드

### products_ui[].status
- "danger": 명확한 중복이거나 심각한 상한 초과로 **제외를 고려해보아야 하는** 경우.
- "safe": 섭취해도 무방한 경우.

## 🛑 최종 확인 (Final Check)
- 당신의 응답은 반드시 `{` 문자로 시작해야 합니다.
- 인사말이나 부연 설명을 절대 추가하지 마세요.
''';

  static const String _premiumReportPrompt = '''
당신은 대한민국 최고의 약사(Pharmacist)이자 헬스케어 전문가입니다.
사용자의 영양제 조합 분석 결과를 바탕으로, 돈을 지불한 프리미엄 사용자를 위한 **심층 분석 리포트**를 작성하세요.

## 📋 분석 데이터 (JSON)
{{JSON_DATA}}

## ✍️ 리포트 작성 가이드
다음 4가지 섹션으로 구성된 마크다운(Markdown) 리포트를 작성하세요.

1.  **💊 성분 종합 평가 (Overall Evaluation)**
    -   현재 조합의 장점과 아쉬운 점을 명확히 설명하세요.
    -   "전반적으로 균형 잡혀 있습니다" 또는 "과다 섭취가 우려됩니다" 등 결론 제시.

2.  **⚠️ 중복/과다 섭취 심층 분석**
    -   위 데이터에서 `has_duplicate` 또는 `has_over_limit`가 true인 경우, 어떤 성분이 얼마나 기준치를 초과했는지 구체적으로 설명하세요.
    -   건강에 미칠 수 있는 구체적인 영향(부작용)을 경고하세요.

3.  **📉 최적화 및 제외 제안 (Optimization)**
    -   `excluded_product`가 있다면, 왜 이 제품을 빼는 것이 좋은지 **경제적 이득(월 절감액)**과 **건강 이득** 관점에서 설득력 있게 설명하세요.

4.  **💡 전문 섭취 가이드 (Timing & Tips)**
    -   식후/식전, 아침/저녁 등 구체적인 섭취 타이밍을 제안하세요.
    -   성분 간의 궁합(시너지/상충) 정보를 제공하세요.

## 🛑 필수 규칙
-   **톤앤매너**: 전문적이고 신뢰감 있게, 하지만 이해하기 쉽게(친절하게).
-   **형식**: 순수 마크다운(Markdown) 텍스트만 출력하세요. JSON 형식이 아닙니다.
-   인사말("안녕하세요 AI입니다")은 생략하고 바로 리포트 본문(제목 포함)부터 시작하세요.
-   제목은 `## 📝 프리미엄 상세 분석 리포트` 로 시작하세요.
''';

  /// Unified Single-Step Analysis
  Future<UnifiedAnalysisResult> analyzeSupplements(Uint8List imageBytes) async {
    try {
      final jsonText = await _sendRestRequest(
        prompt: _unifiedPrompt,
        imageBytes: imageBytes,
        responseMimeType: 'application/json', // Force JSON mime type
      );

      final cleanJson = _cleanJsonString(jsonText);
      final json = jsonDecode(cleanJson);
      return UnifiedAnalysisResult.fromJson(json);
    } catch (e) {
      if (e is FormatException) {
        throw Exception('AI 응답 형식이 올바르지 않습니다. (JSON Parsing Error)');
      }
      throw Exception('Unified Analysis Failed: $e');
    }
  }

  /// Step 2: Generate Premium Report (Paid)
  Future<String> generatePremiumReport(UnifiedAnalysisResult result) async {
    try {
      final summary = _createSummaryFromResult(result);
      final prompt = _premiumReportPrompt.replaceAll('{{JSON_DATA}}', summary);

      final reportMarkdown = await _sendRestRequest(
        prompt: prompt,
        imageBytes: null, // No image needed
        responseMimeType: 'text/plain',
      );

      return reportMarkdown;
    } catch (e) {
      throw Exception('Premium Report Generation Failed: $e');
    }
  }

  /// SuppleCut 프리미엄 상세 리포트 생성 (On-Demand)
  ///
  /// 1차 분석 결과를 기반으로 서술형 마크다운 리포트를 생성한다.
  Future<String> generateSuppleCutReport(SuppleCutAnalysisResult result,
      {String locale = 'ko'}) async {
    // 1차 분석 데이터를 JSON 요약으로 변환
    final summaryMap = {
      'products': result.products
          .map((p) => {
                'name': p.name,
                'source': p.source,
                'estimatedMonthlyPrice': p.estimatedMonthlyPrice,
                'ingredients': p.ingredients
                    .map((i) => '${i.name} ${i.amount}${i.unit}')
                    .toList(),
                'note': p.note,
              })
          .toList(),
      'duplicates': result.duplicates
          .map((d) => {
                'ingredient': d.ingredient,
                'riskLevel': d.riskLevel,
                'advice': d.advice,
                'products': d.products,
                'totalAmount': d.totalAmount,
                'dailyLimit': d.dailyLimit,
              })
          .toList(),
      'overallRisk': result.overallRisk,
      'monthlySavings': result.monthlySavings,
      'yearlySavings': result.yearlySavings,
      'excludedProduct': result.excludedProduct,
    };

    final jsonData = jsonEncode(summaryMap);

    final String prompt = locale == 'en'
        ? '''
You are the top pharmacist and healthcare financial expert in South Korea.
Based on the analysis data provided below, write an in-depth **Premium Consultant Report** for a premium user.

## 📋 Initial Analysis Data (JSON)
$jsonData

## ✍️ Report Writing Guide
Write a **Markdown** report consisting of the following 4 sections.

### 1. Ingredient Analysis and Necessity Evaluation
For each product:
- **Key Ingredients & Efficacy** (Ingredient names, amounts, efficacy description)
- **Necessity for General Adults** (Must/Recommended/Optional/Unnecessary + Reason)

### 2. Overlapping Ingredients Check
- Overlapping ingredient names, amounts per product, and total intake
- Evaluation against the Tolerable Upper Intake Level (UL) (Safe/Caution/Danger)
- Specific side effects if taken in excess

### 3. Exclusion Recommendations and Cost Savings
- Recommended products to exclude and the reason (Priority: Side effect risk > Simple overlap > Lack of proven efficacy)
- Monthly/Yearly savings (Use `monthlySavings`/`yearlySavings` from the JSON data)

### 4. Expert Advice
- **Intake Timing**: Specific recommendations for before/after meals, morning/evening
- **Ingredient Synergy/Conflict**: Explain synergistic or conflicting relationships
- **Alternatives**: How to supplement the key ingredients of the excluded products through food or better alternatives

## 🛑 Strict Rules
- **Tone & Manner**: Professional and trustworthy, yet easy to understand.
- **Format**: Output purely in Markdown text. NOT JSON.
- **Language**: MUST be entirely in English.
- Skip greetings and start directly with the report content.
- Start the title with `## 📝 AI Detailed Analysis Report`.
- Number each section like `### 1.`, `### 2.`, etc.
- Actively use specific figures (mg, IU, UL, etc.).
'''
        : '''
당신은 대한민국 최고의 약사(Pharmacist)이자 헬스케어 재무 전문가입니다.
아래 분석 데이터를 바탕으로, 프리미엄 사용자를 위한 **심층 컨설턴트 리포트**를 작성하세요.

## 📋 1차 분석 데이터 (JSON)
$jsonData

## ✍️ 리포트 작성 가이드
아래 4개 섹션으로 구성된 **마크다운(Markdown) 리포트**를 작성하세요.

### 1. 영양제 성분 분석 및 필요성 평가
각 제품별로:
- **주요 성분 및 효능** (성분명, 함량, 효능 설명)
- **일반 성인 섭취 필요성** (필수/권장/선택/불필요 중 하나 + 이유)

### 2. 중복 성분 점검 결과
- 중복되는 성분명, 각 제품별 함량, 총 섭취량
- 상한 섭취량(UL) 대비 판정 (안전/주의/위험)
- 과다 섭취 시 구체적 부작용 설명

### 3. 섭취 제외 권장 및 비용 절감액
- 제외 권장 제품명 및 이유 (우선순위: 부작용 위험 > 단순 중복 > 효능 입증 부족)
- 월간/연간 절감액 (위 JSON 데이터의 monthlySavings/yearlySavings 사용)

### 4. 전문가 조언
- **섭취 타이밍**: 식전/식후, 아침/저녁 구체적 추천
- **성분 간 궁합**: 시너지/상충 관계 설명
- **대안 제안**: 제외 제품의 핵심 성분을 식품이나 대안 제품으로 보충하는 방법

## 🛑 필수 규칙
- **톤앤매너**: 전문적이고 신뢰감 있게, 하지만 이해하기 쉽게(4050 세대 타겟)
- **형식**: 순수 마크다운 텍스트만 출력하세요. JSON이 아닙니다.
- 인사말 생략, 바로 리포트 본문부터 시작하세요.
- 제목은 `## 📝 AI 상세 분석 리포트` 로 시작하세요.
- 각 섹션은 `### 1.`, `### 2.` 등 번호를 붙여 구분하세요.
- 구체적 수치(mg, IU, UL 등)를 적극 활용하세요.
''';

    try {
      final reportMarkdown = await _sendRestRequest(
        prompt: prompt,
        imageBytes: null,
        responseMimeType: 'text/plain',
      );

      return reportMarkdown;
    } catch (e) {
      throw Exception('SuppleCut 상세 리포트 생성 실패: $e');
    }
  }

  String _createSummaryFromResult(UnifiedAnalysisResult result) {
    // Helper to allow AI to understand the context
    // Using jsonEncode to safe-guard against unescaped quotes
    final Map<String, dynamic> summaryMap = {
      "products": result.products
          .map((p) => {
                "brand": p.brand,
                "name": p.name,
                "ingredients": p.ingredients
                    .map((i) => "${i.name} ${i.amount}${i.unit}")
                    .toList(),
              })
          .toList(),
      "analysis": {
        "has_duplicate": result.analysis.hasDuplicate,
        "has_over_limit": result.analysis.hasOverLimit,
        "excluded_product": result.analysis.excludedProduct,
        "monthly_savings": result.analysis.monthlySavings,
        "duplicate_ingredients": result.analysis.duplicateIngredients,
        "over_limit_ingredients": result.analysis.overLimitIngredients
            .map((i) => "${i.name} (Total: ${i.total}, Limit: ${i.limit})")
            .toList(),
      }
    };

    return jsonEncode(summaryMap);
  }

  /// 로컬 DB 영양제 중복 성분 분석
  Future<Map<String, dynamic>> analyzeRedundancy(
      List<SupplementProduct> products) async {
    if (products.isEmpty) {
      return {'error': '분석할 제품이 없습니다.'};
    }

    final contextLines =
        products.map((p) => p.toGeminiContext()).join('\n---\n');

    final prompt = '''
당신은 영양제 성분 중복 분석 전문가입니다.

## 분석 대상 영양제 목록
$contextLines

## 분석 요청
위 영양제들을 동시에 복용할 때:
1. **중복 성분**: 2개 이상 제품에 포함된 동일 성분 찾기
2. **총 합산 함량**: 중복 성분의 합산 함량이 일일 상한 섭취량(UL)을 초과하는지 확인
3. **제외 권장 제품**: 불필요한 중복으로 제외 가능한 제품 판단

## 출력 형식 (JSON)
{
  "duplicate_ingredients": [
    {
      "name": "성분명",
      "products": ["제품명1", "제품명2"],
      "total_amount": 총합산함량(숫자),
      "unit": "단위",
      "daily_upper_limit": 일일상한(숫자 또는 null),
      "risk_level": "safe | warning | danger"
    }
  ],
  "excluded_products": [
    {
      "name": "제외 권장 제품명",
      "reason": "제외 이유 (한글, 1-2문장)"
    }
  ],
  "overall_assessment": "전체적인 평가 (한글, 2-3문장)",
  "synergy_tips": "섭취 시너지 팁 (한글, 1-2문장)"
}

## 규칙
- 순수 JSON만 반환. 첫 글자는 반드시 {
- 중복이 없으면 duplicate_ingredients를 빈 배열 []로
- 언어: 한국어
''';

    try {
      final responseText = await _sendRestRequest(
        prompt: prompt,
        responseMimeType: 'text/plain',
      );

      final cleanedJson = _cleanJsonString(responseText);
      return jsonDecode(cleanedJson) as Map<String, dynamic>;
    } catch (e) {
      return {
        'error': '중복 분석 실패: $e',
        'duplicate_ingredients': <Map<String, dynamic>>[],
        'excluded_products': <Map<String, dynamic>>[],
        'overall_assessment': '분석에 실패했습니다. 다시 시도해주세요.',
      };
    }
  }

  // ── SuppleCut 분석 메서드 ──

  /// 로컬 DB 제품만 중복 분석 (SuppleCutAnalysisResult 반환)
  Future<SuppleCutAnalysisResult> analyzeWithLocalData({
    required List<SupplementProduct> products,
    String locale = 'ko',
  }) async {
    if (products.isEmpty) {
      throw ArgumentError('분석할 제품이 없습니다.');
    }

    final inputs = products.map((p) => AnalysisInput.fromLocalDb(p)).toList();
    return analyzeWithFallback(inputs: inputs, locale: locale);
  }

  /// 로컬 DB + Fallback 혼합 분석
  Future<SuppleCutAnalysisResult> analyzeWithFallback({
    required List<AnalysisInput> inputs,
    String locale = 'ko',
  }) async {
    if (inputs.isEmpty) {
      throw ArgumentError('분석할 제품이 없습니다.');
    }

    final hasFallback =
        inputs.any((i) => i.source == ProductSource.geminiFallback);

    final prompt = _buildFallbackPrompt(inputs, locale);
    String responseText = '';

    try {
      responseText = await _sendRestRequest(
        prompt: prompt,
        responseMimeType: 'text/plain',
        enableGrounding: hasFallback, // Fallback이 있을 때만 구글 검색 활성화
      );

      final cleanedJson = _cleanJsonString(responseText);
      final json = jsonDecode(cleanedJson) as Map<String, dynamic>;

      // ── 제품 목록을 로컬에서 직접 구성 ──
      // AI는 분석 결과(duplicates/risk/summary)만 반환.
      // fallbackProducts에서 AI 추정 성분 정보를 가져옴.
      final fallbackProducts =
          (json['fallbackProducts'] as List<dynamic>?) ?? [];

      final productJsonList = <Map<String, dynamic>>[];
      int fallbackIdx = 0;

      for (final input in inputs) {
        if (input.source == ProductSource.localDb && input.localData != null) {
          // 로컬 DB 제품: 성분 정보를 로컬에서 직접 구성
          final localIngredients = input.localData!.localIngredients.map((ing) {
            return {
              "name": ing.name,
              "amount": ing.amount,
              "unit": ing.unit,
              "dailyValue": ing.dailyValue,
            };
          }).toList();

          productJsonList.add({
            "name": input.localData?.name ?? input.productName, // 영문명 우선 보존
            "name_ko": input.localData?.nameKo, // 한글명 추가
            "source": "local_db",
            "ingredients": localIngredients,
          });
        } else {
          // Fallback 제품: AI 응답에서 성분 정보 가져오기
          if (fallbackIdx < fallbackProducts.length) {
            final fbProduct =
                fallbackProducts[fallbackIdx] as Map<String, dynamic>;
            fbProduct['source'] = 'ai_estimated';
            productJsonList.add(fbProduct);
            fallbackIdx++;
          } else {
            // AI가 fallback 제품 정보를 반환하지 않은 경우
            productJsonList.add({
              "name": input.productName,
              "source": "ai_estimated",
              "ingredients": [],
              "confidence": "low",
              "note": "AI 응답에서 제품 정보를 찾지 못했습니다.",
            });
          }
        }
      }

      // ── 가격 매핑 (DB 가격 우선) ──
      final estimatedPrices = (json['estimatedPrices'] as List<dynamic>?) ?? [];
      final aiPriceMap = <String, int>{};
      for (final ep in estimatedPrices) {
        if (ep is Map<String, dynamic>) {
          final name = ep['productName'] as String? ?? '';
          final price = (ep['estimatedMonthlyPrice'] as num?)?.round() ?? 0;
          if (name.isNotEmpty && price > 0) {
            aiPriceMap[name] = price;
          }
        }
      }

      // 각 제품에 estimatedMonthlyPrice 설정
      for (var i = 0; i < productJsonList.length; i++) {
        final productName = productJsonList[i]['name'] as String? ?? '';

        // 로컬 DB 제품: DB 가격으로 월 환산 가격 계산 (우선)
        if (i < inputs.length &&
            inputs[i].source == ProductSource.localDb &&
            inputs[i].localData != null) {
          final monthlyPrice = _calculateMonthlyPrice(inputs[i].localData!);
          if (monthlyPrice > 0) {
            productJsonList[i]['estimatedMonthlyPrice'] = monthlyPrice;
            continue; // DB 가격 사용 성공 → AI 가격 불필요
          }
        }

        // Fallback: AI 추정 가격
        final aiPrice = aiPriceMap[productName] ?? 0;
        if (aiPrice > 0) {
          productJsonList[i]['estimatedMonthlyPrice'] = aiPrice;
        }
      }

      // products를 로컬에서 구성한 데이터로 설정
      json['products'] = productJsonList;
      // 임시 필드 제거
      json.remove('fallbackProducts');
      json.remove('estimatedPrices');

      return SuppleCutAnalysisResult.fromJson(json);
    } catch (e) {
      if (e is FormatException) {
        // ignore: avoid_print
        print('JSON Parsing Error (Fallback). Prompt size: ${prompt.length}');
        // ignore: avoid_print
        print('JSON Parsing Error: $responseText');
        throw Exception('AI 응답 형식이 올바르지 않습니다. (JSON Parsing Error)');
      }
      rethrow;
    }
  }

  /// DB 제품 가격에서 월 환산 가격을 계산한다.
  ///
  /// 제품명에서 총 정수 (예: "250 Tablets" → 250),
  /// servingSize에서 1회 섭취량 (예: "2 Tablets" → 2)을 파싱하여
  /// price / (totalCount / servingsPerDay) * 30 으로 월 가격을 구한다.
  int _calculateMonthlyPrice(SupplementProduct product) {
    if (product.price == null || product.price! <= 0) return 0;

    // 제품명에서 총 정수 추출 (예: "250 Tablets", "120 Capsules", "180정")
    final countRegex = RegExp(
      r'(\d+)\s*(?:Tablets?|Capsules?|Softgels?|Veg\s+Capsules?|Veggie\s+Capsules?|Lozenges?|Gummies|Chews|정|캡슐|구미|포|ml|g)',
      caseSensitive: false,
    );
    final totalCountMatch = countRegex.firstMatch(product.name) ??
        (product.nameKo != null
            ? countRegex.firstMatch(product.nameKo!)
            : null);
    if (totalCountMatch == null) return 0;
    final totalCount = int.tryParse(totalCountMatch.group(1)!) ?? 0;
    if (totalCount <= 0) return 0;

    // servingSize에서 1회 섭취 정수 추출 (예: "2 Tablets" → 2)
    int servingsPerDay = 1; // 기본값
    if (product.servingSize != null) {
      final servingMatch = RegExp(
        r'(\d+)',
      ).firstMatch(product.servingSize!);
      if (servingMatch != null) {
        servingsPerDay = int.tryParse(servingMatch.group(1)!) ?? 1;
      }
    }

    // 월 환산: price / (totalCount / servingsPerDay) * 30
    final daysSupply = totalCount / servingsPerDay;
    if (daysSupply <= 0) return 0;
    final monthlyPrice = (product.price! / daysSupply * 30).round();
    return monthlyPrice;
  }

  String _buildFallbackPrompt(List<AnalysisInput> inputs, String locale) {
    final hasFallback =
        inputs.any((i) => i.source == ProductSource.geminiFallback);

    // 제품 섹션 조립 (로컬 DB 제품명에는 미리 계산된 가격도 넘겨주어 AI가 검색하지 않게 함)
    final productSections = inputs.asMap().entries.map((e) {
      final promptSection = e.value.toPromptSection(e.key, locale);
      if (e.value.source == ProductSource.localDb &&
          e.value.localData != null) {
        final monthlyPrice = _calculateMonthlyPrice(e.value.localData!);
        if (monthlyPrice > 0) {
          return '$promptSection\n- (앱 자체 계산) 추정 월 환산 가격: $monthlyPrice원 (이 값을 그대로 사용하세요)';
        }
      }
      return promptSection;
    }).join('\n\n');

    final lang = locale == 'en' ? 'English' : '한국어';
    const currencyRule =
        '- 모든 가격은 **대한민국 원화(KRW)** 기준\n- 가격 검색 시 한국 내 판매가를 검색하여 추정 (예: 1개월분 30,000원)\n- estimatedMonthlyPrice는 숫자로만 반환 (예: 30000)\n- 절대 달러(USD) 등 타 통화로 반환하지 마십시오.';

    // fallbackProducts 섹션: AI 추정이 필요한 제품인 경우에만 포함
    final fallbackProductsSection = hasFallback
        ? '''
  "fallbackProducts": [
    {
      "name": "AI가 추정한 제품명",
      "ingredients": [
        {"name": "성분명", "amount": 숫자, "unit": "단위", "dailyValue": 숫자_또는_null}
      ],
      "confidence": "high/medium/low",
      "note": "추정 근거 (1문장)"
    }
  ],'''
        : '';

    return '''
당신은 영양제 성분 중복 분석 전문가입니다.

## 분석할 영양제

$productSections

## 분석 요청
${hasFallback ? '''
1. **DB 매칭된 제품**: 성분 정보가 이미 제공되었으므로, 분석에 활용만 하고 출력에 성분을 반복하지 마세요. (시간 단축이 최우선입니다)
2. **DB 매칭 실패 제품**: 이 제품들에 한해서만 Google Search를 사용하여 일반적인 성분 정보를 찾아 추정하세요.
   - fallbackProducts에 추정한 성분 정보를 포함하세요.
   - confidence를 "high"/"medium"/"low"로 표기하세요.
3. 모든 제품의 성분을 종합하여 중복 성분 및 과잉 섭취 위험을 분석하세요.
4. **DB 매칭 실패 제품**에 대해서만 Google Search를 사용하여 판매 가격을 검색하고 월 환산 가격(estimatedMonthlyPrice)을 추정하세요. DB 매칭된 제품은 이미 제공된 '(앱 자체 계산) 추정 월 환산 가격'을 그대로 사용하세요.
''' : '''
제공된 성분 정보를 사용하여 중복 성분 및 과잉 섭취 위험을 분석하세요.
(주의) 모든 영양제가 DB 매칭에 성공했습니다. 성분과 가격 정보가 이미 제공되었으므로 **Google Search 기능을 절대 켜지 마세요! (빠른 응답 속도가 생명입니다)**
각 제품의 월 환산 가격(estimatedMonthlyPrice)은 함께 제공된 '(앱 자체 계산) 추정 월 환산 가격' 숫자를 그대로 출력에 사용하세요.
'''}

## 출력 형식 (반드시 이 JSON 구조를 따르세요)
{$fallbackProductsSection
  "estimatedPrices": [
    {
      "productName": "제품명 (위 입력과 동일)",
      "estimatedMonthlyPrice": 월환산가격_숫자 (제공된 경우 그대로 사용)
    }
  ],
  "duplicates": [
    {
      "ingredient": "성분명",
      "products": ["제품명1", "제품명2"],
      "totalAmount": "합산함량 + 단위",
      "dailyLimit": "일일 상한 + 단위 또는 null",
      "riskLevel": "safe | warning | danger",
      "advice": "조언 (1-2문장)"
    }
  ],
  "overallRisk": "safe | warning | danger",
  "summary": "전체 분석 요약 (2-3문장)",
  "recommendations": ["권장사항1", "권장사항2"],
  "excludedProduct": "제외 권장 제품명 또는 null",
  "monthlySavings": 제외제품의_월환산가격_숫자_또는_0,
  "yearlySavings": monthlySavings_곱하기_12,
  "disclaimer": ${hasFallback ? '"일부 제품은 AI 추정치 기반입니다. 정확한 정보는 제품 라벨을 확인하세요."' : 'null'}
}

## 가격 규칙
$currencyRule
- estimatedMonthlyPrice = 판매가 / 섭취기간(개월)

## 기타 규칙
- 순수 JSON만 반환. 첫 글자는 반드시 {
- DB 매칭 제품의 성분을 출력에 포함하지 마세요 (토큰 절약)
- 중복이 없으면 duplicates를 빈 배열 []로
- **가장 중요한 규칙**: 성분이 서로 전혀 겹치지 않는다면(예: 오메가3, 칼슘, 아르기닌, 쏘팔메토 등) 절대로 억지로 중복(duplicates)으로 엮지 마세요.
- duplicates 배열에는 해당 성분이 [실제로 포함된 입력 제품명]만 정확히 나열해야 합니다.
- 중복 성분이 하나라도 발견되면(duplicates 배열이 비어있지 않은 경우), 반드시 중복된 제품 중 하나를 '제외 권장 제품(excludedProduct)'으로 선택하고, 그 제품의 estimatedMonthlyPrice 값을 monthlySavings에 기입하세요.
- 중복이 전혀 없을 때만 excludedProduct를 null, monthlySavings를 0으로 처리하세요.
- 언어: $lang
- 문자열 내의 큰따옴표(")는 반드시 역슬래시(\\)로 이스케이프 처리
- 배열 마지막 항목 뒤에 쉼표(,) 금지
''';
  }

  // ── 통합 파이프라인 메서드 ──

  /// 이미지에서 제품명만 추출 (OCR 전용, 분석 없음)
  Future<List<String>> extractProductNames(Uint8List imageBytes) async {
    const prompt = '''
이미지에서 영양제/건강기능식품 제품들의 정확한 제품명을 추출하세요.

## 규칙
1. 라벨에 보이는 브랜드명과 제품명을 최대한 정확히 읽으세요.
2. 한 제품당 하나의 문자열로 출력하세요.
3. "브랜드명, 제품명, 용량" 형식이 이상적입니다. (예: "NOW Foods, Calcium & Magnesium, 250 Tablets")
4. 라벨이 부분적으로 보여도 읽을 수 있는 만큼 추출하세요.
5. 순수 JSON 배열만 반환. 첫 글자는 반드시 [

## 출력 형식
["제품명1", "제품명2", "제품명3"]
''';

    try {
      final responseText = await _sendRestRequest(
        prompt: prompt,
        imageBytes: imageBytes,
        responseMimeType: 'application/json',
      );

      final cleaned = _cleanJsonString(responseText);
      final decoded = jsonDecode(cleaned);

      if (decoded is List) {
        return decoded.map((e) => e.toString()).toList();
      }
      return [];
    } catch (e) {
      throw Exception('제품명 추출 실패: $e');
    }
  }

  /// 이미지 기반 통합 분석 파이프라인
  Future<SuppleCutAnalysisResult> analyzeWithImage(
    Uint8List imageBytes, {
    String locale = 'ko',
  }) async {
    // Step 1: 이미지에서 제품명 추출
    final productNames = await extractProductNames(imageBytes);

    // ignore: avoid_print
    print('🔍 OCR Extracted Names: $productNames');

    if (productNames.isEmpty) {
      throw Exception('이미지에서 영양제를 찾을 수 없습니다.');
    }

    // Step 2 & 3: 각 제품명 → 로컬 DB 매칭 → AnalysisInput 생성
    final repo = LocalSupplementRepository.instance;
    final inputs = <AnalysisInput>[];

    for (final name in productNames) {
      // fuzzyMatchFromOcr로 로컬 DB 검색
      final matches = await repo.fuzzyMatchFromOcr(name, limit: 1);

      if (matches.isNotEmpty) {
        final match = matches.first;
        // ignore: avoid_print
        print('✅ Matched: "$name" -> "${match.name}" (Brand: ${match.brand})');

        // 매칭 성공 → 로컬 DB 데이터 사용
        inputs.add(AnalysisInput.fromLocalDb(match));
      } else {
        // ignore: avoid_print
        print('❌ No Match for: "$name" -> Fallback to Gemini');

        // 매칭 실패 → Gemini Fallback
        inputs.add(AnalysisInput.fromFallback(productName: name));
      }
    }

    // Step 4: 중복 분석 (Merge logic applied inside)
    return analyzeWithFallback(inputs: inputs, locale: locale);
  }
}
