import '../../models/pill.dart';
import '../mock/dummy_drugs.dart';

class DrugRepository {
  /// 검색어를 기반으로 약품을 검색합니다.
  /// 실제 API 호출을 흉내내기 위해 500ms 지연을 둡니다.
  Future<List<BasePill>> searchDrugs(String query) async {
    // 네트워크 딜레이 시뮬레이션 (규칙 13번 준수)
    await Future.delayed(const Duration(milliseconds: 500));

    if (query.isEmpty) {
      return dummyDrugs;
    }

    final input = query.toLowerCase();
    return dummyDrugs.where((pill) {
      final brand = pill.brand.toLowerCase();
      final name = pill.name.toLowerCase();

      bool matches = brand.contains(input) || name.contains(input);

      if (pill is KoreanPill) {
        matches = matches ||
            pill.category.toLowerCase().contains(input) ||
            pill.ingredients.toLowerCase().contains(input);
      } else if (pill is AmericanPill) {
        matches = matches ||
            pill.upcCode.contains(input) ||
            pill.supplementFacts.toString().toLowerCase().contains(input);
      }

      return matches;
    }).toList();
  }
}
