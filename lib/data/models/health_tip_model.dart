class HealthTipModel {
  final String id;
  final String question;
  final String teaser;
  final String cta;

  const HealthTipModel({
    required this.id,
    required this.question,
    required this.teaser,
    required this.cta,
  });

  factory HealthTipModel.fromJson(Map<String, dynamic> json) {
    return HealthTipModel(
      id: json['id'] as String,
      question: json['question'] as String,
      teaser: json['teaser'] as String,
      cta: json['cta'] as String,
    );
  }
}
