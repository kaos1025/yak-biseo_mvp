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

/// 영양소 섭취 상태 판정
enum NutrientStatus {
  /// UL(상한 섭취량) 초과 — 위험
  exceedsUl,

  /// UL에 근접 (80% 이상) — 주의
  nearUl,

  /// 적정 섭취 (RDA 이상, UL 미만)
  ok,

  /// 섭취 부족 (RDA의 50% 미만) — 정보성
  belowRda,

  /// 그 외 (RDA 미달이지만 심각하지 않음) — 정보성
  mid,

  /// 판정 불가 (단위 변환 실패 등)
  unknown,
}

/// 특정 영양소에 기여한 제품 정보
class NutrientContributor {
  final String productId;
  final String productName;
  final double amount;
  final String unit;

  const NutrientContributor({
    required this.productId,
    required this.productName,
    required this.amount,
    required this.unit,
  });

  Map<String, dynamic> toJson() => {
        'productId': productId,
        'productName': productName,
        'amount': amount,
        'unit': unit,
      };
}

/// 영양소별 분석 요약
class NutrientSummary {
  final String nutrientKey; // canonical key (e.g., 'magnesium')
  final double totalAmount;
  final String unit;
  final double? maleRda; // 남성 권장량
  final double? femaleRda; // 여성 권장량
  final double? ulAmount; // 상한 섭취량
  final String? ulScope; // 'total' vs 'supplement_only'
  final NutrientStatus status;
  final String messageKo; // 간단 안내 메시지
  final List<NutrientContributor> contributors;

  const NutrientSummary({
    required this.nutrientKey,
    required this.totalAmount,
    required this.unit,
    this.maleRda,
    this.femaleRda,
    this.ulAmount,
    this.ulScope,
    required this.status,
    required this.messageKo,
    required this.contributors,
  });

  Map<String, dynamic> toJson() => {
        'nutrientKey': nutrientKey,
        'totalAmount': totalAmount,
        'unit': unit,
        'maleRda': maleRda,
        'femaleRda': femaleRda,
        'ulAmount': ulAmount,
        'ulScope': ulScope,
        'status': status.name,
        'messageKo': messageKo,
        'contributors': contributors.map((c) => c.toJson()).toList(),
      };
}

/// UL/RDA 전체 리포트
class UlRdaReport {
  /// 분석된 모든 영양소 요약
  final List<NutrientSummary> summaries;

  /// 중복 섭취가 발생한 영양소 목록 (단순 중복 포함)
  final List<String> duplicatedNutrients;

  /// UL을 초과한 영양소 목록
  final List<String> exceededUlNutrients;

  const UlRdaReport({
    required this.summaries,
    required this.duplicatedNutrients,
    required this.exceededUlNutrients,
  });

  Map<String, dynamic> toJson() => {
        'summaries': summaries.map((s) => s.toJson()).toList(),
        'duplicatedNutrients': duplicatedNutrients,
        'exceededUlNutrients': exceededUlNutrients,
      };
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

  /// UL/RDA 분석 리포트 (Optional)
  final UlRdaReport? ulRdaReport;

  const RedundancyAnalysisResult({
    required this.verdict,
    required this.redundantPairs,
    required this.totalProductsAnalyzed,
    required this.redundantProductCount,
    required this.productStatuses,
    required this.estimatedSavings,
    this.currency = 'KRW',
    this.ulRdaReport,
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
      if (ulRdaReport != null) 'ulRdaReport': ulRdaReport!.toJson(),
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
      ulRdaReport: null,
    );
  }
}
