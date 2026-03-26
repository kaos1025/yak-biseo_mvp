import '../services/exclusion_engine.dart';
import 'supplecut_analysis_result.dart';

/// Gemini/Claude 원스톱 분석 결과 모델
///
/// 제품 식별 + 성분 + 중복 + 기전 중복 + 안전성 경고 + 제외 추천을
/// 단일 API 호출로 받는 응답 스키마.
class OnestopAnalysisResult {
  final List<OnestopProduct> products;
  final List<OnestopOverlap> overlaps;
  final List<FunctionalOverlap> functionalOverlaps;
  final List<SafetyAlert> safetyAlerts;
  final List<SingleProductUlExcess> singleProductUlExcess;
  final List<UlAtLimit> ulAtLimit;
  final ExclusionRecommendation? exclusionRecommendation;
  final String overallStatus; // "perfect" | "caution" | "warning"
  final String statusReason;

  const OnestopAnalysisResult({
    required this.products,
    required this.overlaps,
    required this.functionalOverlaps,
    required this.safetyAlerts,
    required this.singleProductUlExcess,
    this.ulAtLimit = const [],
    this.exclusionRecommendation,
    required this.overallStatus,
    required this.statusReason,
  });

  factory OnestopAnalysisResult.fromJson(Map<String, dynamic> json) {
    return OnestopAnalysisResult(
      products: (json['products'] as List<dynamic>? ?? [])
          .map((e) => OnestopProduct.fromJson(e as Map<String, dynamic>))
          .toList(),
      overlaps: (json['overlaps'] as List<dynamic>? ?? [])
          .map((e) => OnestopOverlap.fromJson(e as Map<String, dynamic>))
          .toList(),
      functionalOverlaps: (json['functional_overlaps'] as List<dynamic>? ?? [])
          .map((e) => FunctionalOverlap.fromJson(e as Map<String, dynamic>))
          .toList(),
      safetyAlerts: (json['safety_alerts'] as List<dynamic>? ?? [])
          .map((e) => SafetyAlert.fromJson(e as Map<String, dynamic>))
          .toList(),
      singleProductUlExcess: (json['single_product_ul_excess']
                  as List<dynamic>? ??
              [])
          .map((e) => SingleProductUlExcess.fromJson(e as Map<String, dynamic>))
          .toList(),
      ulAtLimit: (json['ul_at_limit'] as List<dynamic>? ?? [])
          .map((e) => UlAtLimit.fromJson(e as Map<String, dynamic>))
          .toList(),
      exclusionRecommendation: json['exclusion_recommendation'] != null
          ? ExclusionRecommendation.fromJson(
              json['exclusion_recommendation'] as Map<String, dynamic>)
          : null,
      overallStatus: json['overall_status'] as String? ?? 'caution',
      statusReason: json['status_reason'] as String? ?? '',
    )._enforceOverallStatus();
  }

  /// normalized_key → { ul, unit } 룩업 테이블
  static const _ulTable = <String, ({double ul, String unit})>{
    'vitamin_d': (ul: 100, unit: 'mcg'),
    'zinc': (ul: 40, unit: 'mg'),
    'vitamin_b6': (ul: 100, unit: 'mg'),
    'folate': (ul: 1000, unit: 'mcg'),
    'niacin': (ul: 35, unit: 'mg'),
    'iodine': (ul: 1100, unit: 'mcg'),
    'iron': (ul: 45, unit: 'mg'),
    'vitamin_a': (ul: 3000, unit: 'mcg'),
    'magnesium': (ul: 350, unit: 'mg'),
    'vitamin_c': (ul: 2000, unit: 'mg'),
    'vitamin_e': (ul: 1000, unit: 'mg'),
    'calcium': (ul: 2500, unit: 'mg'),
    'selenium': (ul: 400, unit: 'mcg'),
  };

  /// 제품 성분에서 UL의 95~100%에 해당하는 항목을 계산
  List<UlAtLimit> _computeUlAtLimit() {
    final result = <UlAtLimit>[];
    // 이미 single_product_ul_excess에 있는 (product, ingredient) 쌍은 제외
    final excessKeys = singleProductUlExcess
        .map((e) => '${e.product}::${e.ingredient}')
        .toSet();

    for (final product in products) {
      for (final ing in product.ingredients) {
        final key = ing.normalizedKey;
        if (key == null) continue;
        final ref = _ulTable[key];
        if (ref == null) continue;
        // 단위가 다르면 스킵 (안전)
        if (ing.unit.toLowerCase() != ref.unit.toLowerCase()) continue;
        if (ref.ul <= 0) continue;

        final pct = (ing.amount / ref.ul * 100).round();
        if (pct >= 95 && pct <= 100) {
          final pairKey = '${product.name}::${ing.name}';
          if (excessKeys.contains(pairKey)) continue;
          result.add(UlAtLimit(
            product: product.name,
            ingredient: ing.name,
            amount: ing.amount,
            unit: ing.unit,
            ul: ref.ul,
            percentageOfUl: pct,
            message:
                'At UL. Any additional ${ing.name} from food or other supplements would exceed safe limits.',
          ));
        }
      }
    }
    return result;
  }

  /// AI 응답의 overall_status를 규칙 기반으로 강제 보정
  ///
  /// 단방향 격상만 수행 — 절대 다운그레이드 없음.
  OnestopAnalysisResult _enforceOverallStatus() {
    // ul_at_limit 결정적 계산 (Gemini 반환 + 앱 계산 병합)
    final computed = _computeUlAtLimit();
    final existingKeys =
        ulAtLimit.map((e) => '${e.product}::${e.ingredient}').toSet();
    final merged = [
      ...ulAtLimit,
      ...computed.where(
          (c) => !existingKeys.contains('${c.product}::${c.ingredient}')),
    ];
    // warning 조건
    final hasWarning = safetyAlerts.isNotEmpty ||
        functionalOverlaps.any((fo) => fo.severity == 'high') ||
        safetyAlerts.any((sa) =>
            sa.alertType == 'research_chemical' ||
            sa.alertType == 'therapeutic_dose') ||
        overlaps.any(
            (o) => o.ul != null && o.ul! > 0 && o.totalAmount / o.ul! >= 2.0) ||
        functionalOverlaps.any((fo) => fo.products.length >= 3);

    if (hasWarning && overallStatus != 'warning') {
      return OnestopAnalysisResult(
        products: products,
        overlaps: overlaps,
        functionalOverlaps: functionalOverlaps,
        safetyAlerts: safetyAlerts,
        singleProductUlExcess: singleProductUlExcess,
        ulAtLimit: merged,
        exclusionRecommendation: exclusionRecommendation,
        overallStatus: 'warning',
        statusReason: statusReason,
      );
    }

    // caution 조건 (warning 아닌 경우만)
    final hasCaution = singleProductUlExcess.isNotEmpty ||
        merged.isNotEmpty ||
        functionalOverlaps.isNotEmpty ||
        overlaps.any((o) => o.exceedsUl);

    if (hasCaution && overallStatus == 'perfect') {
      return OnestopAnalysisResult(
        products: products,
        overlaps: overlaps,
        functionalOverlaps: functionalOverlaps,
        safetyAlerts: safetyAlerts,
        singleProductUlExcess: singleProductUlExcess,
        ulAtLimit: merged,
        exclusionRecommendation: exclusionRecommendation,
        overallStatus: 'caution',
        statusReason: statusReason,
      );
    }

    // merged가 원본과 다르면 (계산된 항목 추가됨) 새 인스턴스 반환
    if (merged.length != ulAtLimit.length) {
      return OnestopAnalysisResult(
        products: products,
        overlaps: overlaps,
        functionalOverlaps: functionalOverlaps,
        safetyAlerts: safetyAlerts,
        singleProductUlExcess: singleProductUlExcess,
        ulAtLimit: merged,
        exclusionRecommendation: exclusionRecommendation,
        overallStatus: overallStatus,
        statusReason: statusReason,
      );
    }

    return this;
  }

  Map<String, dynamic> toJson() {
    return {
      'products': products.map((e) => e.toJson()).toList(),
      'overlaps': overlaps.map((e) => e.toJson()).toList(),
      'functional_overlaps': functionalOverlaps.map((e) => e.toJson()).toList(),
      'safety_alerts': safetyAlerts.map((e) => e.toJson()).toList(),
      'single_product_ul_excess':
          singleProductUlExcess.map((e) => e.toJson()).toList(),
      'ul_at_limit': ulAtLimit.map((e) => e.toJson()).toList(),
      if (exclusionRecommendation != null)
        'exclusion_recommendation': exclusionRecommendation!.toJson(),
      'overall_status': overallStatus,
      'status_reason': statusReason,
    };
  }

  /// 기존 UI 호환용 변환
  SuppleCutAnalysisResult toSuppleCutAnalysisResult() {
    // overallStatus 매핑: perfect→safe, caution→warning, warning→danger
    String overallRisk;
    switch (overallStatus) {
      case 'perfect':
        overallRisk = 'safe';
        break;
      case 'caution':
        overallRisk = 'warning';
        break;
      case 'warning':
        overallRisk = 'danger';
        break;
      default:
        overallRisk = 'safe';
    }

    final convertedDuplicates = overlaps
        .map((o) => DuplicateIngredient(
              ingredient: o.ingredient,
              products: o.sources.map((s) => s.product).toList(),
              totalAmount: '${o.totalAmount}${o.unit}',
              dailyLimit: o.ul != null ? '${o.ul}${o.ulUnit ?? o.unit}' : null,
              riskLevel: o.severity,
              advice: o.exceedsUl
                  ? '합산 섭취량이 일일 상한(UL)을 초과합니다.'
                  : '중복되지만 안전 범위 내입니다.',
            ))
        .toList();

    // ExclusionEngine으로 제외 추천 결정적 계산 (Gemini 결과 덮어씌움)
    final exclusion = ExclusionEngine.calculate(
      products: products,
      functionalOverlaps: functionalOverlaps,
      safetyAlerts: safetyAlerts,
      duplicates: convertedDuplicates,
    );

    return SuppleCutAnalysisResult(
      products: products
          .map((p) => AnalyzedProduct(
                name: p.name,
                source: p.source == 'label' || p.source == 'known'
                    ? 'local_db'
                    : 'ai_estimated',
                ingredients: p.ingredients
                    .map((i) => AnalyzedIngredient(
                          name: i.name,
                          amount: i.amount,
                          unit: i.unit,
                        ))
                    .toList(),
                estimatedMonthlyPrice:
                    (p.monthlyCostEstimate * 1400).round(), // USD→KRW 근사
                monthlyCostUsd: p.monthlyCostEstimate,
              ))
          .toList(),
      duplicates: convertedDuplicates,
      overallRisk: overallRisk,
      summary: statusReason,
      recommendations: _buildRecommendations(),
      monthlySavings: (exclusion.monthlySavings * 1400).round(),
      yearlySavings: (exclusion.annualSavings * 1400).round(),
      excludedProduct:
          exclusion.hasExclusion ? exclusion.excludedProducts.join(', ') : null,
      functionalOverlaps: functionalOverlaps,
      safetyAlerts: safetyAlerts,
      singleProductUlExcess: singleProductUlExcess,
      ulAtLimit: ulAtLimit,
      exclusionResult: exclusion.hasExclusion ? exclusion : null,
    );
  }

  List<String> _buildRecommendations() {
    final recs = <String>[];
    for (final fo in functionalOverlaps) {
      recs.add('[Mechanism Overlap] ${fo.pathway}: ${fo.warning}');
    }
    for (final sa in safetyAlerts) {
      recs.add('[Safety Alert] ${sa.product}: ${sa.summary}');
    }
    if (exclusionRecommendation?.excludeProduct != null) {
      recs.add(
          '[제외 추천] ${exclusionRecommendation!.excludeProduct}: ${exclusionRecommendation!.reason}');
    }
    return recs;
  }

  bool get hasOverlaps => overlaps.isNotEmpty;
  bool get hasFunctionalOverlaps => functionalOverlaps.isNotEmpty;
  bool get hasSafetyAlerts => safetyAlerts.isNotEmpty;
}

/// 제품
class OnestopProduct {
  final String name;
  final String source; // "label" | "known" | "estimated"
  final double monthlyCostEstimate;
  final List<OnestopIngredient> ingredients;

  const OnestopProduct({
    required this.name,
    required this.source,
    required this.monthlyCostEstimate,
    required this.ingredients,
  });

  factory OnestopProduct.fromJson(Map<String, dynamic> json) {
    return OnestopProduct(
      name: json['name'] as String? ?? '',
      source: json['source'] as String? ?? 'estimated',
      monthlyCostEstimate:
          (json['monthly_cost_estimate'] as num?)?.toDouble() ?? 0.0,
      ingredients: (json['ingredients'] as List<dynamic>? ?? [])
          .map((e) => OnestopIngredient.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'source': source,
        'monthly_cost_estimate': monthlyCostEstimate,
        'ingredients': ingredients.map((e) => e.toJson()).toList(),
      };
}

/// 성분
class OnestopIngredient {
  final String name;
  final double amount;
  final String unit;
  final String? normalizedKey;

  const OnestopIngredient({
    required this.name,
    required this.amount,
    required this.unit,
    this.normalizedKey,
  });

  factory OnestopIngredient.fromJson(Map<String, dynamic> json) {
    return OnestopIngredient(
      name: json['name'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      unit: json['unit'] as String? ?? '',
      normalizedKey: json['normalized_key'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'amount': amount,
        'unit': unit,
        if (normalizedKey != null) 'normalized_key': normalizedKey,
      };
}

/// 성분 중복
class OnestopOverlap {
  final String ingredient;
  final String? normalizedKey;
  final double totalAmount;
  final String unit;
  final double? ul;
  final String? ulUnit;
  final bool exceedsUl;
  final List<OverlapSource> sources;
  final String severity; // "high" | "medium" | "low" | "none"

  const OnestopOverlap({
    required this.ingredient,
    this.normalizedKey,
    required this.totalAmount,
    required this.unit,
    this.ul,
    this.ulUnit,
    required this.exceedsUl,
    required this.sources,
    required this.severity,
  });

  factory OnestopOverlap.fromJson(Map<String, dynamic> json) {
    return OnestopOverlap(
      ingredient: json['ingredient'] as String? ?? '',
      normalizedKey: json['normalized_key'] as String?,
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0.0,
      unit: json['unit'] as String? ?? '',
      ul: (json['ul'] as num?)?.toDouble(),
      ulUnit: json['ul_unit'] as String?,
      exceedsUl: json['exceeds_ul'] as bool? ?? false,
      sources: (json['sources'] as List<dynamic>? ?? [])
          .map((e) => OverlapSource.fromJson(e as Map<String, dynamic>))
          .toList(),
      severity: json['severity'] as String? ?? 'none',
    );
  }

  Map<String, dynamic> toJson() => {
        'ingredient': ingredient,
        if (normalizedKey != null) 'normalized_key': normalizedKey,
        'total_amount': totalAmount,
        'unit': unit,
        if (ul != null) 'ul': ul,
        if (ulUnit != null) 'ul_unit': ulUnit,
        'exceeds_ul': exceedsUl,
        'sources': sources.map((e) => e.toJson()).toList(),
        'severity': severity,
      };
}

class OverlapSource {
  final String product;
  final double amount;
  final String? unit;

  const OverlapSource({
    required this.product,
    required this.amount,
    this.unit,
  });

  factory OverlapSource.fromJson(Map<String, dynamic> json) {
    return OverlapSource(
      product: json['product'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      unit: json['unit'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'product': product,
        'amount': amount,
        if (unit != null) 'unit': unit,
      };
}

/// 기전 중복
class FunctionalOverlap {
  final String pathway;
  final String severity; // "high" | "medium" | "low"
  final List<String> products;
  final String warning;

  const FunctionalOverlap({
    required this.pathway,
    required this.severity,
    required this.products,
    required this.warning,
  });

  factory FunctionalOverlap.fromJson(Map<String, dynamic> json) {
    return FunctionalOverlap(
      pathway: json['pathway'] as String? ?? '',
      severity: json['severity'] as String? ?? 'medium',
      products: (json['products'] as List<dynamic>? ?? [])
          .map((e) => e as String)
          .toList(),
      warning: json['warning'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'pathway': pathway,
        'severity': severity,
        'products': products,
        'warning': warning,
      };
}

/// 안전성 경고
class SafetyAlert {
  final String product;
  final String
      alertType; // "regulatory_warning" | "research_chemical" | "otc_drug" | "therapeutic_dose"
  final String severity;
  final String summary;
  final String? details;

  const SafetyAlert({
    required this.product,
    required this.alertType,
    required this.severity,
    required this.summary,
    this.details,
  });

  factory SafetyAlert.fromJson(Map<String, dynamic> json) {
    return SafetyAlert(
      product: json['product'] as String? ?? '',
      alertType: json['alert_type'] as String? ?? 'regulatory_warning',
      severity: json['severity'] as String? ?? 'medium',
      summary: json['summary'] as String? ?? '',
      details: json['details'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'product': product,
        'alert_type': alertType,
        'severity': severity,
        'summary': summary,
        if (details != null) 'details': details,
      };
}

/// 단일 제품 UL 초과
class SingleProductUlExcess {
  final String product;
  final String ingredient;
  final String amount;
  final String ul;
  final String severity;
  final String? warning;

  const SingleProductUlExcess({
    required this.product,
    required this.ingredient,
    required this.amount,
    required this.ul,
    required this.severity,
    this.warning,
  });

  factory SingleProductUlExcess.fromJson(Map<String, dynamic> json) {
    return SingleProductUlExcess(
      product: json['product'] as String? ?? '',
      ingredient: json['ingredient'] as String? ?? '',
      amount: json['amount']?.toString() ?? '',
      ul: json['ul']?.toString() ?? '',
      severity: json['severity'] as String? ?? 'medium',
      warning: json['warning'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'product': product,
        'ingredient': ingredient,
        'amount': amount,
        'ul': ul,
        'severity': severity,
        if (warning != null) 'warning': warning,
      };
}

/// 단일 제품 UL 근접 (95~100%)
class UlAtLimit {
  final String product;
  final String ingredient;
  final double amount;
  final String unit;
  final double ul;
  final int percentageOfUl;
  final String message;

  const UlAtLimit({
    required this.product,
    required this.ingredient,
    required this.amount,
    required this.unit,
    required this.ul,
    required this.percentageOfUl,
    required this.message,
  });

  factory UlAtLimit.fromJson(Map<String, dynamic> json) {
    return UlAtLimit(
      product: json['product'] as String? ?? '',
      ingredient: json['ingredient'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      unit: json['unit'] as String? ?? '',
      ul: (json['ul'] as num?)?.toDouble() ?? 0.0,
      percentageOfUl: (json['percentage_of_ul'] as num?)?.round() ?? 0,
      message: json['message'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'product': product,
        'ingredient': ingredient,
        'amount': amount,
        'unit': unit,
        'ul': ul,
        'percentage_of_ul': percentageOfUl,
        'message': message,
      };
}

/// 제외 추천
class ExclusionRecommendation {
  final String? excludeProduct;
  final String reason;
  final double monthlySavings;
  final double annualSavings;

  const ExclusionRecommendation({
    this.excludeProduct,
    required this.reason,
    required this.monthlySavings,
    required this.annualSavings,
  });

  factory ExclusionRecommendation.fromJson(Map<String, dynamic> json) {
    return ExclusionRecommendation(
      excludeProduct: json['exclude_product'] as String?,
      reason: json['reason'] as String? ?? '',
      monthlySavings: (json['monthly_savings'] as num?)?.toDouble() ?? 0.0,
      annualSavings: (json['annual_savings'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
        if (excludeProduct != null) 'exclude_product': excludeProduct,
        'reason': reason,
        'monthly_savings': monthlySavings,
        'annual_savings': annualSavings,
      };
}
