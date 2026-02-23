class RecentAnalysisModel {
  final String id;
  final DateTime analyzedAt;
  final List<String> productNames;
  final String overallRisk; // safe | warning | danger
  final String? riskSummary;
  final int productCount;

  const RecentAnalysisModel({
    required this.id,
    required this.analyzedAt,
    required this.productNames,
    required this.overallRisk,
    this.riskSummary,
    required this.productCount,
  });

  factory RecentAnalysisModel.fromJson(Map<String, dynamic> json) {
    return RecentAnalysisModel(
      id: json['id'] as String,
      analyzedAt: DateTime.parse(json['analyzedAt'] as String),
      productNames: List<String>.from(json['productNames'] as List),
      overallRisk: json['overallRisk'] as String,
      riskSummary: json['riskSummary'] as String?,
      productCount: json['productCount'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'analyzedAt': analyzedAt.toIso8601String(),
      'productNames': productNames,
      'overallRisk': overallRisk,
      'riskSummary': riskSummary,
      'productCount': productCount,
    };
  }
}
