/// Utilities for reading calculations and formatting.
/// Ref: docs/PRD.md (FR-013)
abstract class ReadingTimeCalculator {
  /// Words per minute reading speed assumption.
  static const int wordsPerMinute = 200;

  /// Returns estimated reading time string (e.g. "1 min read", "5 min read").
  static String calculate(String? text) {
    if (text == null || text.trim().isEmpty) {
      return '1 min read';
    }

    final words = text.trim().split(RegExp(r'\s+')).length;
    final minutes = (words / wordsPerMinute).ceil();
    final effectiveMinutes = minutes < 1 ? 1 : minutes;

    return '$effectiveMinutes min read';
  }
}
