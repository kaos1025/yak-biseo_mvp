import 'package:cloud_firestore/cloud_firestore.dart';

import 'ingredient.dart';

/// 영양제 제품 데이터 모델
///
/// Firestore에 저장되는 제품 정보.
/// 제품명, 제조사, 성분 목록을 포함한다.
class SupplementProduct {
  /// 제품 고유 ID (PRDLST_REPORT_NO 또는 DSLD ID)
  final String id;

  /// 제품명
  final String name;

  /// 제조사/업체명
  final String brand;

  /// 데이터 출처: "kr_food_safety" | "nih_dsld"
  final String source;

  /// 성분 목록
  final List<Ingredient> ingredients;

  /// 생성 시각
  final DateTime createdAt;

  /// 수정 시각 (선택)
  final DateTime? updatedAt;

  const SupplementProduct({
    required this.id,
    required this.name,
    required this.brand,
    required this.source,
    required this.ingredients,
    required this.createdAt,
    this.updatedAt,
  });

  /// Firestore 문서로 변환
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'name': name,
      'brand': brand,
      'source': source,
      'ingredients': ingredients.map((i) => i.toJson()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  /// Firestore DocumentSnapshot에서 생성
  factory SupplementProduct.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    final ingredientsList = (data['ingredients'] as List<dynamic>? ?? [])
        .map((i) => Ingredient.fromJson(i as Map<String, dynamic>))
        .toList();

    return SupplementProduct(
      id: data['id'] as String? ?? doc.id,
      name: data['name'] as String? ?? '',
      brand: data['brand'] as String? ?? '',
      source: data['source'] as String? ?? 'unknown',
      ingredients: ingredientsList,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  /// JSON에서 생성 (캐시/로컬 저장용)
  factory SupplementProduct.fromJson(Map<String, dynamic> json) {
    final ingredientsList = (json['ingredients'] as List<dynamic>? ?? [])
        .map((i) => Ingredient.fromJson(i as Map<String, dynamic>))
        .toList();

    return SupplementProduct(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      brand: json['brand'] as String? ?? '',
      source: json['source'] as String? ?? 'unknown',
      ingredients: ingredientsList,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  /// JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'brand': brand,
      'source': source,
      'ingredients': ingredients.map((i) => i.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  /// 복사 + 일부 필드 변경
  SupplementProduct copyWith({
    String? id,
    String? name,
    String? brand,
    String? source,
    List<Ingredient>? ingredients,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SupplementProduct(
      id: id ?? this.id,
      name: name ?? this.name,
      brand: brand ?? this.brand,
      source: source ?? this.source,
      ingredients: ingredients ?? this.ingredients,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'SupplementProduct($name, $brand, ${ingredients.length} ingredients)';
  }
}
