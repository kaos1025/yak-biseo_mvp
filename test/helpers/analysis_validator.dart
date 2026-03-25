import 'package:myapp/models/supplecut_analysis_result.dart';

import 'ground_truth.dart';

/// 검증 이슈 단건
class ValidationIssue {
  /// "error" | "warning" | "skip"
  final String level;

  /// "ocr" | "analysis" | "exclusion" | "overlap" | "ingredient" | "crash"
  final String category;

  final String message;

  const ValidationIssue({
    required this.level,
    required this.category,
    required this.message,
  });
}

/// 단일 테스트 케이스 검증 결과
class ValidationReport {
  final String testName;
  final List<ValidationIssue> issues;

  const ValidationReport({
    required this.testName,
    required this.issues,
  });

  bool get passed => issues.every((i) => i.level != 'error');
  int get errorCount => issues.where((i) => i.level == 'error').length;
  int get warningCount => issues.where((i) => i.level == 'warning').length;
}

/// SuppleCutAnalysisResult를 GroundTruth와 비교 검증
class AnalysisValidator {
  static ValidationReport validate(
    SuppleCutAnalysisResult result,
    GroundTruth expected,
  ) {
    final issues = <ValidationIssue>[];

    // ── 1단계: OCR 검증 ──

    // 제품 수 확인
    if (result.products.length != expected.expectedProducts) {
      issues.add(ValidationIssue(
        level: 'warning',
        category: 'ocr',
        message: '제품 수 불일치: '
            '${result.products.length} (기대: ${expected.expectedProducts})',
      ));
    }

    // 필수 키워드 인식 확인
    for (final keyword in expected.mustDetect) {
      final kw = keyword.toLowerCase();
      final detected = result.products.any(
        (p) =>
            p.name.toLowerCase().contains(kw) ||
            (p.nameKo?.toLowerCase().contains(kw) ?? false),
      );
      if (!detected) {
        issues.add(ValidationIssue(
          level: 'error',
          category: 'ocr',
          message: '미인식: "$keyword"',
        ));
      }
    }

    // ── 2단계: 분석 검증 (OCR error가 없을 때만) ──

    final hasOcrErrors =
        issues.any((i) => i.category == 'ocr' && i.level == 'error');
    if (hasOcrErrors) {
      issues.add(const ValidationIssue(
        level: 'skip',
        category: 'analysis',
        message: 'OCR 에러로 분석 검증 SKIP',
      ));
      return ValidationReport(testName: expected.testName, issues: issues);
    }

    // 전체 판정 확인
    final actualResult = _determineResult(result);
    if (actualResult != expected.expectedResult) {
      issues.add(ValidationIssue(
        level: 'error',
        category: 'analysis',
        message: '판정 불일치: $actualResult (기대: ${expected.expectedResult})',
      ));
    }

    // ── 3단계: 제외 추천 검증 ──

    if (expected.expectedExclusion != null) {
      final actual = result.excludedProduct?.toLowerCase() ?? '';
      final exp = expected.expectedExclusion!.toLowerCase();
      if (!actual.contains(exp)) {
        issues.add(ValidationIssue(
          level: 'error',
          category: 'exclusion',
          message: '제외 추천 불일치: '
              '"${result.excludedProduct}" (기대: "${expected.expectedExclusion}")',
        ));
      }
    } else if (result.excludedProduct != null &&
        result.excludedProduct!.isNotEmpty) {
      issues.add(ValidationIssue(
        level: 'warning',
        category: 'exclusion',
        message: '불필요한 제외 추천: "${result.excludedProduct}" (기대: 없음)',
      ));
    }

    // ── 4단계: 중복 성분 검증 ──

    for (final expectedDup in expected.dangerOverlaps) {
      final kw = expectedDup.toLowerCase();
      final found = result.duplicates.any(
        (d) =>
            d.ingredient.toLowerCase().contains(kw) && d.riskLevel == 'danger',
      );
      if (!found) {
        issues.add(ValidationIssue(
          level: 'error',
          category: 'overlap',
          message: 'danger 중복 미감지: "$expectedDup"',
        ));
      }
    }

    for (final expectedDup in expected.warningOverlaps) {
      final kw = expectedDup.toLowerCase();
      final found = result.duplicates.any(
        (d) =>
            d.ingredient.toLowerCase().contains(kw) &&
            (d.riskLevel == 'warning' || d.riskLevel == 'danger'),
      );
      if (!found) {
        issues.add(ValidationIssue(
          level: 'warning',
          category: 'overlap',
          message: 'warning 중복 미감지: "$expectedDup"',
        ));
      }
    }

    // ── 5단계: 금지 패턴 검증 ──

    for (final forbidden in expected.mustNotContain) {
      // "Fish Oil에 Vitamin A" 또는 "Fish Oil:Vitamin A" → 제품명, 성분명
      String productKeyword;
      String ingredientKeyword;

      final korSep = forbidden.indexOf('에 ');
      final colonSep = forbidden.indexOf(':');

      if (korSep >= 0) {
        productKeyword = forbidden.substring(0, korSep).trim().toLowerCase();
        ingredientKeyword =
            forbidden.substring(korSep + 2).trim().toLowerCase();
      } else if (colonSep >= 0) {
        productKeyword = forbidden.substring(0, colonSep).trim().toLowerCase();
        ingredientKeyword =
            forbidden.substring(colonSep + 1).trim().toLowerCase();
      } else {
        continue;
      }

      AnalyzedProduct? matchedProduct;
      for (final p in result.products) {
        if (p.name.toLowerCase().contains(productKeyword)) {
          matchedProduct = p;
          break;
        }
      }

      if (matchedProduct != null) {
        final hasIngredient = matchedProduct.ingredients.any(
          (ing) => ing.name.toLowerCase().contains(ingredientKeyword),
        );
        if (hasIngredient) {
          issues.add(ValidationIssue(
            level: 'error',
            category: 'ingredient',
            message: '금지 성분 포함: $forbidden',
          ));
        }
      }
    }

    return ValidationReport(testName: expected.testName, issues: issues);
  }

  static String _determineResult(SuppleCutAnalysisResult result) {
    if (result.duplicates.isEmpty) return 'perfect_combo';
    final hasDanger = result.duplicates.any((d) => d.riskLevel == 'danger');
    if (hasDanger) return 'overlap_danger';
    return 'overlap_safe';
  }
}
