class AnalyzeResult {
  final List<Product> products;
  final String confidence; // 'high' | 'medium' | 'low'
  final String? notes;
  final GeminiUsageMetadata? usageMetadata;

  AnalyzeResult({
    required this.products,
    required this.confidence,
    this.notes,
    this.usageMetadata,
  });

  factory AnalyzeResult.fromJson(Map<String, dynamic> json) {
    return AnalyzeResult(
      products: (json['products'] as List<dynamic>?)
              ?.map((e) => Product.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      confidence: json['confidence'] as String? ?? 'low',
      notes: json['notes'] as String?,
      // usageMetadata는 서비스 계층에서 주입될 예정이므로 JSON 파싱에서는 제외하거나
      // API 응답 구조에 따라 처리. 여기서는 서비스에서 주입한다고 가정.
    );
  }

  AnalyzeResult copyWith({GeminiUsageMetadata? usageMetadata}) {
    return AnalyzeResult(
      products: products,
      confidence: confidence,
      notes: notes,
      usageMetadata: usageMetadata ?? this.usageMetadata,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'products': products.map((e) => e.toJson()).toList(),
      'confidence': confidence,
      'notes': notes,
    };
  }
}

class Product {
  final String brand;
  final String name;
  final String? nameKo;
  final String servingSize;
  final String? efficacy; // 제품 주요 효능
  final List<Ingredient> ingredients;
  final int? estimatedPrice; // Estimated full price (KRW)
  final int? monthlyPrice; // Estimated monthly cost
  final int? supplyPeriodMonths; // How many months it lasts

  Product({
    required this.brand,
    required this.name,
    this.nameKo,
    required this.servingSize,
    this.efficacy,
    required this.ingredients,
    this.estimatedPrice,
    this.monthlyPrice,
    this.supplyPeriodMonths,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      brand: json['brand'] as String? ?? '',
      name: json['name'] as String? ?? '',
      nameKo: json['name_ko'] as String?,
      servingSize: json['serving_size'] as String? ?? '',
      efficacy: json['efficacy'] as String?,
      ingredients: (json['ingredients'] as List<dynamic>?)
              ?.map((e) => Ingredient.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      estimatedPrice: (json['estimated_price'] as num?)?.round(),
      monthlyPrice: (json['monthly_price'] as num?)?.round(),
      supplyPeriodMonths: (json['supply_period_months'] as num?)?.round(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'brand': brand,
      'name': name,
      'name_ko': nameKo,
      'serving_size': servingSize,
      'efficacy': efficacy,
      'ingredients': ingredients.map((e) => e.toJson()).toList(),
      'estimated_price': estimatedPrice,
      'monthly_price': monthlyPrice,
      'supply_period_months': supplyPeriodMonths,
    };
  }
}

class Ingredient {
  final String name;
  final String? nameKo;
  final double amount;
  final String unit;
  final double? dailyValuePercent;
  final String? efficacy; // 성분 효능

  Ingredient({
    required this.name,
    this.nameKo,
    required this.amount,
    required this.unit,
    this.dailyValuePercent,
    this.efficacy,
  });

  factory Ingredient.fromJson(Map<String, dynamic> json) {
    return Ingredient(
      name: json['name'] as String? ?? '',
      nameKo: json['name_ko'] as String?,
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      unit: json['unit'] as String? ?? '',
      dailyValuePercent: (json['daily_value_percent'] as num?)?.toDouble(),
      efficacy: json['efficacy'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'name_ko': nameKo,
      'amount': amount,
      'unit': unit,
      'daily_value_percent': dailyValuePercent,
      'efficacy': efficacy,
    };
  }
}

class GeminiUsageMetadata {
  final int promptTokenCount;
  final int candidatesTokenCount;
  final int totalTokenCount;

  GeminiUsageMetadata({
    this.promptTokenCount = 0,
    this.candidatesTokenCount = 0,
    this.totalTokenCount = 0,
  });

  // $0.10 / 1M input, $0.40 / 1M output (Example pricing for Gemini 1.5/2.0 Flash approx)
  // Note: Pricing may vary. Using user provided reference or standard placeholder.
  // User spec: $0.10 / 1M input, $0.40 / 1M output
  double get estimatedCost {
    const inputPricePerM = 0.10;
    const outputPricePerM = 0.40;

    final inputCost = (promptTokenCount / 1000000) * inputPricePerM;
    final outputCost = (candidatesTokenCount / 1000000) * outputPricePerM;

    return inputCost + outputCost;
  }
}
