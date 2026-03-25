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
  final ExclusionRecommendation? exclusionRecommendation;
  final String overallStatus; // "perfect" | "caution" | "warning"
  final String statusReason;

  const OnestopAnalysisResult({
    required this.products,
    required this.overlaps,
    required this.functionalOverlaps,
    required this.safetyAlerts,
    required this.singleProductUlExcess,
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
      exclusionRecommendation: json['exclusion_recommendation'] != null
          ? ExclusionRecommendation.fromJson(
              json['exclusion_recommendation'] as Map<String, dynamic>)
          : null,
      overallStatus: json['overall_status'] as String? ?? 'caution',
      statusReason: json['status_reason'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'products': products.map((e) => e.toJson()).toList(),
      'overlaps': overlaps.map((e) => e.toJson()).toList(),
      'functional_overlaps': functionalOverlaps.map((e) => e.toJson()).toList(),
      'safety_alerts': safetyAlerts.map((e) => e.toJson()).toList(),
      'single_product_ul_excess':
          singleProductUlExcess.map((e) => e.toJson()).toList(),
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
              ))
          .toList(),
      duplicates: overlaps
          .map((o) => DuplicateIngredient(
                ingredient: o.ingredient,
                products: o.sources.map((s) => s.product).toList(),
                totalAmount: '${o.totalAmount}${o.unit}',
                dailyLimit:
                    o.ul != null ? '${o.ul}${o.ulUnit ?? o.unit}' : null,
                riskLevel: o.severity,
                advice: o.exceedsUl
                    ? '합산 섭취량이 일일 상한(UL)을 초과합니다.'
                    : '중복되지만 안전 범위 내입니다.',
              ))
          .toList(),
      overallRisk: overallRisk,
      summary: statusReason,
      recommendations: _buildRecommendations(),
      monthlySavings:
          ((exclusionRecommendation?.monthlySavings ?? 0) * 1400).round(),
      yearlySavings:
          ((exclusionRecommendation?.annualSavings ?? 0) * 1400).round(),
      excludedProduct: exclusionRecommendation?.excludeProduct,
      functionalOverlaps: functionalOverlaps,
      safetyAlerts: safetyAlerts,
      singleProductUlExcess: singleProductUlExcess,
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
