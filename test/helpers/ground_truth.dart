/// 분석 테스트 정답지 모델
class GroundTruth {
  /// 테스트 케이스 이름
  final String testName;

  /// 테스트 이미지 파일명
  final String imageFile;

  /// 기대 제품 수
  final int expectedProducts;

  /// 기대 판정: "perfect_combo" | "overlap_safe" | "overlap_danger"
  final String expectedResult;

  /// 기대 제외 추천 제품 키워드 (null = 제외 없음)
  final String? expectedExclusion;

  /// danger 수준 중복 성분 키워드
  final List<String> dangerOverlaps;

  /// warning 수준 중복 성분 키워드
  final List<String> warningOverlaps;

  /// safe 수준 중복 성분 키워드
  final List<String> safeOverlaps;

  /// OCR 필수 인식 키워드 (제품명에 포함되어야 함)
  final List<String> mustDetect;

  /// 금지 패턴 ("제품명:성분명" 형태)
  final List<String> mustNotContain;

  const GroundTruth({
    required this.testName,
    required this.imageFile,
    required this.expectedProducts,
    required this.expectedResult,
    this.expectedExclusion,
    this.dangerOverlaps = const [],
    this.warningOverlaps = const [],
    this.safeOverlaps = const [],
    this.mustDetect = const [],
    this.mustNotContain = const [],
  });

  factory GroundTruth.fromJson(Map<String, dynamic> json) {
    return GroundTruth(
      testName: json['testName'] as String? ?? '',
      imageFile: json['imageFile'] as String? ?? '',
      expectedProducts: json['expectedProducts'] as int? ?? 0,
      expectedResult: json['expectedResult'] as String? ?? 'overlap_safe',
      expectedExclusion: json['expectedExclusion'] as String?,
      dangerOverlaps: _toStringList(json['dangerOverlaps']),
      warningOverlaps: _toStringList(json['warningOverlaps']),
      safeOverlaps: _toStringList(json['safeOverlaps']),
      mustDetect: _toStringList(json['mustDetect']),
      mustNotContain: _toStringList(json['mustNotContain']),
    );
  }

  static List<String> _toStringList(dynamic value) {
    if (value is List) return value.map((e) => e as String).toList();
    return [];
  }
}
