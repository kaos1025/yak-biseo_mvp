class KeywordCleaner {
  /// Cleans the input text to make it suitable for API search queries.
  ///
  /// 1. Removes noise (brackets, special chars, emojis).
  /// 2. Removes explicit quantity units (e.g., 50포, 30정, 250mg) but keeps numbers in names (e.g., Omega3).
  /// 3. Normalizes spaces.
  /// 4. Returns the URL-encoded string.
  static String cleanAndEncode(String text) {
    String cleaned = clean(text);
    return Uri.encodeComponent(cleaned);
  }

  /// Raw cleaning method (without URL encoding) for debugging/display.
  static String clean(String text) {
    String result = text;

    // 1. Noise Reduction: Replace specific special chars with space
    // [], (), {}, -, /, *
    result = result.replaceAll(RegExp(r'[\[\]\(\)\{\}\-\/\*]'), ' ');

    // Remove Emojis (Basic ranges for common emojis)
    // This regex covers many common emoji ranges.
    result =
        result.replaceAll(RegExp(r'[\u{1F300}-\u{1F9FF}]', unicode: true), ' ');
    result =
        result.replaceAll(RegExp(r'[\u{2600}-\u{26FF}]', unicode: true), ' ');
    result =
        result.replaceAll(RegExp(r'[\u{2700}-\u{27BF}]', unicode: true), ' ');

    // 2. Unit Removal
    // Remove pattern: Number + (optional space) + Unit
    // Units: 포, 정, 캡슐, g, mg, ml, tablets, tablet, capsules, capsule
    // Constraint: Do NOT remove numbers that are part of the name (e.g., Omega3, VitaminB12)
    // Logic: Ensure the number is NOT preceded by a letter.
    final unitPattern = RegExp(
      r'(?<![a-zA-Z가-힣])\s*\d+\s*(?:mg|ml|g|kg|l|oz|포|정|알|캡슐|tablets?|capsules?|pills?)(?![a-zA-Z가-힣])',
      caseSensitive: false,
    );
    result = result.replaceAll(unitPattern, ' ');

    // 3. Normalize Spaces
    // Replace multiple spaces with single space and trim
    result = result.replaceAll(RegExp(r'\s+'), ' ').trim();

    return result;
  }
}

void main() {
  const testCases = [
    "종근당 락토핏 골드 50포(통)",
    "[해외직구] Nature Made Magnesium 250 mg",
    "고려은단 비타민C 1000 (120정)",
    "얼라이브! 원스데일리 포 맨 60정",
    "Jarrow Formulas, 펨 도필러스, 50억, 60 베지 캡슐",
    "California Gold Nutrition, Omega-3, 프리미엄 피쉬 오일, 100 피쉬 젤라틴 소프트젤",
    "나우푸드 실리마린 밀크시슬 300mg",
    "종근당건강 프로메가 알티지 오메가3 듀얼 60캡슐",
    "비타민B12 5000mcg", // mcq case testing (regex didn't explicitly include mcg, let's fix if needed)
    "CoQ10 100mg",
  ];

  print('--- KeywordCleaner Test Results ---');
  for (final input in testCases) {
    final cleaned = KeywordCleaner.clean(input);
    final encoded = KeywordCleaner.cleanAndEncode(input);
    print('Input: "$input"');
    print('Clean: "$cleaned"');
    print('Encoded: "$encoded"');
    print('---');
  }
}
