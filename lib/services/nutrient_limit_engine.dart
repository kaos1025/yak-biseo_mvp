import 'dart:math' as math;
import '../models/ingredient.dart';
import '../models/redundancy_result.dart';
import '../models/product_with_ingredients.dart';

class _NutrientLimit {
  final double maleRda;
  final double femaleRda;
  final double ul;
  final String unit;
  final String scope; // 'total' or 'supplement_only'

  const _NutrientLimit({
    required this.maleRda,
    required this.femaleRda,
    required this.ul,
    required this.unit,
    this.scope = 'total',
  });
}

/// UL/RDA 분석 엔진 (결정론적 판정)
///
/// 미국 NIH ODS의 성인(19-50세) 기준을 적용한다.
class NutrientLimitEngine {
  // === 기준 데이터 (Source: NIH ODS) ===
  static const Map<String, _NutrientLimit> _limits = {
    'calcium':
        _NutrientLimit(maleRda: 1000, femaleRda: 1000, ul: 2500, unit: 'mg'),
    'magnesium': _NutrientLimit(
        maleRda: 400,
        femaleRda: 310,
        ul: 350,
        unit: 'mg',
        scope: 'supplement_only'), // 마그네슘은 보충제 섭취량만 UL 적용
    'iron': _NutrientLimit(maleRda: 8, femaleRda: 18, ul: 45, unit: 'mg'),
    'zinc': _NutrientLimit(maleRda: 11, femaleRda: 8, ul: 40, unit: 'mg'),
    'vitamin_d':
        _NutrientLimit(maleRda: 15, femaleRda: 15, ul: 100, unit: 'mcg'),
  };

  /// 제품 목록에 대한 영양소 분석 실행
  static UlRdaReport analyze(List<ProductWithIngredients> products) {
    if (products.isEmpty) {
      return const UlRdaReport(
        summaries: [],
        duplicatedNutrients: [],
        exceededUlNutrients: [],
      );
    }

    final totals = <String, double>{};
    final contributors = <String, List<NutrientContributor>>{};

    // 1. 모든 제품의 성분을 순회하며 합산
    for (final product in products) {
      for (final ing in product.ingredients) {
        final key = _canonicalKey(ing.imageNameOrGroup);
        if (!_limits.containsKey(key)) {
          continue;
        }

        final limit = _limits[key]!;
        final rawAmount = ing.amount ?? 0.0;
        final rawUnit = ing.unit ?? '';

        // 단위 변환 및 유효성 검사
        final convertedAmount =
            _convertUnit(rawAmount, rawUnit, limit.unit, key);

        // 변환 불가하거나 0이면 스킵 (UNKNOWN 처리)
        if (convertedAmount == null || convertedAmount <= 0) {
          continue;
        }

        final dailyAmount = convertedAmount * product.servingsPerDay;

        totals[key] = (totals[key] ?? 0.0) + dailyAmount;

        contributors.putIfAbsent(key, () => []).add(NutrientContributor(
              productId: product.productId,
              productName: product.productName,
              amount: dailyAmount,
              unit: limit.unit,
            ));
      }
    }

    // 2. 판정 및 요약 생성
    final summaries = <NutrientSummary>[];
    final exceededUl = <String>[];
    final duplicated = <String>[];

    for (final entry in _limits.entries) {
      final key = entry.key;
      final limit = entry.value;

      if (!totals.containsKey(key)) {
        continue;
      }

      final total = totals[key]!;
      final rdaMin = math.min(limit.maleRda, limit.femaleRda);
      final rdaMax = math.max(limit.maleRda, limit.femaleRda);

      NutrientStatus status;
      String msg;

      // 판정 로직
      if (total > limit.ul) {
        status = NutrientStatus.exceedsUl;
        exceededUl.add(key);
        msg = '상한 섭취량(${limit.ul}${limit.unit}) 초과';
      } else if (total >= 0.8 * limit.ul) {
        status = NutrientStatus.nearUl;
        msg = '상한 섭취량에 근접 (80% 이상)';
      } else if (total >= rdaMax) {
        status = NutrientStatus.ok;
        msg = '권장 섭취량 충족';
      } else if (total < 0.5 * rdaMin) {
        status = NutrientStatus.belowRda;
        msg = '권장량의 50% 미만 (섭취 부족)';
      } else {
        status = NutrientStatus.mid;
        msg = '권장량 미달';
      }

      // 중복 여부 확인 (2개 이상의 제품에서 섭취)
      final prodList = contributors[key] ?? [];
      if (prodList.length > 1) {
        duplicated.add(key);
      }

      summaries.add(NutrientSummary(
        nutrientKey: key,
        totalAmount: double.parse(total.toStringAsFixed(2)), // 소수점 정리
        unit: limit.unit,
        maleRda: limit.maleRda,
        femaleRda: limit.femaleRda,
        ulAmount: limit.ul,
        ulScope: limit.scope,
        status: status,
        messageKo: msg,
        contributors: prodList,
      ));
    }

    return UlRdaReport(
      summaries: summaries,
      duplicatedNutrients: duplicated,
      exceededUlNutrients: exceededUl,
    );
  }

  /// 표준 키 매핑 (Canonicalization)
  static String _canonicalKey(String group) {
    final lower = group.toLowerCase().trim();
    if (lower.contains('calcium') || lower.contains('칼슘')) {
      return 'calcium';
    }
    if (lower.contains('magnesium') || lower.contains('마그네슘')) {
      return 'magnesium';
    }
    if (lower.contains('iron') ||
        lower.contains('철분') ||
        lower.contains('iron')) {
      return 'iron';
    }
    if (lower.contains('zinc') || lower.contains('아연')) {
      return 'zinc';
    }
    if (lower.contains('vitamin d') ||
        lower.contains('비타민d') ||
        lower.contains('비타민 d')) {
      return 'vitamin_d';
    }
    return lower;
  }

  /// 단위 변환 (RDA/UL 단위로 정규화)
  static double? _convertUnit(
      double amount, String fromUnit, String toUnit, String key) {
    final from = _cleanUnit(fromUnit);
    final to = toUnit.toLowerCase();

    if (from == to) {
      return amount;
    }

    // mg variants
    if (to == 'mg') {
      if (from == 'mcg' || from == 'ug') {
        return amount / 1000.0;
      }
      if (from == 'g') {
        return amount * 1000.0;
      }
    }

    // mcg variants
    if (to == 'mcg' || to == 'ug') {
      if (from == 'mg') {
        return amount * 1000.0;
      }
      if (from == 'iu' && key == 'vitamin_d') {
        return amount * 0.025; // Vitamin D: 1 IU = 0.025 mcg
      }
    }

    return null; // 변환 불가
  }

  static String _cleanUnit(String unit) {
    var u = unit.toLowerCase().trim();
    if (u == 'µg' || u == 'ug' || u == '㎍') {
      return 'mcg';
    }
    return u;
  }
}

extension IngredientExtension on Ingredient {
  String get imageNameOrGroup =>
      ingredientGroup.isNotEmpty ? ingredientGroup : name;
}
