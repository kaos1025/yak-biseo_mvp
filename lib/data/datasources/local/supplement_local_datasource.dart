import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart' show rootBundle;

import '../../../models/supplement_product.dart';

/// 로컬 JSON 기반 영양제 데이터소스
///
/// `assets/db/supplements_db.json`을 로드하여 메모리에 캐시한다.
/// 검색/필터/OCR fuzzy 매칭을 지원한다.
class SupplementLocalDatasource {
  /// 메모리 캐시
  List<SupplementProduct> _products = [];

  /// 로드 완료 여부
  bool _isLoaded = false;

  /// 싱글턴 인스턴스
  static SupplementLocalDatasource? _instance;

  /// 싱글턴 접근자
  static SupplementLocalDatasource get instance {
    _instance ??= SupplementLocalDatasource._internal();
    return _instance!;
  }

  SupplementLocalDatasource._internal();

  /// 테스트용 생성자
  SupplementLocalDatasource.withData(List<SupplementProduct> products)
      : _products = products,
        _isLoaded = true;

  /// 데이터 로드 여부
  bool get isLoaded => _isLoaded;

  /// 전체 제품 수
  int get productCount => _products.length;

  /// assets에서 JSON 데이터 로드
  ///
  /// 이미 로드된 경우 스킵한다.
  Future<void> loadData() async {
    if (_isLoaded) return;

    final jsonString =
        await rootBundle.loadString('assets/db/supplements_db.json');
    final List<dynamic> jsonList = json.decode(jsonString) as List<dynamic>;

    _products = jsonList
        .map((item) =>
            SupplementProduct.fromLocalJson(item as Map<String, dynamic>))
        .toList();

    _isLoaded = true;
  }

  /// ID로 제품 조회
  SupplementProduct? getById(String id) {
    _ensureLoaded();
    try {
      return _products.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  /// 제품명 검색 (영문/한글, 대소문자 무시, 부분 매칭)
  ///
  /// [query] 검색어
  /// [limit] 최대 결과 수 (기본값 20)
  List<SupplementProduct> searchByName(String query, {int limit = 20}) {
    _ensureLoaded();
    if (query.isEmpty) return [];

    final q = query.toLowerCase();
    return _products
        .where((p) =>
            p.name.toLowerCase().contains(q) ||
            (p.nameKo?.toLowerCase().contains(q) ?? false))
        .take(limit)
        .toList();
  }

  /// 브랜드 검색
  ///
  /// [query] 브랜드명
  /// [limit] 최대 결과 수 (기본값 20)
  List<SupplementProduct> searchByBrand(String query, {int limit = 20}) {
    _ensureLoaded();
    if (query.isEmpty) return [];

    final q = query.toLowerCase();
    return _products
        .where((p) => p.brand.toLowerCase().contains(q))
        .take(limit)
        .toList();
  }

  /// 성분으로 검색
  ///
  /// [ingredientName] 성분명 또는 정규화된 성분명
  /// [limit] 최대 결과 수 (기본값 20)
  List<SupplementProduct> searchByIngredient(String ingredientName,
      {int limit = 20}) {
    _ensureLoaded();
    if (ingredientName.isEmpty) return [];

    final q = ingredientName.toLowerCase();
    return _products
        .where((p) => p.localIngredients.any((i) =>
            i.name.toLowerCase().contains(q) ||
            (i.nameKo?.toLowerCase().contains(q) ?? false) ||
            i.nameNormalized.contains(q)))
        .take(limit)
        .toList();
  }

  /// 소스별 제품 조회
  ///
  /// [source] "iherb" 또는 "oliveyoung"
  List<SupplementProduct> getAllBySource(String source) {
    _ensureLoaded();
    return _products.where((p) => p.source == source).toList();
  }

  /// OCR 텍스트 → 유사 제품 매칭 (fuzzy)
  ///
  /// OCR이 부정확할 수 있으므로 토큰 기반 유사도 비교를 사용한다.
  /// [ocrText] OCR로 인식된 전체 텍스트
  /// [limit] 최대 결과 수 (기본값 5)
  List<({SupplementProduct product, double score})> fuzzyMatchFromOcr(
      String ocrText,
      {int limit = 5}) {
    _ensureLoaded();
    if (ocrText.isEmpty) return [];

    // OCR 텍스트에서 토큰 추출 (공백, 줄바꿈, 특수문자 기준)
    final tokens = _tokenize(ocrText);
    if (tokens.isEmpty) return [];

    // 각 제품에 대해 유사도 점수 계산
    final scored = <({SupplementProduct product, double score})>[];

    for (final product in _products) {
      final score = _calculateMatchScore(tokens, product);
      if (score > 0.1) {
        scored.add((product: product, score: score));
      }
    }

    // 점수 내림차순 정렬
    scored.sort((a, b) => b.score.compareTo(a.score));

    return scored.take(limit).toList();
  }

  /// 텍스트를 검색 토큰으로 분리
  List<String> _tokenize(String text) {
    return text
        .toLowerCase()
        .split(RegExp(r'[\s,;:/\-\n\r]+'))
        .where((t) => t.length >= 2) // 너무 짧은 토큰 제외
        .toSet() // 중복 제거
        .toList();
  }

  /// 제품과 OCR 토큰 간 매칭 점수 계산
  ///
  /// 브랜드 완전 매칭 = 높은 가중치
  /// 제품명 토큰 매칭 = 중간 가중치
  /// 성분명 매칭 = 낮은 가중치
  double _calculateMatchScore(
      List<String> ocrTokens, SupplementProduct product) {
    double score = 0;

    final brandLower = product.brand.toLowerCase();
    final nameLower = product.name.toLowerCase();
    final nameKoLower = product.nameKo?.toLowerCase() ?? '';

    // 제품명/브랜드 토큰화
    final nameTokens = _tokenize('$nameLower $nameKoLower');

    for (final token in ocrTokens) {
      // 브랜드 매칭 (가중치 3)
      if (brandLower.contains(token) || token.contains(brandLower)) {
        score += 3.0;
        continue;
      }

      // 제품명 정확 토큰 매칭 (가중치 2)
      if (nameTokens.any((nt) => nt == token)) {
        score += 2.0;
        continue;
      }

      // 제품명 부분 매칭 (가중치 1)
      if (nameLower.contains(token) || nameKoLower.contains(token)) {
        score += 1.0;
        continue;
      }

      // 성분명 매칭 (가중치 0.5)
      for (final ing in product.localIngredients) {
        final ingNameLower = ing.name.toLowerCase();
        final ingKoLower = ing.nameKo?.toLowerCase() ?? '';
        if (ingNameLower.contains(token) || ingKoLower.contains(token)) {
          score += 0.5;
          break;
        }
      }
    }

    // 토큰 수로 정규화
    return score / ocrTokens.length;
  }

  /// Levenshtein distance (편집 거리)
  ///
  /// 두 문자열 간의 최소 편집 연산(삽입/삭제/치환) 수
  static int levenshteinDistance(String s, String t) {
    if (s == t) return 0;
    if (s.isEmpty) return t.length;
    if (t.isEmpty) return s.length;

    final sLen = s.length;
    final tLen = t.length;

    // 공간 최적화: 이전 행과 현재 행만 유지
    var prevRow = List<int>.generate(tLen + 1, (j) => j);
    var currRow = List<int>.filled(tLen + 1, 0);

    for (var i = 1; i <= sLen; i++) {
      currRow[0] = i;
      for (var j = 1; j <= tLen; j++) {
        final cost = s[i - 1] == t[j - 1] ? 0 : 1;
        currRow[j] = min(
          min(currRow[j - 1] + 1, prevRow[j] + 1),
          prevRow[j - 1] + cost,
        );
      }
      // Swap rows
      final temp = prevRow;
      prevRow = currRow;
      currRow = temp;
    }

    return prevRow[tLen];
  }

  /// 로드 여부 확인
  void _ensureLoaded() {
    if (!_isLoaded) {
      throw StateError(
          'SupplementLocalDatasource: 데이터가 로드되지 않았습니다. loadData()를 먼저 호출하세요.');
    }
  }
}
