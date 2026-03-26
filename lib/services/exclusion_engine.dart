import '../models/onestop_analysis_result.dart';
import '../models/supplecut_analysis_result.dart';

/// 제외 추천 티어
class ExclusionTier {
  static const criticalStop = 'critical_stop';
  static const recommendRemove = 'recommend_remove';
  static const conditionalRemove = 'conditional_remove';
}

/// 개별 제외 추천 항목
class ExclusionItem {
  final String product;
  final String tier;
  final String reason;
  final double monthlyCostUsd;

  const ExclusionItem({
    required this.product,
    required this.tier,
    required this.reason,
    this.monthlyCostUsd = 0.0,
  });
}

/// 제외 추천 결과
class ExclusionResult {
  /// 티어별 제외 항목 리스트
  final List<ExclusionItem> items;

  /// 남기는 제품명 리스트
  final List<String> keptProducts;

  /// 월간 절감액 (USD) — critical_stop 제외
  final double monthlySavings;

  /// 연간 절감액 (USD) — critical_stop 제외
  final double annualSavings;

  /// 전체 제품 수
  final int totalProductCount;

  const ExclusionResult({
    this.items = const [],
    this.keptProducts = const [],
    this.monthlySavings = 0.0,
    this.annualSavings = 0.0,
    this.totalProductCount = 0,
  });

  const ExclusionResult.none()
      : items = const [],
        keptProducts = const [],
        monthlySavings = 0.0,
        annualSavings = 0.0,
        totalProductCount = 0;

  bool get hasExclusion => items.isNotEmpty;

  /// 전체 제외 제품명 (모든 티어 합산)
  List<String> get excludedProducts => items.map((i) => i.product).toList();

  /// critical_stop 항목
  List<ExclusionItem> get criticalStopItems =>
      items.where((i) => i.tier == ExclusionTier.criticalStop).toList();

  /// recommend_remove 항목
  List<ExclusionItem> get recommendRemoveItems =>
      items.where((i) => i.tier == ExclusionTier.recommendRemove).toList();

  /// conditional_remove 항목
  List<ExclusionItem> get conditionalRemoveItems =>
      items.where((i) => i.tier == ExclusionTier.conditionalRemove).toList();

  /// 절감 대상 항목 (recommend + conditional)
  List<ExclusionItem> get savingsItems => items
      .where((i) =>
          i.tier == ExclusionTier.recommendRemove ||
          i.tier == ExclusionTier.conditionalRemove)
      .toList();

  bool get hasCriticalStop => criticalStopItems.isNotEmpty;
  bool get hasSavings => savingsItems.isNotEmpty;

  /// 배너 텍스트용 (절감 대상만)
  String? get excludedProduct {
    final savings = savingsItems;
    if (savings.isEmpty) return null;
    final kept = keptProducts.length;
    if (kept == 1) {
      return 'ALL EXCEPT ${keptProducts.first}';
    }
    return '${savings.length} of $totalProductCount products';
  }
}

/// 제외 추천 규칙 엔진 (Deterministic)
class ExclusionEngine {
  static ExclusionResult calculate({
    required List<OnestopProduct> products,
    required List<FunctionalOverlap> functionalOverlaps,
    required List<SafetyAlert> safetyAlerts,
    required List<DuplicateIngredient> duplicates,
  }) {
    final allProductNames = products.map((p) => p.name).toSet();
    final items = <String, ExclusionItem>{}; // product name → item (dedup)
    final keepSet = <String>{};

    // ── safety_alerts를 정규 이름 + alertType으로 resolve ──
    final resolvedAlerts = <_ResolvedAlert>[];
    for (final sa in safetyAlerts) {
      final matched = _findProduct(products, sa.product);
      if (matched != null) {
        resolvedAlerts
            .add(_ResolvedAlert(matched.name, sa.alertType, sa.summary));
      }
    }

    // ── 1. critical_stop: research_chemical, therapeutic_dose ──
    for (final ra in resolvedAlerts) {
      if (ra.alertType == 'research_chemical' ||
          ra.alertType == 'therapeutic_dose') {
        final product = _findProduct(products, ra.name);
        items[ra.name] = ExclusionItem(
          product: ra.name,
          tier: ExclusionTier.criticalStop,
          reason: ra.summary,
          monthlyCostUsd: product?.monthlyCostEstimate ?? 0.0,
        );
      }
    }

    // critical_stop 제품은 functional_overlaps keepSet에서도 제외
    final criticalStopNames = items.keys.toSet();

    // ── 2. functional_overlaps high severity → recommend_remove ──
    for (final fo in functionalOverlaps) {
      if (fo.severity != 'high' || fo.products.length < 2) continue;

      final groupProducts = <_ProductWithCost>[];
      for (final foName in fo.products) {
        final matched = _findProduct(products, foName);
        if (matched != null &&
            !groupProducts.any((p) => p.name == matched.name)) {
          groupProducts
              .add(_ProductWithCost(matched.name, matched.monthlyCostEstimate));
        }
      }

      if (groupProducts.length < 2) continue;

      // critical_stop/safety_alert 아닌 제품 중 최저 비용 1개 keep
      final safeAlertNames = resolvedAlerts.map((ra) => ra.name).toSet();
      final safeProducts = groupProducts
          .where((p) =>
              !criticalStopNames.contains(p.name) &&
              !safeAlertNames.contains(p.name))
          .toList();

      String keepProduct;
      if (safeProducts.isNotEmpty) {
        safeProducts.sort((a, b) => a.cost.compareTo(b.cost));
        keepProduct = safeProducts.first.name;
      } else {
        // 전부 alert → 가장 저렴한 1개 keep
        final nonCritical = groupProducts
            .where((p) => !criticalStopNames.contains(p.name))
            .toList();
        if (nonCritical.isNotEmpty) {
          nonCritical.sort((a, b) => a.cost.compareTo(b.cost));
          keepProduct = nonCritical.first.name;
        } else {
          groupProducts.sort((a, b) => a.cost.compareTo(b.cost));
          keepProduct = groupProducts.first.name;
        }
      }

      keepSet.add(keepProduct);

      for (final p in groupProducts) {
        if (p.name != keepProduct && !items.containsKey(p.name)) {
          items[p.name] = ExclusionItem(
            product: p.name,
            tier: ExclusionTier.recommendRemove,
            reason: '${fo.pathway} overlap — excessive combined effect',
            monthlyCostUsd: p.cost,
          );
        }
      }
    }

    // ── 3. regulatory_warning safety_alerts → recommend_remove ──
    for (final ra in resolvedAlerts) {
      if (ra.alertType == 'regulatory_warning' &&
          !items.containsKey(ra.name) &&
          !keepSet.contains(ra.name)) {
        final product = _findProduct(products, ra.name);
        items[ra.name] = ExclusionItem(
          product: ra.name,
          tier: ExclusionTier.recommendRemove,
          reason: ra.summary,
          monthlyCostUsd: product?.monthlyCostEstimate ?? 0.0,
        );
      }
    }

    // ── 4. duplicates danger/warning → conditional_remove ──
    final riskyDuplicates = duplicates
        .where((d) => d.riskLevel == 'danger' || d.riskLevel == 'warning')
        .toList();

    for (final dup in riskyDuplicates) {
      final involvedProducts =
          dup.products.where((name) => !items.containsKey(name)).toList();
      if (involvedProducts.length < 2) continue;

      String? bestCandidate;
      double bestAmount = -1;

      for (final productName in involvedProducts) {
        final product = _findAnalyzedProduct(
          products.map(_toAnalyzedProduct).toList(),
          productName,
        );
        if (product == null) continue;

        for (final ingredient in product.ingredients) {
          if (_ingredientMatches(dup.ingredient, ingredient.name)) {
            if (ingredient.amount > bestAmount) {
              bestAmount = ingredient.amount;
              bestCandidate = product.name;
            }
            break;
          }
        }
      }

      if (bestCandidate != null &&
          !keepSet.contains(bestCandidate) &&
          !items.containsKey(bestCandidate)) {
        final product = _findProduct(products, bestCandidate);
        items[bestCandidate] = ExclusionItem(
          product: bestCandidate,
          tier: ExclusionTier.conditionalRemove,
          reason: '${dup.ingredient} overlap — ${dup.totalAmount} exceeds UL',
          monthlyCostUsd: product?.monthlyCostEstimate ?? 0.0,
        );
      }
    }

    // ── 안전장치: 최소 1개 제품은 남겨야 함 ──
    final excludeNames = items.keys.toSet();
    if (excludeNames.length >= allProductNames.length &&
        allProductNames.length > 1) {
      for (final name in keepSet) {
        items.remove(name);
      }
      if (items.length >= allProductNames.length) {
        final sorted = List<OnestopProduct>.from(products)
          ..sort(
              (a, b) => a.monthlyCostEstimate.compareTo(b.monthlyCostEstimate));
        items.remove(sorted.first.name);
      }
    }

    if (items.isEmpty) {
      return const ExclusionResult.none();
    }

    // 남기는 제품
    final keptProducts =
        allProductNames.where((name) => !items.containsKey(name)).toList();

    // 절감액: critical_stop 제외
    double savingsMonthlyCost = 0.0;
    for (final item in items.values) {
      if (item.tier != ExclusionTier.criticalStop) {
        savingsMonthlyCost += item.monthlyCostUsd;
      }
    }

    return ExclusionResult(
      items: items.values.toList(),
      keptProducts: keptProducts,
      monthlySavings: savingsMonthlyCost,
      annualSavings: savingsMonthlyCost * 12,
      totalProductCount: allProductNames.length,
    );
  }

  // ── Private helpers ──

  static OnestopProduct? _findProduct(
    List<OnestopProduct> products,
    String name,
  ) {
    final nameLower = name.toLowerCase().trim();

    for (final p in products) {
      if (p.name.toLowerCase().trim() == nameLower) return p;
    }

    for (final p in products) {
      final pLower = p.name.toLowerCase().trim();
      if (pLower.contains(nameLower) || nameLower.contains(pLower)) return p;
    }

    final nameTokens = _tokenize(nameLower);
    if (nameTokens.length >= 2) {
      OnestopProduct? bestMatch;
      int bestScore = 0;

      for (final p in products) {
        final pLower = p.name.toLowerCase().trim();
        int score = 0;
        for (final token in nameTokens) {
          if (pLower.contains(token)) score++;
        }
        if (score >= (nameTokens.length * 0.8).ceil() && score > bestScore) {
          bestScore = score;
          bestMatch = p;
        }
      }

      if (bestMatch != null) return bestMatch;
    }

    return null;
  }

  static List<String> _tokenize(String text) {
    return text
        .split(RegExp(r'[\s,;:/\-\(\)]+'))
        .where((t) => t.length >= 2)
        .toList();
  }

  static AnalyzedProduct? _findAnalyzedProduct(
    List<AnalyzedProduct> products,
    String name,
  ) {
    for (final p in products) {
      if (p.name == name) return p;
    }
    return null;
  }

  static AnalyzedProduct _toAnalyzedProduct(OnestopProduct p) {
    return AnalyzedProduct(
      name: p.name,
      source: p.source,
      ingredients: p.ingredients
          .map((i) => AnalyzedIngredient(
                name: i.name,
                amount: i.amount,
                unit: i.unit,
              ))
          .toList(),
      estimatedMonthlyPrice: (p.monthlyCostEstimate * 1400).round(),
    );
  }

  static bool _ingredientMatches(String dupName, String ingredientName) {
    final a = dupName.toLowerCase().replaceAll(RegExp(r'[-_\s]+'), ' ').trim();
    final b =
        ingredientName.toLowerCase().replaceAll(RegExp(r'[-_\s]+'), ' ').trim();

    if (a == b) return true;
    if (a.contains(b) || b.contains(a)) return true;

    final aBase = a.replaceAll(RegExp(r'\d+'), '').trim();
    final bBase = b.replaceAll(RegExp(r'\d+'), '').trim();
    if (aBase.isNotEmpty && bBase.isNotEmpty) {
      if (aBase.contains(bBase) || bBase.contains(aBase)) return true;
    }

    return false;
  }
}

class _ProductWithCost {
  final String name;
  final double cost;

  _ProductWithCost(this.name, this.cost);
}

class _ResolvedAlert {
  final String name;
  final String alertType;
  final String summary;

  _ResolvedAlert(this.name, this.alertType, this.summary);
}
