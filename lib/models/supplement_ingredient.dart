/// 로컬 DB용 영양제 성분 모델
///
/// iHerb/Oliveyoung 스크래핑 데이터의 성분 정보를 표현한다.
/// 기존 [Ingredient] 모델과 달리 영문/한글 이름과 정규화된 이름을 포함한다.
class SupplementIngredient {
  /// 성분명 (영문 또는 한글)
  final String name;

  /// 성분명 한글
  final String? nameKo;

  /// 함량 수치
  final double? amount;

  /// 단위 (mg, mcg, IU 등)
  final String unit;

  /// 일일 권장량 대비 %
  final double? dailyValue;

  /// 정규화된 성분명 (머지 스크립트에서 생성)
  /// 예: "vitamin_d", "calcium", "omega_3"
  final String nameNormalized;

  const SupplementIngredient({
    required this.name,
    this.nameKo,
    this.amount,
    this.unit = '',
    this.dailyValue,
    this.nameNormalized = '',
  });

  /// JSON 역직렬화
  factory SupplementIngredient.fromJson(Map<String, dynamic> json) {
    return SupplementIngredient(
      name: json['name'] as String? ?? '',
      nameKo: json['name_ko'] as String?,
      amount: (json['amount'] as num?)?.toDouble(),
      unit: json['unit'] as String? ?? '',
      dailyValue: (json['dailyValue'] as num?)?.toDouble(),
      nameNormalized: json['name_normalized'] as String? ?? '',
    );
  }

  /// JSON 직렬화
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'name_ko': nameKo,
      'amount': amount,
      'unit': unit,
      'dailyValue': dailyValue,
      'name_normalized': nameNormalized,
    };
  }

  /// Gemini prompt용 문자열 변환
  ///
  /// 예: "Vitamin C (as Ascorbic Acid): 250 mg (278% DV)"
  String toGeminiContext() {
    final displayName = nameKo ?? name;
    final amountStr = amount != null ? '$amount $unit' : '함량 미표기';
    final dvStr = dailyValue != null ? ' ($dailyValue% DV)' : '';
    return '$displayName: $amountStr$dvStr';
  }

  @override
  String toString() {
    final amountStr = amount != null ? '$amount $unit' : 'N/A';
    return 'SupplementIngredient($name, $amountStr, normalized: $nameNormalized)';
  }
}
