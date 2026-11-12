/// Utilities for reading calculations and formatting.
/// Ref: docs/PRD.md (FR-013)
abstract class ReadingTimeCalculator {
  /// Words per minute reading speed assumption (industry standard: Medium, Substack).
  static const int wordsPerMinute = 200;

  /// Returns estimated reading time string (e.g. "1 min read", "5 min read").
  /// Optimized with zero heap allocations (no intermediate string arrays).
  static String calculate(String? text) {
    if (text == null || text.isEmpty) {
      return '1 min read';
    }

    int wordCount = 0;
    bool inWord = false;
    final len = text.length;

    for (int i = 0; i < len; i++) {
      final code = text.codeUnitAt(i);
      // Fast whitespace check (space 32, newline 10, tab 9, return 13)
      final isWhitespace = code <= 32;
      if (!isWhitespace && !inWord) {
        inWord = true;
        wordCount++;
      } else if (isWhitespace) {
        inWord = false;
      }
    }

    if (wordCount == 0) {
      return '1 min read';
    }

    final minutes = (wordCount / wordsPerMinute).ceil();
    final effectiveMinutes = minutes < 1 ? 1 : minutes;

    return '$effectiveMinutes min read';
  }
}
