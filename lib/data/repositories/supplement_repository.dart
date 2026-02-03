import '../../models/ingredient.dart';
import '../../models/supplement_product.dart';

/// 영양제 데이터 Repository 인터페이스
///
/// 이 인터페이스를 통해 데이터 소스(Firestore, Supabase 등)를 교체할 수 있다.
/// 서비스 레이어는 이 인터페이스에만 의존하므로 구현체 변경이 용이하다.
abstract class SupplementRepository {
  /// 제품 ID로 성분 목록 조회
  ///
  /// [productId] 제품 고유 ID
  /// 반환: 성분 목록 또는 null (존재하지 않음)
  Future<List<Ingredient>?> getIngredients(String productId);

  /// 제품 정보 저장
  ///
  /// [product] 저장할 제품 정보
  Future<void> saveProduct(SupplementProduct product);

  /// 제품 ID로 제품 정보 조회
  ///
  /// [productId] 제품 고유 ID
  /// 반환: 제품 정보 또는 null
  Future<SupplementProduct?> getProduct(String productId);

  /// 제품명으로 검색
  ///
  /// [query] 검색어
  /// [limit] 최대 결과 수 (기본값 10)
  /// 반환: 매칭된 제품 목록
  Future<List<SupplementProduct>> searchProducts(String query,
      {int limit = 10});

  /// 제품 존재 여부 확인
  ///
  /// [productId] 제품 고유 ID
  /// 반환: 존재 여부
  Future<bool> exists(String productId);

  /// 제품 삭제
  ///
  /// [productId] 삭제할 제품 ID
  Future<void> deleteProduct(String productId);

  /// 캐시 무효화 (구현체에 따라 다름)
  Future<void> invalidateCache();
}
