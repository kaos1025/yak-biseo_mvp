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
