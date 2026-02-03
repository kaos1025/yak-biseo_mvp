import '../models/ingredient.dart';

/// 식품안전나라 API 응답에서 활성 성분을 파싱하는 전용 파서
///
/// STDR_STND(규격기준) 텍스트를 파싱하여 활성 성분 + 함량을 추출한다.
/// RAWMTRL_NM은 전체 원재료(부형제 포함)이므로 주 파싱 대상이 아니다.
class KrFoodSafetyParser {
  /// 스킵해야 할 품질 검사 항목 키워드
  static const List<String> _skipKeywords = [
    '성상',
    '중금속',
    '잔류용매',
    '대장균',
    '붕해',
    '비소',
    '수은',
    '납',
    '카드뮴',
    '세균수',
    '진균수',
    '수분',
    '회분',
  ];

  /// STDR_STND 텍스트에서 활성 성분 목록 추출
  ///
  /// [stdrStnd] 식품안전나라 API 응답의 STDR_STND 필드
  /// [productId] 원본 제품의 PRDLST_REPORT_NO
  /// 반환: 파싱된 Ingredient 리스트
  ///
  /// 파싱 규칙:
  /// - "표시량" 키워드가 포함된 라인만 활성 성분으로 식별
  /// - 스킵 키워드가 있는 라인은 제외
  /// - 성분명: 콜론(:) 앞의 텍스트에서 번호 제거
  /// - 함량: "표시량" 뒤 괄호 내의 숫자 + 단위 추출
  static List<Ingredient> parseStdrStnd(String stdrStnd, {String? productId}) {
    final ingredients = <Ingredient>[];

    if (stdrStnd.isEmpty) {
      return ingredients;
    }

    // 줄 단위로 분리
    final lines = stdrStnd.split('\n');

    for (final rawLine in lines) {
      final line = rawLine.trim();

      // "표시량" 키워드가 없으면 스킵
      if (!line.contains('표시량')) {
        continue;
      }

      // 스킵 키워드 체크
      if (_containsSkipKeyword(line)) {
        continue;
      }

      try {
        final parsed = _parseLine(line);
        if (parsed != null) {
          ingredients.add(Ingredient.fromKrFoodSafety(
            parsedName: parsed.name,
            parsedAmount: parsed.amount,
            parsedUnit: parsed.unit,
            productId: productId,
          ));
        }
      } catch (e) {
        // 파싱 실패 시 해당 라인만 스킵 (앱 크래시 방지)
        continue;
      }
    }

    return ingredients;
  }

  /// 스킵 키워드 포함 여부 확인
  static bool _containsSkipKeyword(String line) {
    final lowerLine = line.toLowerCase();
    return _skipKeywords.any((keyword) => lowerLine.contains(keyword));
  }

  /// 단일 라인 파싱
  ///
  /// 입력 예시:
  /// - "2) 비타민A : 표시량 (600 ㎍RAE / 500 mg)의 80~150%"
  /// - "5) 아연: 표시량 (4.3 mg / 500 mg)의 80~150%"
  /// - "7) 루테인: 표시량(20 mg/ 500 mg)의 80~120%"
  static _ParsedIngredient? _parseLine(String line) {
    // 패턴 1: 번호 + 성분명 + 콜론 + 표시량 패턴
    // 성분명 추출: "2) 비타민A : 표시량..." → "비타민A"
    final namePattern = RegExp(r'^\d+\)\s*(.+?)\s*[:：]\s*표시량');
    final nameMatch = namePattern.firstMatch(line);

    String? name;
    if (nameMatch != null) {
      name = nameMatch.group(1)?.trim();
    } else {
      // 패턴 2: 번호 없이 "성분명: 표시량" 또는 "성분명 : 표시량"
      final altNamePattern = RegExp(r'^([가-힣A-Za-z0-9\s]+?)\s*[:：]\s*표시량');
      final altMatch = altNamePattern.firstMatch(line);
      if (altMatch != null) {
        name = altMatch.group(1)?.trim();
      }
    }

    if (name == null || name.isEmpty) {
      return null;
    }

    // 함량 + 단위 추출
    // "표시량 (600 ㎍RAE / 500 mg)" 또는 "표시량(20 mg/ 500 mg)"
    // 슬래시(/) 앞이 1회 섭취 기준 함량
    final quantityPattern = RegExp(r'표시량\s*\(?\s*([\d,.]+)\s*([^/\)\s]+)');
    final quantityMatch = quantityPattern.firstMatch(line);

    double? amount;
    String? unit;

    if (quantityMatch != null) {
      // 쉼표 제거 후 파싱 (예: "1,000" → "1000")
      final amountStr = quantityMatch.group(1)?.replaceAll(',', '');
      amount = double.tryParse(amountStr ?? '');
      unit = quantityMatch.group(2)?.trim();
    }

    return _ParsedIngredient(name: name, amount: amount, unit: unit);
  }

  /// RAWMTRL_NM에서 원재료명 목록 추출 (보조 참고용)
  ///
  /// [rawmtrlNm] 식품안전나라 API 응답의 RAWMTRL_NM 필드
  /// 반환: 원재료명 리스트 (부가 정보 제거됨)
  ///
  /// 주의: 규칙 엔진에서는 사용하지 않음. AI 설명 생성 시 보조 참고용.
  static List<String> parseRawMaterials(String rawmtrlNm) {
    if (rawmtrlNm.isEmpty) {
      return [];
    }

    return rawmtrlNm
        .split(',')
        .map((item) {
          // "(고시형)", "(식품첨가물)" 등 부가 정보 제거
          var cleaned = item.replaceAll(RegExp(r'\([^)]*\)'), '');
          return cleaned.trim();
        })
        .where((item) => item.isNotEmpty)
        .toList();
  }
}

/// 파싱된 성분 정보 (내부용)
class _ParsedIngredient {
  final String name;
  final double? amount;
  final String? unit;

  const _ParsedIngredient({
    required this.name,
    this.amount,
    this.unit,
  });
}
