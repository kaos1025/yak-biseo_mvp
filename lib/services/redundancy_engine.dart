// Deterministic Redundancy Engine v2
//
// 성분 중복 판단 규칙 엔진.
// 두 제품 이상의 성분 목록을 비교하여 ingredientGroup 기준 중복을 판단한다.
//
// 판단 기준:
// - 겹침률 50% 이상 → REDUNDANT (제거 권장)
// - 겹침률 1~49% → PARTIAL_OVERLAP (주의 필요)
// - 겹침률 0% → NO_OVERLAP
//
// 이 엔진의 판단 결과는 절대적이다. AI가 이를 번복하거나 수정해서는 안 된다.

import '../models/ingredient.dart';
import '../models/redundancy_result.dart';
import '../core/utils/primary_ingredient_extractor.dart';

/// 제품 + 성분 목록 묶음
class ProductWithIngredients {
  /// 제품 이름
  final String productName;

  /// 제품 ID (NIH: dsld_id / KR: PRDLST_REPORT_NO)
  final String productId;

  /// 귀속된 성분 목록
  final List<Ingredient> ingredients;

  /// 예상 가격 (절약금액 계산용)
  final int price;

  const ProductWithIngredients({
    required this.productName,
    required this.productId,
    required this.ingredients,
    this.price = 0,
  });

  /// 이 제품의 모든 ingredientGroup 집합
  Set<String> get ingredientGroups =>
      ingredients.map((i) => i.ingredientGroup).toSet();

  /// 이 제품의 주성분 ingredientGroup 집합 (중복 비교 대상)
  /// 제품명 키워드 + 함량 기준으로 주성분 판단
  Set<String> get primaryIngredientGroups =>
      PrimaryIngredientExtractor.extractPrimaryGroups(productName, ingredients);
}

/// 성분 중복 판단 규칙 엔진
class RedundancyEngineV2 {
  /// 멀티비타민 카테고리 (특수 처리 대상)
  static const Set<String> _multivitaminGroups = {
    'Multivitamin',
    'Multimineral',
  };

  /// 제품 목록의 성분 중복 분석
  ///
  /// [products] 분석할 제품 목록 (성분 데이터 포함)
  /// [currency] 통화 단위 ('KRW' 또는 'USD')
  /// 반환: RedundancyAnalysisResult
  static RedundancyAnalysisResult analyze(
    List<ProductWithIngredients> products, {
    String currency = 'KRW',
  }) {
    if (products.isEmpty) {
      return RedundancyAnalysisResult.empty();
    }

    if (products.length == 1) {
      return RedundancyAnalysisResult(
        verdict: RedundancyVerdict.noOverlap,
        redundantPairs: [],
        totalProductsAnalyzed: 1,
        redundantProductCount: 0,
        productStatuses: {products.first.productId: 'SAFE'},
        estimatedSavings: 0,
        currency: currency,
      );
    }

    final redundantPairs = <RedundantPair>[];
    final productStatuses = <String, String>{};

    // Step 1: 모든 제품 쌍 비교
    for (var i = 0; i < products.length; i++) {
      for (var j = i + 1; j < products.length; j++) {
        final productA = products[i];
        final productB = products[j];

        // 주성분만 비교 (부성분 제외)
        final primaryA = productA.primaryIngredientGroups;
        final primaryB = productB.primaryIngredientGroups;

        if (primaryA.isEmpty || primaryB.isEmpty) continue;

        final overlap = primaryA.intersection(primaryB);
        final minSize = primaryA.length < primaryB.length
            ? primaryA.length
            : primaryB.length;

        // 겹침률 = 겹치는 그룹 수 / min(A 그룹 수, B 그룹 수)
        final overlapPercentage = minSize > 0 ? overlap.length / minSize : 0.0;

        // 개별 판정
        RedundancyVerdict pairVerdict;
        if (overlapPercentage >= 0.5) {
          pairVerdict = RedundancyVerdict.redundant;
        } else if (overlap.isNotEmpty) {
          // 멀티비타민 특수 케이스: 단일 비타민과 겹치면 부분 중복
          final aIsMulti = _isMultivitamin(primaryA);
          final bIsMulti = _isMultivitamin(primaryB);
          if (aIsMulti || bIsMulti) {
            pairVerdict = RedundancyVerdict.partialOverlap;
          } else {
            pairVerdict = RedundancyVerdict.partialOverlap;
          }
        } else {
          pairVerdict = RedundancyVerdict.noOverlap;
        }

        // 중복 쌍 기록 (겹침이 있는 경우만)
        if (overlap.isNotEmpty) {
          redundantPairs.add(RedundantPair(
            productAName: productA.productName,
            productAId: productA.productId,
            productBName: productB.productName,
            productBId: productB.productId,
            overlappingGroups: overlap.toList(),
            overlapPercentage: overlapPercentage,
            pairVerdict: pairVerdict,
          ));

          // 상태 결정: 더 비싼 제품을 REDUNDANT로 표시
          if (pairVerdict == RedundancyVerdict.redundant) {
            if (productA.price >= productB.price && productA.price > 0) {
              productStatuses[productA.productId] = 'REDUNDANT';
              productStatuses.putIfAbsent(productB.productId, () => 'SAFE');
            } else if (productB.price > 0) {
              productStatuses[productB.productId] = 'REDUNDANT';
              productStatuses.putIfAbsent(productA.productId, () => 'SAFE');
            } else {
              // 가격 정보 없음 → 둘 다 WARNING
              productStatuses[productA.productId] = 'WARNING';
              productStatuses[productB.productId] = 'WARNING';
            }
          } else if (pairVerdict == RedundancyVerdict.partialOverlap) {
            productStatuses.putIfAbsent(productA.productId, () => 'WARNING');
            productStatuses.putIfAbsent(productB.productId, () => 'WARNING');
          }
        }
      }
    }

    // Step 2: 나머지 제품 SAFE 처리
    for (final product in products) {
      productStatuses.putIfAbsent(product.productId, () => 'SAFE');
    }

    // Step 3: 전체 판정 결정
    RedundancyVerdict overallVerdict;
    if (redundantPairs
        .any((p) => p.pairVerdict == RedundancyVerdict.redundant)) {
      overallVerdict = RedundancyVerdict.redundant;
    } else if (redundantPairs
        .any((p) => p.pairVerdict == RedundancyVerdict.partialOverlap)) {
      overallVerdict = RedundancyVerdict.partialOverlap;
    } else {
      overallVerdict = RedundancyVerdict.noOverlap;
    }

    // Step 4: 절약 금액 계산
    int savings = 0;
    for (final product in products) {
      if (productStatuses[product.productId] == 'REDUNDANT') {
        savings += product.price;
      }
    }

    return RedundancyAnalysisResult(
      verdict: overallVerdict,
      redundantPairs: redundantPairs,
      totalProductsAnalyzed: products.length,
      redundantProductCount:
          productStatuses.values.where((s) => s == 'REDUNDANT').length,
      productStatuses: productStatuses,
      estimatedSavings: savings,
      currency: currency,
    );
  }

  /// 멀티비타민 제품인지 확인
  static bool _isMultivitamin(Set<String> groups) {
    return groups.any((g) => _multivitaminGroups.contains(g));
  }
}

// ================================================
// 기존 API 호환용 레거시 코드 (점진적 마이그레이션)
// ================================================

/// 기존 ExtractedProduct (api_service.dart 호환)
class ExtractedProduct {
  final String id;
  final String name;
  final String brand;
  final String ingredients; // Raw ingredients string from AI extraction
  final String dosage;
  final int price;

  ExtractedProduct({
    required this.id,
    required this.name,
    required this.brand,
    required this.ingredients,
    required this.dosage,
    required this.price,
  });

  factory ExtractedProduct.fromJson(Map<String, dynamic> json) {
    return ExtractedProduct(
      id: json['id']?.toString() ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      name: json['name'] ?? '',
      brand: json['brand'] ?? '',
      ingredients: json['ingredients'] ?? '',
      dosage: json['dosage'] ?? '',
      price: json['price'] ?? 0,
    );
  }
}

/// 기존 RedundantPair (api_service.dart 호환)
class LegacyRedundantPair {
  final String productA;
  final String productB;
  final List<String> overlappingCategories;
  final int overlapPercentage;

  LegacyRedundantPair({
    required this.productA,
    required this.productB,
    required this.overlappingCategories,
    required this.overlapPercentage,
  });
}

/// 기존 RedundancyResult (api_service.dart 호환)
class RedundancyResult {
  final bool hasRedundancy;
  final List<LegacyRedundantPair> redundantPairs;
  final Map<String, String> productStatuses;
  final int estimatedSavings;

  RedundancyResult({
    required this.hasRedundancy,
    required this.redundantPairs,
    required this.productStatuses,
    required this.estimatedSavings,
  });
}

/// 기존 RedundancyEngine (api_service.dart 호환)
/// 점진적 마이그레이션 후 제거 예정
class RedundancyEngine {
  /// Ingredient categories for overlap detection
  static const Map<String, List<String>> ingredientCategories = {
    'vitamin_a': [
      'vitamin a',
      '비타민a',
      '비타민 a',
      'retinol',
      '레티놀',
      'beta-carotene',
      '베타카로틴'
    ],
    'vitamin_b': [
      'vitamin b',
      '비타민b',
      '비타민 b',
      'b-complex',
      'b complex',
      'thiamine',
      'riboflavin',
      'niacin',
      'b1',
      'b2',
      'b6',
      'b12',
      'folate',
      'folic acid',
      '엽산'
    ],
    'vitamin_c': ['vitamin c', '비타민c', '비타민 c', 'ascorbic acid', '아스코르빈산'],
    'vitamin_d': [
      'vitamin d',
      '비타민d',
      '비타민 d',
      'cholecalciferol',
      'calciferol',
      'd3'
    ],
    'vitamin_e': ['vitamin e', '비타민e', '비타민 e', 'tocopherol', '토코페롤'],
    'vitamin_k': ['vitamin k', '비타민k', '비타민 k'],
    'calcium': ['calcium', '칼슘', 'ca', 'calcium carbonate', 'calcium citrate'],
    'magnesium': [
      'magnesium',
      '마그네슘',
      'mg',
      'magnesium oxide',
      'magnesium citrate'
    ],
    'iron': ['iron', '철', '철분', 'ferrous', 'ferric'],
    'zinc': ['zinc', '아연', 'zn'],
    'selenium': ['selenium', '셀레늄', '셀레니움'],
    'omega3': [
      'omega-3',
      'omega 3',
      '오메가3',
      '오메가-3',
      'fish oil',
      'epa',
      'dha',
      '어유',
      'krill oil',
      '크릴오일'
    ],
    'multivitamin': [
      'multivitamin',
      'multi-vitamin',
      '멀티비타민',
      '종합비타민',
      '복합비타민',
      'multimineral',
      '종합영양제'
    ],
    'probiotics': [
      'probiotic',
      '프로바이오틱',
      '유산균',
      'lactobacillus',
      'bifidobacterium',
      '비피더스'
    ],
    'collagen': ['collagen', '콜라겐'],
    'coq10': ['coq10', 'coenzyme q10', '코엔자임', '코큐텐'],
    'glucosamine': ['glucosamine', '글루코사민'],
    'lutein': ['lutein', '루테인'],
    'biotin': ['biotin', '비오틴'],
  };

  static const List<String> broadSpectrumCategories = ['multivitamin'];

  static RedundancyResult analyze(List<ExtractedProduct> products) {
    final redundantPairs = <LegacyRedundantPair>[];
    final productStatuses = <String, String>{};
    final productCategories = <String, Set<String>>{};

    for (var product in products) {
      productCategories[product.id] = _getCategories(product);
    }

    for (var i = 0; i < products.length; i++) {
      for (var j = i + 1; j < products.length; j++) {
        final productA = products[i];
        final productB = products[j];

        final categoriesA = productCategories[productA.id]!;
        final categoriesB = productCategories[productB.id]!;

        final overlap = categoriesA.intersection(categoriesB);
        final union = categoriesA.union(categoriesB);

        if (union.isEmpty) continue;

        final overlapPercentage = (overlap.length / union.length * 100).round();

        bool isRedundant = overlapPercentage >= 50;

        if (!isRedundant) {
          final aIsMulti = categoriesA.contains('multivitamin');
          final bIsMulti = categoriesB.contains('multivitamin');

          if (aIsMulti || bIsMulti) {
            if (overlap.isNotEmpty) {
              isRedundant = true;
            }
          }
        }

        if (isRedundant && overlap.isNotEmpty) {
          redundantPairs.add(LegacyRedundantPair(
            productA: productA.name,
            productB: productB.name,
            overlappingCategories: overlap.toList(),
            overlapPercentage: overlapPercentage,
          ));

          if (productA.price >= productB.price && productA.price > 0) {
            productStatuses[productA.id] = 'REDUNDANT';
            productStatuses.putIfAbsent(productB.id, () => 'SAFE');
          } else if (productB.price > 0) {
            productStatuses[productB.id] = 'REDUNDANT';
            productStatuses.putIfAbsent(productA.id, () => 'SAFE');
          } else {
            productStatuses[productA.id] = 'WARNING';
            productStatuses[productB.id] = 'WARNING';
          }
        }
      }
    }

    for (var product in products) {
      productStatuses.putIfAbsent(product.id, () => 'SAFE');
    }

    int savings = 0;
    for (var product in products) {
      if (productStatuses[product.id] == 'REDUNDANT') {
        savings += product.price;
      }
    }

    return RedundancyResult(
      hasRedundancy: redundantPairs.isNotEmpty,
      redundantPairs: redundantPairs,
      productStatuses: productStatuses,
      estimatedSavings: savings,
    );
  }

  static Set<String> _getCategories(ExtractedProduct product) {
    final categories = <String>{};
    final text = '${product.name} ${product.ingredients}'.toLowerCase();

    for (var entry in ingredientCategories.entries) {
      for (var keyword in entry.value) {
        if (text.contains(keyword)) {
          categories.add(entry.key);
          break;
        }
      }
    }

    return categories;
  }
}
