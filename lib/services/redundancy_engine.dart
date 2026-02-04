import '../models/ingredient.dart';
import '../models/redundancy_result.dart';
import '../models/product_with_ingredients.dart';
import 'nutrient_limit_engine.dart';

/// 성분 중복 판단 규칙 엔진 (Deterministic)
///
/// 개선 사항:
/// 1. Jaccard Index 도입으로 중복 오탐지 최소화
/// 2. ProductWithIngredients 모델 도입 (함량 포함)
/// 3. NutrientLimitEngine 통합 (UL/RDA 분석)
class RedundancyEngine {
  /// 제품 목록의 성분 중복 및 과다 섭취 분석
  static RedundancyAnalysisResult analyze(
    List<ProductWithIngredients> products, {
    String currency = 'KRW',
  }) {
    if (products.isEmpty) {
      return RedundancyAnalysisResult.empty();
    }

    if (products.length == 1) {
      // 단일 제품이라도 UL 분석은 수행해야 함
      final ulReport = NutrientLimitEngine.analyze(products);
      final statuses = {products.first.productId: 'SAFE'};

      // UL 초과 시 WARNING 처리
      _applyUlWarnings(statuses, ulReport);

      return RedundancyAnalysisResult(
        verdict: RedundancyVerdict.noOverlap,
        redundantPairs: [],
        totalProductsAnalyzed: 1,
        redundantProductCount: 0,
        productStatuses: statuses,
        estimatedSavings: 0,
        currency: currency,
        ulRdaReport: ulReport,
      );
    }

    final redundantPairs = <RedundantPair>[];
    final productStatuses = <String, String>{};

    // Step 1: 중복 분석 (Primary Ingredient Jaccard Index)
    for (var i = 0; i < products.length; i++) {
      for (var j = i + 1; j < products.length; j++) {
        final productA = products[i];
        final productB = products[j];

        // 주성분만 비교
        final primaryA = productA.primaryIngredientGroups;
        final primaryB = productB.primaryIngredientGroups;

        if (primaryA.isEmpty || primaryB.isEmpty) {
          continue;
        }

        final overlap = primaryA.intersection(primaryB);
        final union = primaryA.union(primaryB);

        // Jaccard Index = Intersection / Union
        final jaccardIndex =
            union.isNotEmpty ? overlap.length / union.length : 0.0;

        // 기존 50% 기준 유지 (Jaccard 기준)
        RedundancyVerdict pairVerdict;
        if (jaccardIndex >= 0.5) {
          pairVerdict = RedundancyVerdict.redundant;
        } else if (overlap.isNotEmpty) {
          // 멀티비타민 특수 케이스: 단일 비타민과 겹치면 부분 중복
          // Jaccard가 낮아도 교집합이 있으면 부분 중복 처리 (안전장치)
          pairVerdict = RedundancyVerdict.partialOverlap;
        } else {
          pairVerdict = RedundancyVerdict.noOverlap;
        }

        if (overlap.isNotEmpty) {
          redundantPairs.add(RedundantPair(
            productAName: productA.productName,
            productAId: productA.productId,
            productBName: productB.productName,
            productBId: productB.productId,
            overlappingGroups: overlap.toList(),
            overlapPercentage: jaccardIndex, // 0.0 ~ 1.0 (toAiContext에서 %로 변환됨)
            pairVerdict: pairVerdict,
          ));

          _updateStatuses(productStatuses, productA, productB, pairVerdict);
        }
      }
    }

    // 초기 SAFE 설정 (아직 상태 없는 제품들)
    for (final product in products) {
      productStatuses.putIfAbsent(product.productId, () => 'SAFE');
    }

    // Step 2: UL/RDA 분석
    final ulReport = NutrientLimitEngine.analyze(products);

    // Step 3: UL 초과 제품 WARNING 승격
    _applyUlWarnings(productStatuses, ulReport);

    // Step 4: 전체 판정 요약
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

    // Step 5: 절약 금액 (REDUNDANT 제품 가격 합산)
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
      ulRdaReport: ulReport,
    );
  }

  static void _updateStatuses(
      Map<String, String> statuses,
      ProductWithIngredients a,
      ProductWithIngredients b,
      RedundancyVerdict verdict) {
    if (verdict == RedundancyVerdict.redundant) {
      // 비싼 쪽을 제거 권장
      if (a.price >= b.price && a.price > 0) {
        statuses[a.productId] = 'REDUNDANT';
        statuses.putIfAbsent(b.productId, () => 'SAFE');
      } else if (b.price > 0) {
        statuses[b.productId] = 'REDUNDANT';
        statuses.putIfAbsent(a.productId, () => 'SAFE');
      } else {
        statuses[a.productId] = 'WARNING';
        statuses[b.productId] = 'WARNING';
      }
    } else if (verdict == RedundancyVerdict.partialOverlap) {
      // 이미 REDUNDANT면 유지, 아니면 WARNING
      if (statuses[a.productId] != 'REDUNDANT') {
        statuses[a.productId] = 'WARNING';
      }
      if (statuses[b.productId] != 'REDUNDANT') {
        statuses[b.productId] = 'WARNING';
      }
    }
  }

  static void _applyUlWarnings(
      Map<String, String> statuses, UlRdaReport report) {
    for (final nutrientKey in report.exceededUlNutrients) {
      // 해당 영양소 상세 정보 찾기
      final summary = report.summaries.firstWhere(
          (s) => s.nutrientKey == nutrientKey,
          orElse: () => report.summaries.first);

      // 기여한 모든 제품을 찾아서 WARNING 처리
      for (final contributor in summary.contributors) {
        final pid = contributor.productId;
        if (statuses[pid] == 'SAFE') {
          statuses[pid] = 'WARNING';
        }
      }
    }
  }
}

// ================================================
// Legacy Compatibility Models (to be migrated)
// ================================================

/// 기존 ExtractedProduct (api_service.dart 호환용 유지)
class ExtractedProduct {
  final String id;
  final String name;
  final String brand;
  final String ingredients; // Raw string
  final String dosage;
  final int price;

  // 원본 영문 제품명 (NIH API 검색용)
  final String? originalName;

  // New fields for structure (Nullable for backward compatibility)
  final List<Ingredient>? parsedIngredients;

  ExtractedProduct({
    required this.id,
    required this.name,
    required this.brand,
    required this.ingredients,
    required this.dosage,
    required this.price,
    this.originalName,
    this.parsedIngredients,
  });

  factory ExtractedProduct.fromJson(Map<String, dynamic> json) {
    List<Ingredient>? parsed;
    if (json['parsedIngredients'] != null) {
      parsed = (json['parsedIngredients'] as List)
          .map((i) => Ingredient.fromJson(i))
          .toList();
    }

    return ExtractedProduct(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      brand: json['brand'] ?? '',
      ingredients: json['ingredients'] ?? '', // Legacy string
      dosage: json['dosage'] ?? '',
      price: json['price'] ?? 0,
      originalName: json['originalName'] as String?,
      parsedIngredients: parsed,
    );
  }
}
