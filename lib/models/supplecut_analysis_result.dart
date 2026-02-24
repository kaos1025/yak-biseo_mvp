/// SuppleCut Gemini 분석 응답 모델
///
/// 로컬 DB 제품 + Fallback 제품 혼합 분석 결과를 담는다.
class SuppleCutAnalysisResult {
  /// 분석된 제품 목록
  final List<AnalyzedProduct> products;

  /// 중복 성분 목록
  final List<DuplicateIngredient> duplicates;

  /// 전체 위험도: "safe" | "warning" | "danger"
  final String overallRisk;

  /// 전체 요약 (한글)
  final String summary;

  /// 권장사항 목록
  final List<String> recommendations;

  /// 면책 조항 (Fallback 제품 포함 시)
  final String? disclaimer;

  /// 월간 절감액 (KRW) — 제외 권장 제품의 월 환산 가격
  final int monthlySavings;

  /// 연간 절감액 (KRW)
  final int yearlySavings;

  /// 제외 권장 제품명
  final String? excludedProduct;

  const SuppleCutAnalysisResult({
    required this.products,
    required this.duplicates,
    required this.overallRisk,
    required this.summary,
    required this.recommendations,
    this.disclaimer,
    this.monthlySavings = 0,
    this.yearlySavings = 0,
    this.excludedProduct,
  });

  /// Gemini JSON 응답에서 생성
  factory SuppleCutAnalysisResult.fromJson(Map<String, dynamic> json) {
    return SuppleCutAnalysisResult(
      products: (json['products'] as List<dynamic>?)
              ?.map((e) => AnalyzedProduct.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      duplicates: (json['duplicates'] as List<dynamic>?)
              ?.map((e) =>
                  DuplicateIngredient.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      overallRisk: json['overallRisk'] as String? ?? 'safe',
      summary: json['summary'] as String? ?? '',
      recommendations: (json['recommendations'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      disclaimer: json['disclaimer'] as String?,
      monthlySavings: (json['monthlySavings'] as num?)?.round() ?? 0,
      yearlySavings: (json['yearlySavings'] as num?)?.round() ?? 0,
      excludedProduct: json['excludedProduct'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'products': products.map((e) => e.toJson()).toList(),
      'duplicates': duplicates.map((e) => e.toJson()).toList(),
      'overallRisk': overallRisk,
      'summary': summary,
      'recommendations': recommendations,
      if (disclaimer != null) 'disclaimer': disclaimer,
      'monthlySavings': monthlySavings,
      'yearlySavings': yearlySavings,
      if (excludedProduct != null) 'excludedProduct': excludedProduct,
    };
  }

  /// 중복 성분이 있는지 여부
  bool get hasDuplicates => duplicates.isNotEmpty;

  /// Fallback 제품이 포함되어 있는지 여부
  bool get hasFallbackProducts =>
      products.any((p) => p.source == 'ai_estimated');

  /// 절감액이 있는지 여부
  bool get hasSavings => monthlySavings > 0;

  @override
  String toString() {
    return 'SuppleCutAnalysisResult('
        '${products.length} products, '
        '${duplicates.length} duplicates, '
        'risk: $overallRisk, '
        'savings: $monthlySavings/월)';
  }
}

/// 분석된 개별 제품 정보
class AnalyzedProduct {
  /// 제품명
  final String name;

  /// 데이터 소스: "local_db" | "ai_estimated"
  final String source;

  /// 성분 목록
  final List<AnalyzedIngredient> ingredients;

  /// AI 추정 신뢰도 (ai_estimated일 때만): "high" | "medium" | "low"
  final String? confidence;

  /// 추가 참고사항
  final String? note;

  /// AI 추정 월 환산 가격 (KRW)
  final int estimatedMonthlyPrice;

  const AnalyzedProduct({
    required this.name,
    required this.source,
    required this.ingredients,
    this.confidence,
    this.note,
    this.estimatedMonthlyPrice = 0,
  });

  factory AnalyzedProduct.fromJson(Map<String, dynamic> json) {
    return AnalyzedProduct(
      name: json['name'] as String? ?? '',
      source: json['source'] as String? ?? 'local_db',
      ingredients: (json['ingredients'] as List<dynamic>?)
              ?.map(
                  (e) => AnalyzedIngredient.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      confidence: json['confidence'] as String?,
      note: json['note'] as String?,
      estimatedMonthlyPrice:
          (json['estimatedMonthlyPrice'] as num?)?.round() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'source': source,
      'ingredients': ingredients.map((e) => e.toJson()).toList(),
      if (confidence != null) 'confidence': confidence,
      if (note != null) 'note': note,
      'estimatedMonthlyPrice': estimatedMonthlyPrice,
    };
  }

  /// AI 추정 제품인지 여부
  bool get isEstimated => source == 'ai_estimated';

  @override
  String toString() => 'AnalyzedProduct($name, source: $source)';
}

/// 분석된 개별 성분 정보
class AnalyzedIngredient {
  /// 성분명
  final String name;

  /// 함량
  final double amount;

  /// 단위
  final String unit;

  /// 일일 권장량 대비 %
  final double? dailyValue;

  const AnalyzedIngredient({
    required this.name,
    required this.amount,
    required this.unit,
    this.dailyValue,
  });

  factory AnalyzedIngredient.fromJson(Map<String, dynamic> json) {
    return AnalyzedIngredient(
      name: json['name'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      unit: json['unit'] as String? ?? '',
      dailyValue: (json['dailyValue'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'amount': amount,
      'unit': unit,
      if (dailyValue != null) 'dailyValue': dailyValue,
    };
  }
}

/// 중복 성분 분석 결과
class DuplicateIngredient {
  /// 성분명
  final String ingredient;

  /// 해당 성분을 포함하는 제품명 목록
  final List<String> products;

  /// 합산 함량 문자열 (예: "75mcg")
  final String totalAmount;

  /// 일일 상한 섭취량 (문자열, 예: "100mcg")
  final String? dailyLimit;

  /// 위험 수준: "safe" | "warning" | "danger"
  final String riskLevel;

  /// 조언 (한글)
  final String advice;

  const DuplicateIngredient({
    required this.ingredient,
    required this.products,
    required this.totalAmount,
    this.dailyLimit,
    required this.riskLevel,
    required this.advice,
  });

  factory DuplicateIngredient.fromJson(Map<String, dynamic> json) {
    return DuplicateIngredient(
      ingredient: json['ingredient'] as String? ?? '',
      products: (json['products'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      totalAmount: json['totalAmount'] as String? ?? '',
      dailyLimit: json['dailyLimit'] as String?,
      riskLevel: json['riskLevel'] as String? ?? 'safe',
      advice: json['advice'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ingredient': ingredient,
      'products': products,
      'totalAmount': totalAmount,
      if (dailyLimit != null) 'dailyLimit': dailyLimit,
      'riskLevel': riskLevel,
      'advice': advice,
    };
  }

  @override
  String toString() => 'DuplicateIngredient($ingredient, risk: $riskLevel)';
}
