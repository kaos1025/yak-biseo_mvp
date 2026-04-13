class SavedProduct {
  final String name;
  final List<String> ingredients;
  final double? monthlyCost;

  const SavedProduct({
    required this.name,
    required this.ingredients,
    this.monthlyCost,
  });

  factory SavedProduct.fromJson(Map<String, dynamic> json) {
    return SavedProduct(
      name: json['name'] as String,
      ingredients: (json['ingredients'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      monthlyCost: (json['monthlyCost'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'ingredients': ingredients,
      'monthlyCost': monthlyCost,
    };
  }
}
