abstract class BasePill {
  final String id;
  final String name;
  final String brand;
  final String imageUrl;
  final String dailyDosage;

  const BasePill({
    required this.id,
    required this.name,
    required this.brand,
    required this.imageUrl,
    required this.dailyDosage,
  });
}

class KoreanPill extends BasePill {
  final String category;
  final String ingredients;

  const KoreanPill({
    required super.id,
    required super.name,
    required super.brand,
    required super.imageUrl,
    required super.dailyDosage,
    required this.category,
    required this.ingredients,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'brand': brand,
      'imageUrl': imageUrl,
      'dailyDosage': dailyDosage,
      'category': category,
      'ingredients': ingredients,
    };
  }

  factory KoreanPill.fromJson(Map<String, dynamic> json) {
    return KoreanPill(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '이름 없음',
      brand: json['brand'] as String? ?? '브랜드 정보 없음',
      imageUrl: json['imageUrl'] as String? ?? '',
      dailyDosage: json['dailyDosage'] as String? ?? '섭취방법 정보 없음',
      category: json['category'] as String? ?? '건강기능식품',
      ingredients: json['ingredients'] as String? ?? '',
    );
  }
}

class AmericanPill extends BasePill {
  final String upcCode;
  final String servingSize;
  final Map<String, dynamic> supplementFacts;
  final String disclaimer;

  const AmericanPill({
    required super.id,
    required super.name,
    required super.brand,
    required super.imageUrl,
    required super.dailyDosage,
    required this.upcCode,
    required this.servingSize,
    required this.supplementFacts,
    required this.disclaimer,
  });

  factory AmericanPill.fromJson(Map<String, dynamic> json) {
    return AmericanPill(
      id: json['id'] as String,
      name: json['name'] as String,
      brand: json['brand'] as String,
      imageUrl: json['imageUrl'] as String,
      dailyDosage: json['dailyDosage'] as String,
      upcCode: json['upcCode'] as String,
      servingSize: json['servingSize'] as String,
      supplementFacts: json['supplementFacts'] as Map<String, dynamic>,
      disclaimer: json['disclaimer'] as String,
    );
  }
}
