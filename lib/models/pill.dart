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
}
