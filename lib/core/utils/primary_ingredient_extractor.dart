import '../../models/ingredient.dart';

/// 주성분 추출 유틸리티
///
/// 제품명과 성분 함량을 분석하여 해당 제품의 "주성분"을 판별한다.
/// 주성분만 중복 비교 대상이 되고, 부성분(소량 첨가)은 제외된다.
class PrimaryIngredientExtractor {
  /// 주성분 판단을 위한 최소 함량 기준 (mg)
  static const double _minAmountMg = 100.0;

  /// 주성분 판단을 위한 최소 함량 기준 (mcg)
  static const double _minAmountMcg = 100.0;

  /// 주성분 판단을 위한 최소 함량 기준 (IU)
  static const double _minAmountIu = 400.0;

  /// 제품명 → ingredientGroup 키워드 매핑
  static const Map<String, String> _nameKeywords = {
    // 미네랄
    '마그네슘': 'Magnesium',
    '칼슘': 'Calcium',
    '아연': 'Zinc',
    '철분': 'Iron',
    '셀레늄': 'Selenium',
    '크롬': 'Chromium',

    // 비타민
    '비타민a': 'Vitamin A',
    '비타민b': 'B Vitamins',
    '비타민c': 'Vitamin C',
    '비타민d': 'Vitamin D',
    '비타민e': 'Vitamin E',
    '비타민k': 'Vitamin K',
    '엽산': 'Folate',

    // 특수 성분
    '오메가': 'Omega-3',
    '루테인': 'Lutein',
    '코엔자임': 'CoQ10',
    '코큐텐': 'CoQ10',
    '프로바이오틱': 'Probiotics',
    '유산균': 'Probiotics',
    '콜라겐': 'Collagen',
    '글루코사민': 'Glucosamine',
    '밀크씨슬': 'Milk Thistle',

    // 아미노산
    '아르기닌': 'L-Arginine',
    '타우린': 'Taurine',
    '글루타민': 'Glutamine',

    // 추출물
    '쏘팔메토': 'Saw Palmetto',
    '소팔메토': 'Saw Palmetto',
    '은행잎': 'Ginkgo Biloba',
    '녹차': 'Green Tea Extract',
    '홍삼': 'Red Ginseng',
    '인삼': 'Ginseng',
  };

  /// 제품명에서 주성분 키워드 추출
  ///
  /// [productName] 제품명 (예: "칼슘 & 마그네슘")
  /// 반환: 추출된 ingredientGroup Set (예: {"Calcium", "Magnesium"})
  static Set<String> extractFromProductName(String productName) {
    final result = <String>{};
    final lowerName = productName.toLowerCase();

    for (final entry in _nameKeywords.entries) {
      if (lowerName.contains(entry.key)) {
        result.add(entry.value);
      }
    }

    return result;
  }

  /// 함량 기준으로 주성분 여부 판단
  ///
  /// [ingredient] 성분 정보
  /// 반환: true = 주성분, false = 부성분
  static bool isPrimaryByAmount(Ingredient ingredient) {
    final amount = ingredient.amount;
    final unit = ingredient.unit?.toLowerCase() ?? '';

    if (amount == null || amount <= 0) {
      // 함량 정보 없으면 일단 주성분으로 간주 (안전한 판단)
      return true;
    }

    // 단위별 최소 기준
    if (unit.contains('mg')) {
      return amount >= _minAmountMg;
    } else if (unit.contains('mcg') ||
        unit.contains('㎍') ||
        unit.contains('μg')) {
      return amount >= _minAmountMcg;
    } else if (unit.contains('iu')) {
      return amount >= _minAmountIu;
    }

    // 알 수 없는 단위는 주성분으로 간주
    return true;
  }

  /// 제품의 주성분 그룹 추출 (하이브리드 방식)
  ///
  /// 판단 로직:
  /// 1. 제품명에 성분 키워드가 있으면 → 해당 성분만 주성분 (함량 무시)
  /// 2. 제품명에 키워드가 없으면 → 함량 기준으로 주성분 판단
  ///
  /// 예: "쏘팔메토 추출물" → Saw Palmetto만 주성분 (마그네슘은 부성분)
  /// 예: "종합비타민" → 함량 기준으로 판단
  ///
  /// [productName] 제품명
  /// [ingredients] 성분 목록
  /// 반환: 주성분 ingredientGroup Set
  static Set<String> extractPrimaryGroups(
    String productName,
    List<Ingredient> ingredients,
  ) {
    final nameBasedPrimary = extractFromProductName(productName);

    // 제품명에서 주성분이 추출되면 → 해당 성분만 주성분
    if (nameBasedPrimary.isNotEmpty) {
      // 성분 목록에 있는 것만 필터링
      final actualGroups = ingredients.map((i) => i.ingredientGroup).toSet();
      final intersection = nameBasedPrimary.intersection(actualGroups);

      // 교집합이 있으면 그것만 반환, 없으면 제품명 기반 그대로 반환
      return intersection.isNotEmpty ? intersection : nameBasedPrimary;
    }

    // 제품명에 키워드가 없으면 → 함량 기준으로 판단
    final result = <String>{};
    for (final ing in ingredients) {
      final group = ing.ingredientGroup;
      if (group.isEmpty) continue;

      if (isPrimaryByAmount(ing)) {
        result.add(group);
      }
    }

    // 결과가 비어있으면 모든 성분을 주성분으로 간주 (fallback)
    if (result.isEmpty && ingredients.isNotEmpty) {
      for (final ing in ingredients) {
        if (ing.ingredientGroup.isNotEmpty) {
          result.add(ing.ingredientGroup);
        }
      }
    }

    return result;
  }
}
