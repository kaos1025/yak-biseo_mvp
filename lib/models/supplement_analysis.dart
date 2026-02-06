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
}

class Product {
  final String brand;
  final String name;
  final String? nameKo;
  final String servingSize;
  final List<Ingredient> ingredients;

  Product({
    required this.brand,
    required this.name,
    this.nameKo,
    required this.servingSize,
    required this.ingredients,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      brand: json['brand'] as String? ?? '',
      name: json['name'] as String? ?? '',
      nameKo: json['name_ko'] as String?,
      servingSize: json['serving_size'] as String? ?? '',
      ingredients: (json['ingredients'] as List<dynamic>?)
              ?.map((e) => Ingredient.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class Ingredient {
  final String name;
  final String? nameKo;
  final double amount;
  final String unit;
  final double? dailyValuePercent;

  Ingredient({
    required this.name,
    this.nameKo,
    required this.amount,
    required this.unit,
    this.dailyValuePercent,
  });

  factory Ingredient.fromJson(Map<String, dynamic> json) {
    return Ingredient(
      name: json['name'] as String? ?? '',
      nameKo: json['name_ko'] as String?,
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      unit: json['unit'] as String? ?? '',
      dailyValuePercent: (json['daily_value_percent'] as num?)?.toDouble(),
    );
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
