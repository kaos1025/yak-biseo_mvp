/// 컨설턴트 분석 결과를 담는 모델
class ConsultantResult {
  final List<ExcludedProduct> excludedProducts;
  final int totalMonthlySavings;
  final String reportMarkdown;

  ConsultantResult({
    required this.excludedProducts,
    required this.totalMonthlySavings,
    required this.reportMarkdown,
  });

  factory ConsultantResult.fromJson(Map<String, dynamic> json) {
    return ConsultantResult(
      excludedProducts: (json['excluded_products'] as List<dynamic>?)
              ?.map((e) => ExcludedProduct.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      totalMonthlySavings:
          (json['total_monthly_savings'] as num?)?.round() ?? 0,
      reportMarkdown: json['report_markdown'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'excluded_products': excludedProducts.map((e) => e.toJson()).toList(),
      'total_monthly_savings': totalMonthlySavings,
      'report_markdown': reportMarkdown,
    };
  }

  /// 제외 권장 제품이 있는지 여부
  bool get hasExclusions => excludedProducts.isNotEmpty;

  /// 연간 절약 금액 (월간 × 12)
  int get totalYearlySavings => totalMonthlySavings * 12;
}

/// 제외 권장 제품 정보
class ExcludedProduct {
  final String name;
  final String reason;
  final int monthlySavings;

  ExcludedProduct({
    required this.name,
    required this.reason,
    required this.monthlySavings,
  });

  factory ExcludedProduct.fromJson(Map<String, dynamic> json) {
    return ExcludedProduct(
      name: json['name'] as String? ?? '',
      reason: json['reason'] as String? ?? '',
      monthlySavings: (json['monthly_savings'] as num?)?.round() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'reason': reason,
      'monthly_savings': monthlySavings,
    };
  }

  /// 연간 절약 금액
  int get yearlySavings => monthlySavings * 12;
}
