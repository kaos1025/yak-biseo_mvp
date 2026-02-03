import 'ingredient_category.dart';

/// 통합 성분 데이터 모델
///
/// NIH DSLD API와 식품안전나라 API의 응답을 공통 포맷으로 변환한다.
/// 규칙 엔진은 [ingredientGroup] 필드를 기준으로 중복을 판단한다.
class Ingredient {
  /// 성분명 (NIH: "Vitamin D" / KR: "비타민A")
  final String name;

  /// 대분류 (vitamin, mineral, carotenoid, etc.)
  final String category;

  /// 세분류 — 규칙 엔진의 핵심 비교 키
  /// NIH: ingredientGroup 필드 직접 사용 (예: "Vitamin D", "Calcium")
  /// KR: 한글 매핑 테이블로 변환 (예: "비타민A" → "Vitamin A")
  final String ingredientGroup;

  /// 함량 수치 (예: 600, 4.3, 20)
  final double? amount;

  /// 단위 (mg, ㎍RAE, mg α-TE, IU 등)
  final String? unit;

  /// 부가 정보 (NIH: notes 필드 / KR: null)
  final String? notes;

  /// 데이터 출처: "nih_dsld" | "kr_food_safety"
  final String source;

  /// 원본 제품 ID (NIH: dsld_id / KR: PRDLST_REPORT_NO)
  final String? sourceProductId;

  const Ingredient({
    required this.name,
    required this.category,
    required this.ingredientGroup,
    this.amount,
    this.unit,
    this.notes,
    required this.source,
    this.sourceProductId,
  });

  /// NIH DSLD API ingredientRow로부터 생성
  ///
  /// [ingredientRow] API 응답의 ingredientRows[] 요소
  /// [productId] 원본 제품의 dsld_id
  factory Ingredient.fromNihDsld(
    Map<String, dynamic> ingredientRow, {
    String? productId,
  }) {
    // quantity 배열에서 첫 번째 요소의 quantity와 unit 추출
    double? amount;
    String? unit;

    final quantityList = ingredientRow['quantity'] as List<dynamic>?;
    if (quantityList != null && quantityList.isNotEmpty) {
      final firstQuantity = quantityList[0] as Map<String, dynamic>;
      amount = (firstQuantity['quantity'] as num?)?.toDouble();
      unit = firstQuantity['unit'] as String?;
    }

    return Ingredient(
      name: ingredientRow['name'] as String? ?? '',
      category: ingredientRow['category'] as String? ?? 'unknown',
      ingredientGroup: ingredientRow['ingredientGroup'] as String? ?? '',
      amount: amount,
      unit: unit,
      notes: ingredientRow['notes'] as String?,
      source: 'nih_dsld',
      sourceProductId: productId,
    );
  }

  /// 식품안전나라 STDR_STND 파싱 결과로부터 생성
  ///
  /// [parsedName] STDR_STND에서 파싱된 성분명 (예: "비타민A")
  /// [parsedAmount] STDR_STND에서 파싱된 함량
  /// [parsedUnit] STDR_STND에서 파싱된 단위
  /// [productId] 원본 제품의 PRDLST_REPORT_NO
  factory Ingredient.fromKrFoodSafety({
    required String parsedName,
    double? parsedAmount,
    String? parsedUnit,
    String? productId,
  }) {
    // 한글 매핑 테이블 조회
    final mapping = IngredientCategory.fromKoreanName(parsedName);

    return Ingredient(
      name: parsedName,
      category: mapping.category,
      ingredientGroup: mapping.group,
      amount: parsedAmount,
      unit: parsedUnit,
      notes: null,
      source: 'kr_food_safety',
      sourceProductId: productId,
    );
  }

  /// JSON 직렬화 (캐시 저장용)
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'category': category,
      'ingredientGroup': ingredientGroup,
      'amount': amount,
      'unit': unit,
      'notes': notes,
      'source': source,
      'sourceProductId': sourceProductId,
    };
  }

  /// JSON 역직렬화 (캐시 로드용)
  factory Ingredient.fromJson(Map<String, dynamic> json) {
    return Ingredient(
      name: json['name'] as String? ?? '',
      category: json['category'] as String? ?? 'unknown',
      ingredientGroup: json['ingredientGroup'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble(),
      unit: json['unit'] as String?,
      notes: json['notes'] as String?,
      source: json['source'] as String? ?? 'unknown',
      sourceProductId: json['sourceProductId'] as String?,
    );
  }

  @override
  String toString() {
    final amountStr = amount != null ? '$amount $unit' : 'N/A';
    return 'Ingredient($name, $ingredientGroup, $amountStr)';
  }
}
