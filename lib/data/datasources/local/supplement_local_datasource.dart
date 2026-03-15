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

    // ignore: avoid_print
    print('🔍 OCR Tokens: $tokens');

    // 각 제품에 대해 유사도 점수 계산
    final scored = <({SupplementProduct product, double score})>[];

    for (final product in _products) {
      final score = _calculateMatchScore(tokens, product);
      if (score > 3.0) {
        // ignore: avoid_print
        print('Possible Match: "${product.name}" Score: $score');
      }
      if (score >= 4.0) {
        scored.add((product: product, score: score));
      }
    }

    // 점수 내림차순 정렬
    scored.sort((a, b) => b.score.compareTo(a.score));

    return scored.take(limit).toList();
  }

  /// 텍스트를 검색 토큰으로 분리
  List<String> _tokenize(String text) {
    // 숫자+단위 패턴 제거 (예: 10,000mcg, 500mg, 1000IU, 50ml)
    var cleaned = text.replaceAll(
        RegExp(r'\d[\d,]*\s*(?:mcg|mg|g|kg|iu|ml|l|oz)\b',
            caseSensitive: false),
        '');
    // 하이픈 연결 패턴 보존 (예: 오메가-3 → 오메가3, B-12 → B12, Vitamin-D3 → VitaminD3)
    // \w는 한글 미지원이므로 유니코드 포함 패턴 사용
    cleaned = cleaned.replaceAll(RegExp(r'(?<=\S)-(?=\S)'), '');
    return cleaned
        .toLowerCase()
        .split(RegExp(r'[\s,;:/\-\n\r\(\)]+'))
        .where((t) => t.length >= 2) // 너무 짧은 토큰 제외
        .where((t) => !_noiseTokens.contains(t)) // 노이즈 토큰 제거
        .toSet() // 중복 제거
        .toList();
  }

  /// 매칭에 방해되는 노이즈 토큰
  ///
  /// 제품 설명에 자주 등장하지만 매칭에 도움이 안 되는 단어들.
  /// 이 토큰들이 매칭 점수를 희석시키는 것을 방지한다.
  static const _noiseTokens = <String>{
    // 비율/강도 표현
    'ratio', 'strength', 'double', 'triple', 'extra', 'high', 'ultra',
    'maximum', 'super', 'plus', 'advanced', 'premium', 'pure',
    // 제형 설명
    'extract', 'powder', 'liquid', 'complex', 'formula', 'blend',
    'supplement', 'dietary', 'food', 'foods',
    // 단위/형태
    'softgels', 'tablets', 'capsules', 'gummies', 'chewable',
    'veggie', 'vegan', 'vegetarian',
    'mg', 'mcg', 'g', 'kg', 'iu', 'ml', 'l', 'oz', // 측정 단위 추가
    // 한글 노이즈
    '건강기능식품', '건강', '기능', '식품', '보충제',
  };

  /// 제품과 OCR 토큰 간 매칭 점수 계산 (v3 - 2-Phase)
  ///
  /// Phase 1: 브랜드 매칭 → 통과 조건 (Gate)
  /// Phase 2: 제품명 핵심 키워드 매칭 → 주 점수
  /// Phase 3: 용량/정 수 매칭 → Tiebreaker
  ///
  /// 성분명 매칭은 제거됨 (false positive 방지)
  double _calculateMatchScore(
      List<String> ocrTokens, SupplementProduct product) {
    final brandLower = product.brand.toLowerCase();
    final nameLower = product.name.toLowerCase();
    final nameKoLower = product.nameKo?.toLowerCase() ?? '';

    // ── Phase 1: Brand Match (Gate) ──
    final brandTokens = _tokenize(brandLower);
    final ocrJoined = ocrTokens.join(' ');

    bool brandMatched = ocrJoined.contains(brandLower);
    for (final bt in brandTokens) {
      if (ocrTokens.any((ot) => ot == bt)) {
        brandMatched = true;
      }
    }

    // 브랜드가 매칭되지 않으면 즉시 제외
    if (!brandMatched) return 0.0;

    // ── OCR 토큰 분류: 이름 키워드 vs 숫자 ──
    final nameKeywords = <String>[];
    final numberTokens = <String>[];

    for (final token in ocrTokens) {
      if (brandTokens.contains(token)) continue; // 브랜드 토큰 스킵
      if (RegExp(r'^\d+$').hasMatch(token)) {
        numberTokens.add(token);
      } else {
        nameKeywords.add(token);
      }
    }

    // 제품명 토큰 (브랜드 제외)
    final productNameTokens = _tokenize('$nameLower $nameKoLower')
        .where((t) => !brandTokens.contains(t))
        .toSet();

    // ── Phase 2: Name Keyword Match (주 점수) ──
    int nameMatches = 0;
    for (final kw in nameKeywords) {
      if (productNameTokens.any((pt) => pt == kw) ||
          nameLower.contains(kw) ||
          nameKoLower.contains(kw)) {
        nameMatches++;
      }
    }

    // 이름 키워드가 있는데 하나도 안 맞으면 → 다른 제품
    if (nameMatches == 0 && nameKeywords.isNotEmpty) return 0.0;

    // 키워드 매칭률이 너무 낮으면 → 다른 제품 (false positive 방지)
    if (nameKeywords.length >= 2 && nameMatches / nameKeywords.length < 0.6) {
      return 0.0;
    }

    // ── Phase 3: Number Match (Tiebreaker) ──
    int numberMatches = 0;
    for (final num in numberTokens) {
      if (nameLower.contains(num)) {
        numberMatches++;
      }
    }

    return nameMatches * 5.0 + numberMatches * 2.0;
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
