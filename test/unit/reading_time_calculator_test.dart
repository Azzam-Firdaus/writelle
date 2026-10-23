import 'package:flutter_test/flutter_test.dart';
import 'package:writtle/core/utils/reading_time_calculator.dart';

void main() {
  group('TC-006: ReadingTimeCalculator Tests (FR-013)', () {
    test('returns 1 min read for null or empty string', () {
      expect(ReadingTimeCalculator.calculate(null), equals('1 min read'));
      expect(ReadingTimeCalculator.calculate(''), equals('1 min read'));
      expect(ReadingTimeCalculator.calculate('   '), equals('1 min read'));
    });

    test('returns 1 min read for short text (< 200 words)', () {
      final shortText = List.generate(50, (index) => 'word').join(' ');
      expect(ReadingTimeCalculator.calculate(shortText), equals('1 min read'));
    });

    test('returns 2 min read for 400 words', () {
      final text = List.generate(400, (index) => 'word').join(' ');
      expect(ReadingTimeCalculator.calculate(text), equals('2 min read'));
    });

    test('rounds up correctly (ceil) for 250 words', () {
      final text = List.generate(250, (index) => 'word').join(' ');
      expect(ReadingTimeCalculator.calculate(text), equals('2 min read'));
    });
  });
}
