import 'ingredient.dart';
import '../core/utils/primary_ingredient_extractor.dart';

/// 제품 + 성분 목록 묶음 (중복/UL 분석 엔진 입력 모델)
class ProductWithIngredients {
  /// 제품 이름
  final String productName;

  /// 제품 ID (NIH: dsld_id / KR: PRDLST_REPORT_NO)
  final String productId;

  /// 귀속된 성분 목록
  final List<Ingredient> ingredients;

  /// 예상 가격 (절약금액 계산용)
  final int price;

  /// 일일 섭취 횟수/량 (기본값 1.0)
  /// dosage 파싱 결과가 없으면 1.0으로 가정
  final double servingsPerDay;

  const ProductWithIngredients({
    required this.productName,
    required this.productId,
    required this.ingredients,
    this.price = 0,
    this.servingsPerDay = 1.0,
  });

  /// 이 제품의 모든 ingredientGroup 집합
  Set<String> get ingredientGroups =>
      ingredients.map((i) => i.ingredientGroup).toSet();

  /// 이 제품의 주성분 ingredientGroup 집합 (중복 비교 대상)
  /// 제품명 키워드 + 함량 기준으로 주성분 판단
  Set<String> get primaryIngredientGroups =>
      PrimaryIngredientExtractor.extractPrimaryGroups(productName, ingredients);
}
