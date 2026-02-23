class UnifiedAnalysisResult {
  final List<UnifiedProduct> products;
  final UnifiedAnalysis analysis;
  final List<UnifiedProductUI> productsUI;
  final String id;
  final String? premiumReport;

  UnifiedAnalysisResult({
    required this.id,
    required this.products,
    required this.analysis,
    required this.productsUI,
    this.premiumReport,
  });

  factory UnifiedAnalysisResult.fromJson(Map<String, dynamic> json) {
    return UnifiedAnalysisResult(
      id: json['id'] as String? ??
          DateTime.now()
              .millisecondsSinceEpoch
              .toString(), // Generate simplified ID if missing
      products: (json['products'] as List<dynamic>?)
              ?.map((e) => UnifiedProduct.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      analysis: UnifiedAnalysis.fromJson(
          json['analysis'] as Map<String, dynamic>? ?? {}),
      productsUI: (json['products_ui'] as List<dynamic>?)
              ?.map((e) => UnifiedProductUI.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      premiumReport: json['premium_report'] as String?,
    );
  }
}

class UnifiedProduct {
  final String brand;
  final String name;
  final List<UnifiedIngredient> ingredients;
  final int estimatedMonthlyPrice;
  final int originalPrice;
  final num durationMonths;
  final String? dosage; // Added dosage

  UnifiedProduct({
    required this.brand,
    required this.name,
    required this.ingredients,
    required this.estimatedMonthlyPrice,
    this.originalPrice = 0,
    this.durationMonths = 1,
    this.dosage,
  });

  factory UnifiedProduct.fromJson(Map<String, dynamic> json) {
    return UnifiedProduct(
      brand: json['brand'] as String? ?? '',
      name: json['name'] as String? ?? '',
      ingredients: (json['ingredients'] as List<dynamic>?)
              ?.map(
                  (e) => UnifiedIngredient.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      estimatedMonthlyPrice:
          (json['estimated_monthly_price'] as num?)?.round() ?? 0,
      originalPrice: _parseInt(json['original_price']) > 0
          ? _parseInt(json['original_price'])
          : (_parseInt(json['estimated_monthly_price']) > 0
              ? _parseInt(json['estimated_monthly_price']) *
                  (_parseNum(json['duration_months'])?.toInt() ?? 1)
              : 30000), // Default fallback if all fail
      durationMonths: _parseNum(json['duration_months']) ?? 1,
      dosage: json['dosage'] as String?,
    );
  }

  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.round();
    if (value is String) {
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
}

class UnifiedIngredient {
  final String name;
  final double amount;
  final String unit;

  UnifiedIngredient({
    required this.name,
    required this.amount,
    required this.unit,
  });

  factory UnifiedIngredient.fromJson(Map<String, dynamic> json) {
    return UnifiedIngredient(
      name: json['name'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      unit: json['unit'] as String? ?? '',
    );
  }
}

class UnifiedAnalysis {
  final String bannerType;
  final bool hasDuplicate;
  final bool hasOverLimit;
  final String? excludedProduct;
  final int monthlySavings;
  final int yearlySavings;
  final String? exclusionReason;
  final List<String> duplicateIngredients;
  final List<UnifiedOverLimitIngredient> overLimitIngredients;

  UnifiedAnalysis({
    required this.bannerType,
    required this.hasDuplicate,
    required this.hasOverLimit,
    this.excludedProduct,
    required this.monthlySavings,
    required this.yearlySavings,
    this.exclusionReason,
    required this.duplicateIngredients,
    required this.overLimitIngredients,
  });

  factory UnifiedAnalysis.fromJson(Map<String, dynamic> json) {
    return UnifiedAnalysis(
      bannerType: json['banner_type'] as String? ?? 'good',
      hasDuplicate: json['has_duplicate'] as bool? ?? false,
      hasOverLimit: json['has_over_limit'] as bool? ?? false,
      excludedProduct: json['excluded_product'] as String?,
      monthlySavings: (json['monthly_savings'] as num?)?.round() ?? 0,
      yearlySavings: (json['yearly_savings'] as num?)?.round() ?? 0,
      exclusionReason: json['exclusion_reason'] as String?,
      duplicateIngredients: (json['duplicate_ingredients'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      overLimitIngredients: (json['over_limit_ingredients'] as List<dynamic>?)
              ?.map((e) => UnifiedOverLimitIngredient.fromJson(
                  e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class UnifiedOverLimitIngredient {
  final String name;
  final double total;
  final double limit;
  final String unit;

  UnifiedOverLimitIngredient({
    required this.name,
    required this.total,
    required this.limit,
    required this.unit,
  });

  factory UnifiedOverLimitIngredient.fromJson(Map<String, dynamic> json) {
    return UnifiedOverLimitIngredient(
      name: json['name'] as String? ?? '',
      total: (json['total'] as num?)?.toDouble() ?? 0.0,
      limit: (json['limit'] as num?)?.toDouble() ?? 0.0,
      unit: json['unit'] as String? ?? '',
    );
  }
}

class UnifiedProductUI {
  final String name;
  final String brand;
  final String status; // 'danger' or 'safe'
  final String? tag;
  final int monthlyPrice;

  UnifiedProductUI({
    required this.name,
    required this.brand,
    required this.status,
    this.tag,
    required this.monthlyPrice,
  });

  factory UnifiedProductUI.fromJson(Map<String, dynamic> json) {
    return UnifiedProductUI(
      name: json['name'] as String? ?? '',
      brand: json['brand'] as String? ?? '',
      status: json['status'] as String? ?? 'safe',
      tag: (json['tag'] == 'null' || json['tag'] == null)
          ? null
          : json['tag'] as String?,
      monthlyPrice: (json['monthly_price'] as num?)?.round() ?? 0,
    );
  }
}
