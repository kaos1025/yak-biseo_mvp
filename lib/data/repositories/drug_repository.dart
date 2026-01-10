import '../mock/dummy_drugs.dart';

class DrugRepository {
  /// 검색어를 기반으로 약품을 검색합니다.
  /// 실제 API 호출을 흉내내기 위해 500ms 지연을 둡니다.
  Future<List<Drug>> searchDrugs(String query) async {
    // 네트워크 딜레이 시뮬레이션 (규칙 13번 준수)
    await Future.delayed(const Duration(milliseconds: 500));

    if (query.isEmpty) {
      return dummyDrugs;
    }

    final input = query.toLowerCase();
    return dummyDrugs.where((drug) {
      final brand = drug.brandName.toLowerCase();
      final product = drug.productName.toLowerCase();
      final category = drug.category.toLowerCase();
      final ingredients = drug.ingredients.toLowerCase();

      return brand.contains(input) ||
          product.contains(input) ||
          category.contains(input) ||
          ingredients.contains(input);
    }).toList();
  }
}
