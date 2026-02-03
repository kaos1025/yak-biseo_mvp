/// 성분 카테고리 표준 매핑
///
/// NIH DSLD API는 ingredientGroup 필드를 직접 제공하지만,
/// 식품안전나라 API는 한글 성분명을 영문 표준 그룹으로 매핑해야 한다.
///
/// 이 매핑 테이블을 통해 한국/미국 제품 간 교차 비교가 가능하다.
class IngredientCategory {
  /// 한글 성분명 → 표준 카테고리 매핑 테이블
  ///
  /// key: 한글 성분명 (STDR_STND에서 파싱된 이름)
  /// value: (category, group) 튜플
  ///   - category: 대분류 (vitamin, mineral, etc.)
  ///   - group: NIH ingredientGroup과 동일한 영문 표준
  static const Map<String, ({String category, String group})> koreanMapping = {
    // === 비타민 ===
    '비타민A': (category: 'vitamin', group: 'Vitamin A'),
    '비타민 A': (category: 'vitamin', group: 'Vitamin A'),
    '비타민B1': (category: 'vitamin', group: 'Vitamin B1 (Thiamin)'),
    '비타민 B1': (category: 'vitamin', group: 'Vitamin B1 (Thiamin)'),
    '티아민': (category: 'vitamin', group: 'Vitamin B1 (Thiamin)'),
    '비타민B2': (category: 'vitamin', group: 'Vitamin B2 (Riboflavin)'),
    '비타민 B2': (category: 'vitamin', group: 'Vitamin B2 (Riboflavin)'),
    '리보플라빈': (category: 'vitamin', group: 'Vitamin B2 (Riboflavin)'),
    '비타민B6': (category: 'vitamin', group: 'Vitamin B6'),
    '비타민 B6': (category: 'vitamin', group: 'Vitamin B6'),
    '피리독신': (category: 'vitamin', group: 'Vitamin B6'),
    '비타민B12': (category: 'vitamin', group: 'Vitamin B12'),
    '비타민 B12': (category: 'vitamin', group: 'Vitamin B12'),
    '코발라민': (category: 'vitamin', group: 'Vitamin B12'),
    '비타민C': (category: 'vitamin', group: 'Vitamin C'),
    '비타민 C': (category: 'vitamin', group: 'Vitamin C'),
    '아스코르브산': (category: 'vitamin', group: 'Vitamin C'),
    '비타민D': (category: 'vitamin', group: 'Vitamin D'),
    '비타민 D': (category: 'vitamin', group: 'Vitamin D'),
    '비타민D3': (category: 'vitamin', group: 'Vitamin D'),
    '콜레칼시페롤': (category: 'vitamin', group: 'Vitamin D'),
    '비타민E': (category: 'vitamin', group: 'Vitamin E'),
    '비타민 E': (category: 'vitamin', group: 'Vitamin E'),
    '토코페롤': (category: 'vitamin', group: 'Vitamin E'),
    '비타민K': (category: 'vitamin', group: 'Vitamin K'),
    '비타민 K': (category: 'vitamin', group: 'Vitamin K'),
    '나이아신': (category: 'vitamin', group: 'Niacin'),
    '니아신': (category: 'vitamin', group: 'Niacin'),
    '엽산': (category: 'vitamin', group: 'Folate'),
    '폴산': (category: 'vitamin', group: 'Folate'),
    '판토텐산': (category: 'vitamin', group: 'Pantothenic Acid'),
    '비오틴': (category: 'vitamin', group: 'Biotin'),

    // === 미네랄 ===
    '칼슘': (category: 'mineral', group: 'Calcium'),
    '마그네슘': (category: 'mineral', group: 'Magnesium'),
    '아연': (category: 'mineral', group: 'Zinc'),
    '철': (category: 'mineral', group: 'Iron'),
    '철분': (category: 'mineral', group: 'Iron'),
    '셀렌': (category: 'mineral', group: 'Selenium'),
    '셀레늄': (category: 'mineral', group: 'Selenium'),
    '크롬': (category: 'mineral', group: 'Chromium'),
    '구리': (category: 'mineral', group: 'Copper'),
    '망간': (category: 'mineral', group: 'Manganese'),
    '요오드': (category: 'mineral', group: 'Iodine'),
    '칼륨': (category: 'mineral', group: 'Potassium'),
    '인': (category: 'mineral', group: 'Phosphorus'),
    '나트륨': (category: 'mineral', group: 'Sodium'),
    '몰리브덴': (category: 'mineral', group: 'Molybdenum'),

    // === 카로티노이드 ===
    '루테인': (category: 'carotenoid', group: 'Lutein'),
    '지아잔틴': (category: 'carotenoid', group: 'Zeaxanthin'),
    '제아잔틴': (category: 'carotenoid', group: 'Zeaxanthin'),
    '베타카로틴': (category: 'carotenoid', group: 'Beta-Carotene'),

    // === 지방산 ===
    '오메가3': (category: 'fatty_acid', group: 'Omega-3'),
    '오메가-3': (category: 'fatty_acid', group: 'Omega-3'),
    'EPA': (category: 'fatty_acid', group: 'EPA'),
    'DHA': (category: 'fatty_acid', group: 'DHA'),
    '오메가6': (category: 'fatty_acid', group: 'Omega-6'),

    // === 특수 영양소 ===
    '코엔자임Q10': (category: 'coenzyme', group: 'Coenzyme Q10'),
    '코큐텐': (category: 'coenzyme', group: 'Coenzyme Q10'),
    'CoQ10': (category: 'coenzyme', group: 'Coenzyme Q10'),
    '콜라겐': (category: 'protein', group: 'Collagen'),
    '프로바이오틱스': (category: 'probiotic', group: 'Probiotics'),
    '유산균': (category: 'probiotic', group: 'Probiotics'),
    '글루코사민': (category: 'joint', group: 'Glucosamine'),
    '콘드로이친': (category: 'joint', group: 'Chondroitin'),
    'MSM': (category: 'joint', group: 'MSM'),
    '밀크씨슬': (category: 'botanical', group: 'Milk Thistle'),
    '실리마린': (category: 'botanical', group: 'Milk Thistle'),
    '쏘팔메토': (category: 'botanical', group: 'Saw Palmetto'),
    '아르기닌': (category: 'amino_acid', group: 'Arginine'),
    'L-아르기닌': (category: 'amino_acid', group: 'Arginine'),
  };

  /// 한글 성분명으로 카테고리 조회
  ///
  /// [koreanName] STDR_STND에서 파싱된 한글 성분명
  /// 반환: (category, group) 튜플
  /// 매핑 실패 시 category: 'unknown', group: 원본 이름
  static ({String category, String group}) fromKoreanName(String koreanName) {
    // 1. 공백 정규화 (앞뒤 공백 제거)
    final normalized = koreanName.trim();

    // 2. 정확한 매칭 시도
    if (koreanMapping.containsKey(normalized)) {
      return koreanMapping[normalized]!;
    }

    // 3. 공백 제거 후 재시도 (예: "비타민 A" → "비타민A")
    final noSpace = normalized.replaceAll(' ', '');
    if (koreanMapping.containsKey(noSpace)) {
      return koreanMapping[noSpace]!;
    }

    // 4. 부분 매칭 시도 (예: "비타민B2(리보플라빈)" → "비타민B2")
    for (final entry in koreanMapping.entries) {
      if (normalized.startsWith(entry.key) ||
          noSpace.startsWith(entry.key.replaceAll(' ', ''))) {
        return entry.value;
      }
    }

    // 5. 매핑 실패
    return (category: 'unknown', group: normalized);
  }

  /// 영문 ingredientGroup이 매핑에 존재하는지 확인
  static bool isKnownGroup(String group) {
    return koreanMapping.values.any((v) => v.group == group);
  }
}
