import 'package:cloud_firestore/cloud_firestore.dart';

import 'ingredient.dart';
import 'supplement_ingredient.dart';

/// 영양제 제품 데이터 모델
///
/// Firestore 또는 로컬 DB(assets JSON)에 저장되는 제품 정보.
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

  // ── 로컬 DB 전용 필드 (assets JSON에서 로드) ──

  /// 한글 제품명 (iHerb: 번역, Oliveyoung: 원본)
  final String? nameKo;

  /// 가격 (KRW)
  final double? price;

  /// 카테고리 목록
  final List<String> categories;

  /// 한글 카테고리 목록
  final List<String> categoriesKo;

  /// 1회 섭취량
  final String? servingSize;

  /// 평점
  final double? rating;

  /// 리뷰 수
  final int? reviewCount;

  /// 로컬 DB 성분 목록 (정규화된 이름 포함)
  final List<SupplementIngredient> localIngredients;

  const SupplementProduct({
    required this.id,
    required this.name,
    required this.brand,
    required this.source,
    required this.ingredients,
    required this.createdAt,
    this.updatedAt,
    this.nameKo,
    this.price,
    this.categories = const [],
    this.categoriesKo = const [],
    this.servingSize,
    this.rating,
    this.reviewCount,
    this.localIngredients = const [],
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

  /// 로컬 DB JSON에서 생성 (assets/db/supplements_db.json)
  factory SupplementProduct.fromLocalJson(Map<String, dynamic> json) {
    final ingredientsList = (json['ingredients'] as List<dynamic>? ?? [])
        .map((i) => SupplementIngredient.fromJson(i as Map<String, dynamic>))
        .toList();

    return SupplementProduct(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      brand: json['brand'] as String? ?? '',
      source: json['source'] as String? ?? 'unknown',
      ingredients: const [], // 로컬 DB는 localIngredients 사용
      createdAt: DateTime.now(),
      nameKo: json['name_ko'] as String?,
      price: (json['price'] as num?)?.toDouble(),
      categories: (json['categories'] as List<dynamic>? ?? [])
          .map((c) => c as String)
          .toList(),
      categoriesKo: (json['categories_ko'] as List<dynamic>? ?? [])
          .map((c) => c as String)
          .toList(),
      servingSize:
          json['servingSize'] as String? ?? json['servingSize_ko'] as String?,
      rating: (json['rating'] as num?)?.toDouble(),
      reviewCount: (json['reviewCount'] as num?)?.toInt(),
      localIngredients: ingredientsList,
    );
  }

  /// Gemini prompt용 제품 정보 문자열 변환
  ///
  /// 예:
  /// ```
  /// [Thorne, Basic Nutrients 2/Day] (Thorne)
  /// 성분: 비타민C: 250 mg (278% DV), 비타민D: 50 mcg (250% DV), ...
  /// ```
  String toGeminiContext() {
    final displayName = nameKo ?? name;
    final buffer = StringBuffer();
    buffer.writeln('[$displayName] ($brand)');

    if (localIngredients.isNotEmpty) {
      final ingredientStrs =
          localIngredients.map((i) => i.toGeminiContext()).toList();
      buffer.writeln('성분: ${ingredientStrs.join(', ')}');
    } else if (ingredients.isNotEmpty) {
      final ingredientStrs = ingredients.map((i) {
        final amountStr =
            i.amount != null ? '${i.amount} ${i.unit ?? ""}' : '함량 미표기';
        return '${i.name}: $amountStr';
      }).toList();
      buffer.writeln('성분: ${ingredientStrs.join(', ')}');
    }

    return buffer.toString();
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
    String? nameKo,
    double? price,
    List<String>? categories,
    List<String>? categoriesKo,
    String? servingSize,
    double? rating,
    int? reviewCount,
    List<SupplementIngredient>? localIngredients,
  }) {
    return SupplementProduct(
      id: id ?? this.id,
      name: name ?? this.name,
      brand: brand ?? this.brand,
      source: source ?? this.source,
      ingredients: ingredients ?? this.ingredients,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      nameKo: nameKo ?? this.nameKo,
      price: price ?? this.price,
      categories: categories ?? this.categories,
      categoriesKo: categoriesKo ?? this.categoriesKo,
      servingSize: servingSize ?? this.servingSize,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      localIngredients: localIngredients ?? this.localIngredients,
    );
  }

  @override
  String toString() {
    return 'SupplementProduct($name, $brand, ${ingredients.length} ingredients)';
  }
}
