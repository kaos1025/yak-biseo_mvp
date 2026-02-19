import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../models/supplement_analysis.dart';
import '../models/consultant_result.dart';
import '../models/supplement_product.dart';
import '../models/unified_analysis_result.dart';

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

        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            "contents": [
              {"parts": parts}
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

  /// JSON 문자열 정리 (Markdown 코드 블록 제거 및 순수 JSON 추출)
  String _cleanJsonString(String text) {
    String clean = text;

    // 1. Remove Markdown code blocks first
    clean = clean
        .replaceAll(RegExp(r'```json', caseSensitive: false), '')
        .replaceAll(RegExp(r'```', caseSensitive: false), '');

    // 2. Find the first '{' and last '}'
    final startIndex = clean.indexOf('{');
    final endIndex = clean.lastIndexOf('}');

    // 3. If valid JSON brackets allow extraction
    if (startIndex != -1 && endIndex != -1 && endIndex > startIndex) {
      return clean.substring(startIndex, endIndex + 1);
    }

    return clean.trim();
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
        // Use standard analyzeImage (old method) or new?
        // consistencyTest was using analyzeImage which returns AnalyzeResult.
        // analyzeImage is still there (lines 87-102 of original).
        // So this is fine.
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
    -   **중요**: 문자열 내의 큰따옴표(")는 반드시 역슬래시(\)로 이스케이프 처리하세요.
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
      // Debug print to see raw output if parsing fails
      // print("Cleaned JSON: $cleanJson");

      final json = jsonDecode(cleanJson);
      return UnifiedAnalysisResult.fromJson(json);
    } catch (e) {
      if (e is FormatException) {
        // Retry once with a simpler prompt or just re-throw with clear message
        // For now, let's allow the UI to show the error but make it clearer
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
  ///
  /// [products] 사용자가 선택한 영양제 제품 목록
  /// 반환: Gemini 분석 결과 (중복 성분, 상한 초과, 제외 권장 등)
  Future<Map<String, dynamic>> analyzeRedundancy(
      List<SupplementProduct> products) async {
    if (products.isEmpty) {
      return {'error': '분석할 제품이 없습니다.'};
    }

    // 제품 정보를 Gemini context로 변환
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
}
