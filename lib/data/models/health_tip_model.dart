class HealthTipModel {
  final String id;
  final String questionKo;
  final String questionEn;
  final String teaserKo;
  final String teaserEn;
  final String ctaKo;
  final String ctaEn;

  const HealthTipModel({
    required this.id,
    required this.questionKo,
    required this.questionEn,
    required this.teaserKo,
    required this.teaserEn,
    required this.ctaKo,
    required this.ctaEn,
  });

  factory HealthTipModel.fromJson(Map<String, dynamic> json) {
    return HealthTipModel(
      id: json['id'] as String,
      questionKo: json['questionKo'] as String,
      questionEn: json['questionEn'] as String,
      teaserKo: json['teaserKo'] as String,
      teaserEn: json['teaserEn'] as String,
      ctaKo: json['ctaKo'] as String,
      ctaEn: json['ctaEn'] as String,
    );
  }

  String getQuestion(String locale) => locale == 'en' ? questionEn : questionKo;
  String getTeaser(String locale) => locale == 'en' ? teaserEn : teaserKo;
  String getCta(String locale) => locale == 'en' ? ctaEn : ctaKo;
}
