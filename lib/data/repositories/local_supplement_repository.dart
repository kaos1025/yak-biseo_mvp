import '../../models/ingredient.dart';
import '../../models/supplement_product.dart';
import '../datasources/local/supplement_local_datasource.dart';
import 'supplement_repository.dart';

/// 로컬 DB 기반 영양제 Repository 구현체
///
/// assets/db/supplements_db.json을 사용하여 영양제 데이터를 검색/조회한다.
/// 나중에 Firebase 전환 시 이 클래스만 교체하면 된다.
class LocalSupplementRepository implements SupplementRepository {
  final SupplementLocalDatasource _datasource;

  LocalSupplementRepository(this._datasource);

  /// 싱글턴 인스턴스
  static LocalSupplementRepository? _instance;

  /// 싱글턴 접근자 (기본 데이터소스 사용)
  static LocalSupplementRepository get instance {
    _instance ??= LocalSupplementRepository(
      SupplementLocalDatasource.instance,
    );
    return _instance!;
  }

  /// 초기화 (데이터 로드)
  Future<void> initialize() async {
    await _datasource.loadData();
  }

  @override
  Future<List<Ingredient>?> getIngredients(String productId) async {
    final product = _datasource.getById(productId);
    if (product == null) return null;

    // localIngredients → Ingredient 변환
    return product.localIngredients
        .map((li) => Ingredient(
              name: li.name,
              category: 'unknown', // 로컬 DB에는 category 없음
              ingredientGroup: li.nameNormalized,
              amount: li.amount,
              unit: li.unit,
              source: product.source,
              sourceProductId: productId,
            ))
        .toList();
  }

  @override
  Future<void> saveProduct(SupplementProduct product) async {
    // 로컬 DB는 읽기 전용 (assets JSON)
    // 필요 시 SharedPreferences 등으로 확장 가능
  }

  @override
  Future<SupplementProduct?> getProduct(String productId) async {
    return _datasource.getById(productId);
  }

  @override
  Future<List<SupplementProduct>> searchProducts(String query,
      {int limit = 10}) async {
    return _datasource.searchByName(query, limit: limit);
  }

  @override
  Future<bool> exists(String productId) async {
    return _datasource.getById(productId) != null;
  }

  @override
  Future<void> deleteProduct(String productId) async {
    // 로컬 DB는 읽기 전용
  }

  @override
  Future<void> invalidateCache() async {
    // 필요 시 데이터 리로드
  }

  @override
  Future<List<SupplementProduct>> searchByBrand(String query,
      {int limit = 20}) async {
    return _datasource.searchByBrand(query, limit: limit);
  }

  @override
  Future<List<SupplementProduct>> searchByIngredient(String ingredientName,
      {int limit = 20}) async {
    return _datasource.searchByIngredient(ingredientName, limit: limit);
  }

  @override
  Future<List<SupplementProduct>> fuzzyMatchFromOcr(String ocrText,
      {int limit = 5}) async {
    final results = _datasource.fuzzyMatchFromOcr(ocrText, limit: limit);
    return results.map((r) => r.product).toList();
  }
}
