import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/ingredient.dart';
import '../../models/supplement_product.dart';
import 'supplement_repository.dart';

/// Firestore 기반 영양제 Repository 구현체
///
/// Firebase Firestore를 사용하여 영양제 데이터를 저장/조회한다.
/// 향후 Supabase로 전환 시 이 클래스만 교체하면 된다.
class FirestoreSupplementRepository implements SupplementRepository {
  /// Firestore 컬렉션 참조
  final CollectionReference<Map<String, dynamic>> _collection;

  /// 싱글턴 인스턴스
  static FirestoreSupplementRepository? _instance;

  /// 싱글턴 접근자
  static FirestoreSupplementRepository get instance {
    _instance ??= FirestoreSupplementRepository._internal();
    return _instance!;
  }

  /// 내부 생성자
  FirestoreSupplementRepository._internal()
      : _collection = FirebaseFirestore.instance.collection('supplements');

  /// 테스트용 생성자 (DI)
  FirestoreSupplementRepository.withCollection(
      CollectionReference<Map<String, dynamic>> collection)
      : _collection = collection;

  @override
  Future<List<Ingredient>?> getIngredients(String productId) async {
    try {
      final doc = await _collection.doc(productId).get();
      if (!doc.exists) {
        return null;
      }
      return SupplementProduct.fromFirestore(doc).ingredients;
    } catch (e) {
      // Firestore 오류 시 null 반환 (graceful degradation)
      return null;
    }
  }

  @override
  Future<void> saveProduct(SupplementProduct product) async {
    try {
      await _collection.doc(product.id).set(
            product.toFirestore(),
            SetOptions(merge: true), // 기존 데이터가 있으면 병합
          );
    } catch (e) {
      // 저장 실패 시 무시 (캐시 역할이므로 치명적이지 않음)
      // 필요 시 로깅 추가: debugPrint('Firestore save failed: $e');
    }
  }

  @override
  Future<SupplementProduct?> getProduct(String productId) async {
    try {
      final doc = await _collection.doc(productId).get();
      if (!doc.exists) {
        return null;
      }
      return SupplementProduct.fromFirestore(doc);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<List<SupplementProduct>> searchProducts(String query,
      {int limit = 10}) async {
    if (query.isEmpty) {
      return [];
    }

    try {
      // Firestore는 부분 문자열 검색을 지원하지 않으므로
      // 시작 문자열 매칭 방식 사용
      final querySnapshot = await _collection
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThanOrEqualTo: '$query\uf8ff')
          .limit(limit)
          .get();

      return querySnapshot.docs
          .map((doc) => SupplementProduct.fromFirestore(doc))
          .toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<bool> exists(String productId) async {
    try {
      final doc = await _collection.doc(productId).get();
      return doc.exists;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<void> deleteProduct(String productId) async {
    try {
      await _collection.doc(productId).delete();
    } catch (e) {
      // 삭제 실패 시 무시
    }
  }

  @override
  Future<void> invalidateCache() async {
    // Firestore는 자동 캐시 관리하므로 별도 처리 불필요
    // 필요 시 여기에 로컬 캐시 초기화 로직 추가
  }

  /// 특정 소스의 모든 제품 조회
  ///
  /// [source] "kr_food_safety" 또는 "nih_dsld"
  Future<List<SupplementProduct>> getProductsBySource(String source,
      {int limit = 100}) async {
    try {
      final querySnapshot = await _collection
          .where('source', isEqualTo: source)
          .limit(limit)
          .get();

      return querySnapshot.docs
          .map((doc) => SupplementProduct.fromFirestore(doc))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// 제품 수 조회
  Future<int> getProductCount() async {
    try {
      final snapshot = await _collection.count().get();
      return snapshot.count ?? 0;
    } catch (e) {
      return 0;
    }
  }
}
