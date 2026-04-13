import 'package:myapp/models/saved_product.dart';

class SavedStack {
  final List<SavedProduct> products;
  final DateTime lastAnalyzed;
  final String lastAnalysisJson;

  const SavedStack({
    required this.products,
    required this.lastAnalyzed,
    required this.lastAnalysisJson,
  });

  factory SavedStack.fromJson(Map<String, dynamic> json) {
    return SavedStack(
      products: (json['products'] as List<dynamic>)
          .map((e) => SavedProduct.fromJson(e as Map<String, dynamic>))
          .toList(),
      lastAnalyzed: DateTime.parse(json['lastAnalyzed'] as String),
      lastAnalysisJson: json['lastAnalysisJson'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'products': products.map((p) => p.toJson()).toList(),
      'lastAnalyzed': lastAnalyzed.toIso8601String(),
      'lastAnalysisJson': lastAnalysisJson,
    };
  }
}
