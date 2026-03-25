import '../models/supplecut_analysis_result.dart';

/// 제외 추천 결과
class ExclusionResult {
  final String? excludedProduct;
  final int monthlySavings;
  final int yearlySavings;

  const ExclusionResult({
    this.excludedProduct,
    this.monthlySavings = 0,
    this.yearlySavings = 0,
  });

  const ExclusionResult.none()
      : excludedProduct = null,
        monthlySavings = 0,
        yearlySavings = 0;
}

/// 제외 추천 규칙 엔진 (Deterministic)
///
/// Gemini가 제외 제품 선택 규칙을 일관 적용하지 못하는 문제를 해결하기 위해
/// Dart 코드에서 결정적으로 계산한다.
class ExclusionEngine {
  /// Gemini 분석 결과에서 제외 추천 제품을 결정적으로 계산
  static ExclusionResult calculate({
    required List<DuplicateIngredient> duplicates,
    required List<AnalyzedProduct> products,
  }) {
    // 1. danger/warning 중복만 필터 (safe는 제외 불필요)
    final riskyDuplicates = duplicates
        .where((d) => d.riskLevel == 'danger' || d.riskLevel == 'warning')
        .toList();

    if (riskyDuplicates.isEmpty) {
      return const ExclusionResult.none();
    }

    // 2. 각 중복 성분의 초과율 계산 (totalAmount / dailyLimit)
    //    dailyLimit이 null이면 skip
    final withExcessRatio = <_DuplicateWithRatio>[];
    for (final dup in riskyDuplicates) {
      if (dup.dailyLimit == null || dup.dailyLimit!.isEmpty) continue;

      final total = _parseAmount(dup.totalAmount);
      final limit = _parseAmount(dup.dailyLimit!);
      if (limit <= 0) continue;

      final ratio = total / limit;
      withExcessRatio.add(_DuplicateWithRatio(dup, ratio));
    }

    if (withExcessRatio.isEmpty) {
      return const ExclusionResult.none();
    }

    // 3. 초과율 내림차순 정렬 → 최대 초과율 성분 선택
    withExcessRatio.sort((a, b) => b.ratio.compareTo(a.ratio));
    final worst = withExcessRatio.first;

    // 4. 해당 성분에 가장 많이 기여하는 제품 찾기
    String? bestCandidate;
    double bestAmount = -1;

    for (final productName in worst.duplicate.products) {
      final product = _findProduct(products, productName);
      if (product == null) continue;

      for (final ingredient in product.ingredients) {
        if (_ingredientMatches(worst.duplicate.ingredient, ingredient.name)) {
          if (ingredient.amount > bestAmount) {
            bestAmount = ingredient.amount;
            bestCandidate = product.name;
          }
          break;
        }
      }
    }

    if (bestCandidate == null) {
      return const ExclusionResult.none();
    }

    // 5. 제외 후보의 estimatedMonthlyPrice로 savings 계산
    final excludedProduct = _findProduct(products, bestCandidate);
    final monthly = excludedProduct?.estimatedMonthlyPrice ?? 0;

    return ExclusionResult(
      excludedProduct: bestCandidate,
      monthlySavings: monthly,
      yearlySavings: monthly * 12,
    );
  }

  /// 문자열에서 숫자 추출: "150mcg" → 150.0, "1,347mcg DFE" → 1347.0
  // TODO: Phase 2 — 단위 정규화 (mg/mcg 혼용 시 mcg 기준 통일)
  static double _parseAmount(String text) {
    // 콤마 제거
    final cleaned = text.replaceAll(',', '');
    // 첫 번째 숫자 패턴 추출 (소수점 포함)
    final match = RegExp(r'(\d+\.?\d*)').firstMatch(cleaned);
    if (match == null) return 0.0;
    return double.tryParse(match.group(1)!) ?? 0.0;
  }

  /// 제품명으로 AnalyzedProduct 찾기
  static AnalyzedProduct? _findProduct(
    List<AnalyzedProduct> products,
    String name,
  ) {
    for (final p in products) {
      if (p.name == name) return p;
    }
    return null;
  }

  /// 성분명 퍼지 매칭
  ///
  /// DuplicateIngredient.ingredient (예: "Vitamin D3")와
  /// AnalyzedIngredient.name (예: "Vitamin D-3", "Cholecalciferol") 매칭
  static bool _ingredientMatches(String dupName, String ingredientName) {
    final a = dupName.toLowerCase().replaceAll(RegExp(r'[-_\s]+'), ' ').trim();
    final b =
        ingredientName.toLowerCase().replaceAll(RegExp(r'[-_\s]+'), ' ').trim();

    // 정확히 일치
    if (a == b) return true;

    // 양방향 contains
    if (a.contains(b) || b.contains(a)) return true;

    // 숫자 제거 후 비교 (예: "vitamin d3" vs "vitamin d")
    final aBase = a.replaceAll(RegExp(r'\d+'), '').trim();
    final bBase = b.replaceAll(RegExp(r'\d+'), '').trim();
    if (aBase.isNotEmpty && bBase.isNotEmpty) {
      if (aBase.contains(bBase) || bBase.contains(aBase)) return true;
    }

    return false;
  }
}

class _DuplicateWithRatio {
  final DuplicateIngredient duplicate;
  final double ratio;

  _DuplicateWithRatio(this.duplicate, this.ratio);
}
