/// 컨설턴트 분석 결과를 담는 모델
class ConsultantResult {
  final List<ExcludedProduct> excludedProducts;
  final int totalMonthlySavings;
  final String reportMarkdown;
  final String? exclusionReason;

  ConsultantResult({
    required this.excludedProducts,
    required this.totalMonthlySavings,
    required this.reportMarkdown,
    this.exclusionReason,
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
      exclusionReason: json['exclusion_reason'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'excluded_products': excludedProducts.map((e) => e.toJson()).toList(),
      'total_monthly_savings': totalMonthlySavings,
      'report_markdown': reportMarkdown,
      'exclusion_reason': exclusionReason,
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
  final int originalPrice;
  final num durationMonths;
  final int monthlySavings;

  ExcludedProduct({
    required this.name,
    required this.reason,
    required this.monthlySavings,
    this.originalPrice = 0,
    this.durationMonths = 1,
  });

  factory ExcludedProduct.fromJson(Map<String, dynamic> json) {
    return ExcludedProduct(
      name: json['name'] as String? ?? '',
      reason: json['reason'] as String? ?? '',
      monthlySavings: (json['monthly_savings'] as num?)?.round() ?? 0,
      originalPrice: _parseInt(json['original_price']),
      durationMonths: _parseNum(json['duration_months']) ?? 1,
    );
  }

  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.round();
    if (value is String) {
      // Remove non-digit characters except decimal point (though we want int)
      final cleanStr = value.replaceAll(RegExp(r'[^0-9]'), '');
      return int.tryParse(cleanStr) ?? 0;
    }
    return 0;
  }

  static num? _parseNum(dynamic value) {
    if (value is num) return value;
    if (value is String) {
      final cleanStr = value.replaceAll(RegExp(r'[^0-9.]'), '');
      return num.tryParse(cleanStr);
    }
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'reason': reason,
      'monthly_savings': monthlySavings,
      'original_price': originalPrice,
      'duration_months': durationMonths,
    };
  }

  /// 연간 절약 금액
  int get yearlySavings => monthlySavings * 12;
}
