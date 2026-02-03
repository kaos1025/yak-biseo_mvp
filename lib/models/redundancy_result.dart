// 규칙 엔진 분석 결과 모델
//
// AI에게 전달되어 설명 텍스트 생성의 입력으로 사용된다.
// AI는 이 결과를 바꿀 수 없고, 오직 결과를 사용자에게 설명하는 역할만 한다.

/// 중복 판정 결과
enum RedundancyVerdict {
  /// 50% 이상 중복 — 제거 권장
  redundant,

  /// 일부 중복 (1~49%) — 주의 필요
  partialOverlap,

  /// 중복 없음
  noOverlap,
}

/// 중복 제품 쌍 정보
class RedundantPair {
  /// 제품 A 이름
  final String productAName;

  /// 제품 A ID
  final String productAId;

  /// 제품 B 이름
  final String productBName;

  /// 제품 B ID
  final String productBId;

  /// 겹치는 ingredientGroup 목록 (예: ["Vitamin C", "Zinc"])
  final List<String> overlappingGroups;

  /// 겹침 비율 (0.0 ~ 1.0)
  final double overlapPercentage;

  /// 이 쌍의 개별 판정
  final RedundancyVerdict pairVerdict;

  const RedundantPair({
    required this.productAName,
    required this.productAId,
    required this.productBName,
    required this.productBId,
    required this.overlappingGroups,
    required this.overlapPercentage,
    required this.pairVerdict,
  });

  /// AI 프롬프트용 JSON 변환
  Map<String, dynamic> toJson() {
    return {
      'productA': productAName,
      'productB': productBName,
      'overlappingGroups': overlappingGroups,
      'overlapPercentage': (overlapPercentage * 100).round(),
      'verdict': pairVerdict.name,
    };
  }
}

/// 전체 분석 결과
class RedundancyAnalysisResult {
  /// 전체 판정 결과
  final RedundancyVerdict verdict;

  /// 중복 쌍 목록
  final List<RedundantPair> redundantPairs;

  /// 분석된 총 제품 수
  final int totalProductsAnalyzed;

  /// 중복으로 판정된 제품 수
  final int redundantProductCount;

  /// 각 제품의 개별 상태 (productId -> SAFE/REDUNDANT/WARNING)
  final Map<String, String> productStatuses;

  /// 예상 절약 금액
  final int estimatedSavings;

  /// 통화 단위
  final String currency;

  const RedundancyAnalysisResult({
    required this.verdict,
    required this.redundantPairs,
    required this.totalProductsAnalyzed,
    required this.redundantProductCount,
    required this.productStatuses,
    required this.estimatedSavings,
    this.currency = 'KRW',
  });

  /// 중복이 발견되었는지 여부
  bool get hasRedundancy => verdict != RedundancyVerdict.noOverlap;

  /// AI 설명 생성용 구조화 데이터
  /// AI 프롬프트에 JSON으로 포함됨
  Map<String, dynamic> toAiContext() {
    return {
      'verdict': verdict.name,
      'totalProducts': totalProductsAnalyzed,
      'redundantCount': redundantProductCount,
      'estimatedSavings': estimatedSavings,
      'currency': currency,
      'pairs': redundantPairs.map((p) => p.toJson()).toList(),
    };
  }

  /// 빈 결과 (제품이 없거나 분석 실패 시)
  factory RedundancyAnalysisResult.empty() {
    return const RedundancyAnalysisResult(
      verdict: RedundancyVerdict.noOverlap,
      redundantPairs: [],
      totalProductsAnalyzed: 0,
      redundantProductCount: 0,
      productStatuses: {},
      estimatedSavings: 0,
    );
  }
}
