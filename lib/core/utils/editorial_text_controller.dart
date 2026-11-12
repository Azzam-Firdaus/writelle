import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Custom TextEditingController that provides live WYSIWYG styling in the editor:
/// - `==highlight==` displays directly with authentic canary yellow stabilo background
/// - `**bold**` displays directly with bold typography
/// - `*italic*` displays directly with italic typography
/// - `> quote` displays with quote styling
/// - `## heading` displays with heading typography
///
/// Also provides smart toggles (wrap / unwrap) for mobile editing.
/// Highly optimized with memoized caching and zero-backtracking linear regex
/// for stutter-free 120 FPS typing on mobile devices.
class WrittleEditorialTextController extends TextEditingController {
  WrittleEditorialTextController({super.text});

  // Cached results to eliminate re-parsing on cursor blink / layout / paint
  String? _cachedText;
  TextStyle? _cachedStyle;
  bool? _cachedIsDark;
  TextSpan? _cachedSpan;

  // Pre-compiled static regex to avoid per-keystroke compilation overhead.
  // Using [^=\n]+ and [^*\n]+ guarantees linear O(N) evaluation with 0 backtracking.
  static final RegExp _inlinePattern = RegExp(
    r'(==[^=\n]+==|\*\*[^*\n]+\*\*|\*[^*\n]+\*)',
  );

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final baseStyle = style ?? const TextStyle(fontSize: 16, height: 1.75);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fullText = text;

    if (fullText.isEmpty) {
      return TextSpan(text: '', style: baseStyle);
    }

    // 1. FAST CACHE HIT: Return existing TextSpan if text and styles are unchanged.
    // Completely eliminates CPU spikes during cursor blinking and selection movement.
    if (_cachedText == fullText &&
        _cachedStyle == baseStyle &&
        _cachedIsDark == isDark &&
        _cachedSpan != null) {
      return _cachedSpan!;
    }

    // 2. ULTRA-FAST PATH: If document contains no markdown markers, return single span.
    // Zero string splitting, zero regex evaluations, zero object churn.
    if (!fullText.contains('==') &&
        !fullText.contains('*') &&
        !fullText.contains('#') &&
        !fullText.contains('>')) {
      final singleSpan = TextSpan(text: fullText, style: baseStyle);
      _cachedText = fullText;
      _cachedStyle = baseStyle;
      _cachedIsDark = isDark;
      _cachedSpan = singleSpan;
      return singleSpan;
    }

    // 3. Pre-calculate styles once per build pass instead of inside loops
    final stabiloBgColor = isDark
        ? const Color(0xFFEAB308).withValues(alpha: 0.35)
        : const Color(0xFFFFF275);
    final stabiloTextColor = isDark
        ? const Color(0xFFFEF9C3)
        : const Color(0xFF1E140C);
    final delimiterColor = isDark
        ? const Color(0x35EAB308)
        : const Color(0x35854D0E);

    final stabiloStyle = baseStyle.copyWith(
      backgroundColor: stabiloBgColor,
      color: stabiloTextColor,
      fontWeight: FontWeight.w600,
    );
    final delimiterStyle = baseStyle.copyWith(
      color: delimiterColor,
      fontSize: 11,
    );
    final boldStyle = baseStyle.copyWith(fontWeight: FontWeight.bold);
    final italicStyle = baseStyle.copyWith(fontStyle: FontStyle.italic);

    final headingStyle = baseStyle.copyWith(
      fontSize: 19,
      fontWeight: FontWeight.bold,
      color: isDark ? Colors.white : AppColors.espresso,
    );
    final headingMarkerStyle = baseStyle.copyWith(
      color: AppColors.burntSienna.withValues(alpha: 0.4),
      fontWeight: FontWeight.bold,
    );

    final quoteStyle = baseStyle.copyWith(
      fontStyle: FontStyle.italic,
      color: isDark ? const Color(0xFFE2D9CC) : const Color(0xFF6B4226),
    );
    final quoteMarkerStyle = baseStyle.copyWith(
      color: AppColors.burntSienna,
      fontWeight: FontWeight.bold,
    );

    final spans = <InlineSpan>[];
    final lines = fullText.split('\n');

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final isLastLine = i == lines.length - 1;

      if (line.startsWith('## ')) {
        spans.add(TextSpan(text: '## ', style: headingMarkerStyle));
        _appendInlineSpans(
          spans: spans,
          lineText: line.substring(3),
          baseStyle: headingStyle,
          stabiloStyle: stabiloStyle,
          delimiterStyle: delimiterStyle,
          boldStyle: boldStyle,
          italicStyle: italicStyle,
        );
      } else if (line.startsWith('> ')) {
        spans.add(TextSpan(text: '▌ ', style: quoteMarkerStyle));
        _appendInlineSpans(
          spans: spans,
          lineText: line.substring(2),
          baseStyle: quoteStyle,
          stabiloStyle: stabiloStyle,
          delimiterStyle: delimiterStyle,
          boldStyle: boldStyle,
          italicStyle: italicStyle,
        );
      } else {
        _appendInlineSpans(
          spans: spans,
          lineText: line,
          baseStyle: baseStyle,
          stabiloStyle: stabiloStyle,
          delimiterStyle: delimiterStyle,
          boldStyle: boldStyle,
          italicStyle: italicStyle,
        );
      }

      if (!isLastLine) {
        spans.add(const TextSpan(text: '\n'));
      }
    }

    final parsedSpan = TextSpan(style: baseStyle, children: spans);
    _cachedText = fullText;
    _cachedStyle = baseStyle;
    _cachedIsDark = isDark;
    _cachedSpan = parsedSpan;
    return parsedSpan;
  }

  static void _appendInlineSpans({
    required List<InlineSpan> spans,
    required String lineText,
    required TextStyle baseStyle,
    required TextStyle stabiloStyle,
    required TextStyle delimiterStyle,
    required TextStyle boldStyle,
    required TextStyle italicStyle,
  }) {
    // Fast path: line without inline tokens is added as a single contiguous span
    if (!lineText.contains('==') && !lineText.contains('*')) {
      spans.add(TextSpan(text: lineText, style: baseStyle));
      return;
    }

    int lastEnd = 0;
    for (final match in _inlinePattern.allMatches(lineText)) {
      if (match.start > lastEnd) {
        spans.add(TextSpan(
          text: lineText.substring(lastEnd, match.start),
          style: baseStyle,
        ));
      }

      final matchedStr = match.group(0)!;

      if (matchedStr.startsWith('==') && matchedStr.endsWith('==') && matchedStr.length >= 4) {
        final inner = matchedStr.substring(2, matchedStr.length - 2);
        spans.add(TextSpan(text: '==', style: delimiterStyle));
        spans.add(TextSpan(text: inner, style: stabiloStyle));
        spans.add(TextSpan(text: '==', style: delimiterStyle));
      } else if (matchedStr.startsWith('**') && matchedStr.endsWith('**') && matchedStr.length >= 4) {
        final inner = matchedStr.substring(2, matchedStr.length - 2);
        spans.add(TextSpan(text: '**', style: delimiterStyle));
        spans.add(TextSpan(text: inner, style: boldStyle));
        spans.add(TextSpan(text: '**', style: delimiterStyle));
      } else if (matchedStr.startsWith('*') && matchedStr.endsWith('*') && matchedStr.length >= 2) {
        final inner = matchedStr.substring(1, matchedStr.length - 1);
        spans.add(TextSpan(text: '*', style: delimiterStyle));
        spans.add(TextSpan(text: inner, style: italicStyle));
        spans.add(TextSpan(text: '*', style: delimiterStyle));
      }

      lastEnd = match.end;
    }

    if (lastEnd < lineText.length) {
      spans.add(TextSpan(
        text: lineText.substring(lastEnd),
        style: baseStyle,
      ));
    }
  }

  // ==========================================
  // SMART TOGGLE ACTIONS (FOR KEYBOARD BAR)
  // ==========================================

  /// Toggles stabilo highlighter: wraps selected text or unwraps if already highlighted
  void toggleStabilo() {
    _toggleWrap(
      delimiter: '==',
      placeholder: 'teks sorotan',
    );
  }

  /// Toggles bold formatting
  void toggleBold() {
    _toggleWrap(
      delimiter: '**',
      placeholder: 'teks tebal',
    );
  }

  /// Toggles italic formatting
  void toggleItalic() {
    _toggleWrap(
      delimiter: '*',
      placeholder: 'teks miring',
    );
  }

  /// Toggles pull-quote prefix on current line
  void toggleQuote() {
    _toggleLinePrefix(prefix: '> ');
  }

  /// Toggles bullet list prefix on current line
  void toggleBulletList() {
    _toggleLinePrefix(prefix: '- ');
  }

  /// Toggles subheading prefix on current line
  void toggleHeading() {
    _toggleLinePrefix(prefix: '## ');
  }

  void _toggleWrap({
    required String delimiter,
    required String placeholder,
  }) {
    final fullText = text;
    final sel = selection;
    final dLen = delimiter.length;

    // 1. Text is selected
    if (sel.isValid && !sel.isCollapsed && sel.start < sel.end) {
      final selectedText = fullText.substring(sel.start, sel.end);

      // Selected text itself is wrapped in delimiter
      if (selectedText.startsWith(delimiter) &&
          selectedText.endsWith(delimiter) &&
          selectedText.length >= dLen * 2) {
        final unwrapped = selectedText.substring(dLen, selectedText.length - dLen);
        final newText = fullText.replaceRange(sel.start, sel.end, unwrapped);
        value = TextEditingValue(
          text: newText,
          selection: TextSelection(
            baseOffset: sel.start,
            extentOffset: sel.start + unwrapped.length,
          ),
        );
        return;
      }

      // Check if delimiter immediately surrounds the selection
      if (sel.start >= dLen && sel.end <= fullText.length - dLen) {
        final before = fullText.substring(sel.start - dLen, sel.start);
        final after = fullText.substring(sel.end, sel.end + dLen);
        if (before == delimiter && after == delimiter) {
          // Remove outer delimiters
          final newText = fullText
              .replaceRange(sel.end, sel.end + dLen, '')
              .replaceRange(sel.start - dLen, sel.start, '');
          value = TextEditingValue(
            text: newText,
            selection: TextSelection(
              baseOffset: sel.start - dLen,
              extentOffset: sel.end - dLen,
            ),
          );
          return;
        }
      }

      // Not wrapped: wrap it now
      final wrapped = '$delimiter$selectedText$delimiter';
      final newText = fullText.replaceRange(sel.start, sel.end, wrapped);
      value = TextEditingValue(
        text: newText,
        selection: TextSelection(
          baseOffset: sel.start,
          extentOffset: sel.start + wrapped.length,
        ),
      );
      return;
    }

    // 2. Cursor is collapsed (no selection)
    final pos = sel.isValid ? sel.start : fullText.length;

    // Check if cursor is resting inside a formatted word on the current line
    final lineStart = fullText.lastIndexOf('\n', pos > 0 ? pos - 1 : 0) + 1;
    final nextNewline = fullText.indexOf('\n', pos);
    final lineEnd = nextNewline == -1 ? fullText.length : nextNewline;
    final currentLine = fullText.substring(lineStart, lineEnd);
    final relativePos = pos - lineStart;

    final escapedDelimiter = RegExp.escape(delimiter);
    final pattern = RegExp('$escapedDelimiter[^\\n]+?$escapedDelimiter');
    for (final match in pattern.allMatches(currentLine)) {
      if (relativePos >= match.start && relativePos <= match.end) {
        // Cursor is inside this token: unwrap it!
        final matchStart = lineStart + match.start;
        final matchEnd = lineStart + match.end;
        final inner = currentLine.substring(match.start + dLen, match.end - dLen);
        final newText = fullText.replaceRange(matchStart, matchEnd, inner);
        value = TextEditingValue(
          text: newText,
          selection: TextSelection.collapsed(offset: matchStart + inner.length),
        );
        return;
      }
    }

    // Otherwise, insert placeholder and select it
    final insert = '$delimiter$placeholder$delimiter';
    final newText = fullText.replaceRange(pos, pos, insert);
    value = TextEditingValue(
      text: newText,
      selection: TextSelection(
        baseOffset: pos + dLen,
        extentOffset: pos + dLen + placeholder.length,
      ),
    );
  }

  void _toggleLinePrefix({required String prefix}) {
    final fullText = text;
    final sel = selection;
    final pos = sel.isValid ? sel.start : fullText.length;

    final lineStart = fullText.lastIndexOf('\n', pos > 0 ? pos - 1 : 0) + 1;
    final nextNewline = fullText.indexOf('\n', pos);
    final lineEnd = nextNewline == -1 ? fullText.length : nextNewline;
    final currentLine = fullText.substring(lineStart, lineEnd);

    if (currentLine.startsWith(prefix)) {
      // Remove prefix
      final stripped = currentLine.substring(prefix.length);
      final newText = fullText.replaceRange(lineStart, lineEnd, stripped);
      final newPos = (pos - prefix.length).clamp(lineStart, lineStart + stripped.length);
      value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: newPos),
      );
    } else {
      // Add prefix
      final updated = '$prefix$currentLine';
      final newText = fullText.replaceRange(lineStart, lineEnd, updated);
      final newPos = pos + prefix.length;
      value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: newPos),
      );
    }
  }
}
