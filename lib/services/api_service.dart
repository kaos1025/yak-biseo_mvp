import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../core/utils/keyword_cleaner.dart';
import '../models/pill.dart';
import '../models/ingredient.dart';
import '../models/redundancy_result.dart';
import 'redundancy_engine.dart';
import 'nih_dsld_service.dart';
import 'kr_food_safety_service.dart';
import 'ingredient_cache_service.dart';

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

  /// [2-PHASE ARCHITECTURE]
  /// Phase 1: AI extracts product info (name, brand, ingredients, price)
  /// Phase 2: RedundancyEngine determines status deterministically
  static Future<String> analyzeDrugImage(XFile image, String locale) async {
    final apiKey = dotenv.env['API_KEY'] ?? '';
    if (apiKey.isEmpty) {
      return _buildErrorJson("API Key가 설정되지 않았습니다. .env 파일을 확인해주세요.");
    }

    try {
      // === PHASE 1: AI Extraction (No Judgment) ===
      final extractedProducts =
          await _extractProductsFromImage(apiKey, image, locale);

      if (extractedProducts.isEmpty) {
        return _buildErrorJson(locale == 'en'
            ? "No supplements detected in the image."
            : "이미지에서 영양제를 찾을 수 없습니다.");
      }

      // === PHASE 2: Deterministic Redundancy Check ===
      final redundancyResult = RedundancyEngine.analyze(extractedProducts);

      // === PHASE 3: Generate Summary (AI explains the result) ===
      final summary = await _generateSummary(
          apiKey, extractedProducts, redundancyResult, locale);

      // === Combine Results ===
      final products = extractedProducts.map((p) {
        return {
          'id': p.id,
          'name': p.name,
          'brand': p.brand,
          'dosage': p.dosage,
          'description': '', // Can be added if needed
          'status': redundancyResult.productStatuses[p.id] ?? 'SAFE',
          'price': p.price,
        };
      }).toList();

      return jsonEncode({
        'products': products,
        'summary': summary,
        'estimated_savings': redundancyResult.estimatedSavings,
        'currency': locale == 'en' ? 'USD' : 'KRW',
        'redundancy_found': redundancyResult.hasRedundancy,
      });
    } catch (e) {
      return _buildErrorJson("Analysis error: $e");
    }
  }

  /// Phase 1: Extract products from image (AI does NOT judge redundancy)
  static Future<List<ExtractedProduct>> _extractProductsFromImage(
      String apiKey, XFile image, String locale) async {
    final model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: apiKey,
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
        temperature: 0.0, // Zero for fully consistent extraction
      ),
    );

    final isEnglish = locale == 'en';
    final languageInstruction =
        isEnglish ? "LANGUAGE: English only." : "LANGUAGE: 한국어만 사용.";

    final currencyInstruction = isEnglish
        ? "Estimate price in USD (integer)."
        : "Estimate price in KRW (integer).";

    final prompt = '''
Extract supplement product information from this image.

RULES:
1. $languageInstruction
2. DO NOT judge redundancy or safety. Just extract information.
3. $currencyInstruction
4. Extract ingredient keywords from labels if visible.

OUTPUT (JSON array):
{
  "products": [
    {
      "id": "unique_string",
      "name": "Product Name",
      "brand": "Brand/Manufacturer",
      "ingredients": "comma-separated ingredient keywords (e.g., 'Vitamin C, Zinc, Calcium')",
      "dosage": "Usage info (e.g., '1 tablet daily')",
      "price": 0
    }
  ]
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
    final jsonString = response.text ?? '{}';

    try {
      // JSON 파싱 전 제어 문자 제거 (AI 응답에 개행 등 포함될 수 있음)
      final sanitizedJson = jsonString
          .replaceAll(RegExp(r'[\x00-\x1F\x7F]', multiLine: true), ' ')
          .trim();
      final data = jsonDecode(sanitizedJson);
      final productsList = data['products'] as List<dynamic>? ?? [];
      return productsList.map((p) => ExtractedProduct.fromJson(p)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Phase 3: Generate human-readable summary based on engine result
  static Future<String> _generateSummary(
      String apiKey,
      List<ExtractedProduct> products,
      RedundancyResult redundancyResult,
      String locale) async {
    final model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: apiKey,
      generationConfig: GenerationConfig(
        temperature: 0.3, // Slightly higher for natural language
      ),
    );

    final isEnglish = locale == 'en';
    final languageInstruction = isEnglish ? "Write in English." : "한국어로 작성하세요.";

    final redundancyInfo = redundancyResult.hasRedundancy
        ? redundancyResult.redundantPairs
            .map((p) =>
                "${p.productA} + ${p.productB}: ${p.overlappingCategories.join(', ')}")
            .join('\n')
        : (isEnglish ? "No redundancy detected." : "중복이 발견되지 않았습니다.");

    final prompt = '''
Write a 2-3 sentence summary for the user.

ANALYSIS RESULT:
- Redundancy Found: ${redundancyResult.hasRedundancy}
- Redundant Pairs: 
$redundancyInfo
- Estimated Savings: ${redundancyResult.estimatedSavings}

PRODUCTS:
${products.map((p) => "- ${p.name} (${redundancyResult.productStatuses[p.id]})").join('\n')}

$languageInstruction
DO NOT contradict the "Redundancy Found" value above.
If redundancy is found, explain which products overlap and why.
If no redundancy, briefly confirm the combination is safe.
''';

    final response = await model.generateContent([Content.text(prompt)]);
    return response.text ?? (isEnglish ? "Analysis complete." : "분석이 완료되었습니다.");
  }

  static String _buildErrorJson(String message) {
    return '''
    {
      "products": [],
      "summary": "$message",
      "estimated_savings": 0,
      "currency": "KRW",
      "redundancy_found": false
    }
    ''';
  }

  // ========================================================================
  // [NEW] 4-PHASE HYBRID ARCHITECTURE: Dual API + Rules Engine
  // ========================================================================
  //
  // Phase 1: AI extracts product info (name, brand) from image
  // Phase 2: Fetch ingredients from official APIs (NIH / 식약처) + cache
  // Phase 3: Rules Engine determines redundancy deterministically
  // Phase 4: AI generates explanation based on engine result
  //
  // Key difference: Judgment is done by Rules Engine (100% consistent),
  // AI only explains the result (cannot override verdict).
  // ========================================================================

  /// [4-PHASE HYBRID ARCHITECTURE]
  /// Uses official APIs (NIH DSLD / 식약처) for ingredient data.
  /// Rules Engine makes deterministic judgments, AI only explains.
  ///
  /// [image] 분석할 이미지 (XFile)
  /// [locale] 언어 설정 ('ko' 또는 'en')
  /// [useOfficialApi] true: 공식 API 사용 (정확도 높음), false: AI only (기존 방식)
  static Future<String> analyzeWithDualApi(
    XFile image,
    String locale, {
    bool useOfficialApi = true,
  }) async {
    final apiKey = dotenv.env['API_KEY'] ?? '';
    if (apiKey.isEmpty) {
      return _buildErrorJson("API Key가 설정되지 않았습니다. .env 파일을 확인해주세요.");
    }

    try {
      // === PHASE 1: AI Product Extraction ===
      final extractedProducts =
          await _extractProductsFromImage(apiKey, image, locale);

      if (extractedProducts.isEmpty) {
        return _buildErrorJson(locale == 'en'
            ? "No supplements detected in the image."
            : "이미지에서 영양제를 찾을 수 없습니다.");
      }

      // === PHASE 2: Fetch Ingredients from Official APIs ===
      final productsWithIngredients = <ProductWithIngredients>[];

      for (final product in extractedProducts) {
        List<Ingredient> ingredients = [];
        final isKoreanProduct = _isKoreanProduct(product.name, product.brand);

        if (useOfficialApi) {
          // 캐시에서 먼저 조회 (TTL 7일)
          final cached =
              await IngredientCacheService.getIngredients(product.id);
          if (cached != null && cached.isNotEmpty) {
            ingredients = cached;
          } else {
            // Determine product origin (heuristic: Korean brands use 한글)

            if (isKoreanProduct) {
              // 식약처 API: 제품명 검색 → STDR_STND 파싱
              final searchResults =
                  await KrFoodSafetyService.searchProducts(product.name);
              if (searchResults.isNotEmpty) {
                // 검색 결과의 첫 번째 제품에서 STDR_STND 파싱
                ingredients = searchResults.first.parseIngredients();

                // STDR_STND 파싱 결과가 없으면 AI 추출 결과 사용
                if (ingredients.isEmpty) {
                  ingredients =
                      _parseAiIngredientsAsKr(product.ingredients, product.id);
                }
              } else {
                // 검색 결과가 없으면 AI 추출 결과 사용
                ingredients =
                    _parseAiIngredientsAsKr(product.ingredients, product.id);
              }
            } else {
              // NIH DSLD API: 제품명 검색 → 성분 조회
              final searchResults =
                  await NihDsldService.searchProducts(product.name);
              if (searchResults.isNotEmpty) {
                final dsldId = searchResults.first.id;
                ingredients =
                    await NihDsldService.getProductIngredients(dsldId);
              }
            }

            // 캐시에 저장 (TTL 7일)
            if (ingredients.isNotEmpty) {
              await IngredientCacheService.saveIngredients(
                product.id,
                ingredients,
              );
            }
          }
        }

        // Fallback: Use AI-extracted ingredients if official APIs fail
        if (ingredients.isEmpty) {
          ingredients =
              _parseAiIngredientsAsKr(product.ingredients, product.id);
        }

        productsWithIngredients.add(ProductWithIngredients(
          productName: product.name,
          productId: product.id,
          ingredients: ingredients,
          price: product.price,
        ));
      }

      // === PHASE 3: Deterministic Redundancy Check (Rules Engine) ===
      final currency = locale == 'en' ? 'USD' : 'KRW';
      final redundancyResult = RedundancyEngineV2.analyze(
        productsWithIngredients,
        currency: currency,
      );

      // === PHASE 4: AI Explanation (cannot override verdict) ===
      final summary = await _generateSummaryFromEngineResult(
        apiKey,
        productsWithIngredients,
        redundancyResult,
        locale,
      );

      // === Combine Results ===
      final products = extractedProducts.map((p) {
        return {
          'id': p.id,
          'name': p.name,
          'brand': p.brand,
          'dosage': p.dosage,
          'description': '',
          'status': redundancyResult.productStatuses[p.id] ?? 'SAFE',
          'price': p.price,
        };
      }).toList();

      return jsonEncode({
        'products': products,
        'summary': summary,
        'estimated_savings': redundancyResult.estimatedSavings,
        'currency': currency,
        'redundancy_found': redundancyResult.hasRedundancy,
        'analysis_method': useOfficialApi ? 'dual_api' : 'ai_only',
      });
    } catch (e) {
      return _buildErrorJson("Analysis error: $e");
    }
  }

  /// 제품이 한국 제품인지 휴리스틱 판별
  static bool _isKoreanProduct(String name, String brand) {
    final combined = '$name $brand';
    // 한글 문자 포함 여부로 판별
    return RegExp(r'[가-힣]').hasMatch(combined);
  }

  /// AI 추출 성분을 KR 파서 표준으로 변환
  static List<Ingredient> _parseAiIngredientsAsKr(
    String ingredientsStr,
    String productId,
  ) {
    if (ingredientsStr.isEmpty) return [];

    // 쉼표로 분리 후 각각 Ingredient로 변환
    return ingredientsStr
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .map((name) => Ingredient.fromKrFoodSafety(
              parsedName: name,
              productId: productId,
            ))
        .toList();
  }

  /// Phase 4: 규칙 엔진 결과를 AI가 설명
  static Future<String> _generateSummaryFromEngineResult(
    String apiKey,
    List<ProductWithIngredients> products,
    RedundancyAnalysisResult result,
    String locale,
  ) async {
    final model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: apiKey,
      generationConfig: GenerationConfig(
        temperature: 0.3,
      ),
    );

    final isEnglish = locale == 'en';
    final languageInstruction = isEnglish ? "Write in English." : "한국어로 작성하세요.";

    final pairsInfo = result.redundantPairs.isNotEmpty
        ? result.redundantPairs
            .map((p) =>
                "${p.productAName} + ${p.productBName}: ${p.overlappingGroups.join(', ')}")
            .join('\n')
        : (isEnglish ? "No redundancy detected." : "중복이 발견되지 않았습니다.");

    final prompt = '''
Write a 2-3 sentence summary for the user.

ANALYSIS RESULT (from Rules Engine - DO NOT CONTRADICT):
- Verdict: ${result.verdict.name}
- Redundancy Found: ${result.hasRedundancy}
- Redundant Pairs:
$pairsInfo
- Estimated Savings: ${result.estimatedSavings} ${result.currency}

PRODUCTS:
${products.map((p) => "- ${p.productName} (${result.productStatuses[p.productId]})").join('\n')}

$languageInstruction
Your job is to EXPLAIN the result above, NOT to judge redundancy yourself.
If redundancy is found, explain which products overlap and why.
If no redundancy, briefly confirm the combination is safe.
''';

    final response = await model.generateContent([Content.text(prompt)]);
    return response.text ?? (isEnglish ? "Analysis complete." : "분석이 완료되었습니다.");
  }
}
