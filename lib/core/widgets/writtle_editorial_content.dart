import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Core parser for Writtle editorial formatting and preview rendering.
/// Parses author markdown extensions:
/// - `==highlighted text==` -> Authentic Stabilo canary yellow highlighter styling
/// - `> quote` or `| quote` -> Elegant pull-quote / standfirst with vertical burnt sienna accent bar
/// - `## Heading` or `### Subheading` -> Section subheadings
/// - `**bold**` & `*italic*` -> Inline font weights and styles
class WrittleEditorialParser {
  static final RegExp _inlinePattern = RegExp(r'(==[\s\S]+?==|\*\*[\s\S]+?\*\*|\*[\s\S]+?\*)');
  static final RegExp _headingMarkerRegex = RegExp(r'^#{2,3}\s*');
  static final RegExp _quoteOrHeadingMarkerRegex = RegExp(r'^(>|\|\t?|#+)\s*');

  /// Parses inline tokens: ==stabilo==, **bold**, *italic*
  static List<InlineSpan> parseInlineSpans(
    String text,
    TextStyle baseStyle, {
    required bool isDark,
  }) {
    final spans = <InlineSpan>[];

    // Stabilo Highlighter colors:
    // Light mode: Vibrant, soft canary yellow highlighter marker (#FFF275)
    // Dark mode: Deep golden amber (#EAB308)
    final stabiloBgColor = isDark
        ? const Color(0xFFEAB308).withValues(alpha: 0.35)
        : const Color(0xFFFFF275);

    final stabiloTextColor = isDark
        ? const Color(0xFFFEF9C3)
        : const Color(0xFF1E140C);

    int lastMatchEnd = 0;

    for (final match in _inlinePattern.allMatches(text)) {
      if (match.start > lastMatchEnd) {
        spans.add(TextSpan(
          text: text.substring(lastMatchEnd, match.start),
          style: baseStyle,
        ));
      }

      final matchStr = match.group(0)!;

      if (matchStr.startsWith('==') && matchStr.endsWith('==') && matchStr.length >= 4) {
        final innerText = matchStr.substring(2, matchStr.length - 2);
        spans.add(TextSpan(
          text: innerText,
          style: baseStyle.copyWith(
            backgroundColor: stabiloBgColor,
            color: stabiloTextColor,
            fontWeight: FontWeight.w600,
          ),
        ));
      } else if (matchStr.startsWith('**') && matchStr.endsWith('**') && matchStr.length >= 4) {
        final innerText = matchStr.substring(2, matchStr.length - 2);
        spans.add(TextSpan(
          text: innerText,
          style: baseStyle.copyWith(fontWeight: FontWeight.bold),
        ));
      } else if (matchStr.startsWith('*') && matchStr.endsWith('*') && matchStr.length >= 2) {
        final innerText = matchStr.substring(1, matchStr.length - 1);
        spans.add(TextSpan(
          text: innerText,
          style: baseStyle.copyWith(fontStyle: FontStyle.italic),
        ));
      }

      lastMatchEnd = match.end;
    }

    if (lastMatchEnd < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastMatchEnd),
        style: baseStyle,
      ));
    }

    return spans;
  }

  /// Extracts the subtitle / subjudul for story cards (Home Feed & Profile).
  /// 1. If author explicitly used `## ` or `### ` Subjudul, extracts that clean subjudul.
  /// 2. Otherwise, extracts the first non-empty narrative line (cleaned of quote or heading markers).
  static String extractSubtitle(String content) {
    if (content.trim().isEmpty) return '';
    final lines = content.trim().split('\n');

    // 1. Check for explicit subjudul (## or ###)
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.startsWith('## ') || trimmed.startsWith('### ')) {
        return trimmed.replaceFirst(_headingMarkerRegex, '').trim();
      }
    }

    // 2. Fall back to first non-empty line
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isNotEmpty) {
        return trimmed.replaceFirst(_quoteOrHeadingMarkerRegex, '').trim();
      }
    }

    return '';
  }

  /// Builds a rendered Story Title widget with inline formatting support (e.g. stabilo).
  static Widget buildTitle(
    String title,
    TextStyle style, {
    required bool isDark,
    int maxLines = 2,
  }) {
    return Text.rich(
      TextSpan(
        children: parseInlineSpans(title, style, isDark: isDark),
      ),
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
    );
  }

  /// Builds a rendered Subtitle / Subjudul widget with inline writing styles (canary yellow stabilo, bold, italic).
  static Widget buildSubtitle(
    String content,
    TextStyle style, {
    required bool isDark,
    int maxLines = 2,
  }) {
    final subtitle = extractSubtitle(content);
    return Text.rich(
      TextSpan(
        children: parseInlineSpans(subtitle, style, isDark: isDark),
      ),
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
    );
  }
}

/// Editorial Content Parser & Renderer for Preview and Reader screens.
class WrittleEditorialContent extends StatelessWidget {
  final String content;
  final TextStyle? defaultStyle;
  final bool isSelectable;

  const WrittleEditorialContent({
    super.key,
    required this.content,
    this.defaultStyle,
    this.isSelectable = true,
  });

  @override
  Widget build(BuildContext context) {
    if (content.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseStyle = defaultStyle ??
        AppTypography.storyBody.copyWith(
          fontSize: 17,
          height: 1.85,
          color: AppColors.textPrimaryColor(context),
        );

    final lines = content.split('\n');
    final widgets = <Widget>[];

    int i = 0;
    while (i < lines.length) {
      final line = lines[i];
      final trimmed = line.trim();

      if (trimmed.isEmpty) {
        if (widgets.isNotEmpty && widgets.last is! SizedBox) {
          widgets.add(const SizedBox(height: 14));
        }
        i++;
        continue;
      }

      // 1. Heading (#, ##, ###)
      if (trimmed.startsWith('### ')) {
        final headingText = trimmed.substring(4).trim();
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: 14, bottom: 6),
          child: Text.rich(
            TextSpan(
              children: WrittleEditorialParser.parseInlineSpans(
                headingText,
                AppTypography.storyHeading.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimaryColor(context),
                ),
                isDark: isDark,
              ),
            ),
          ),
        ));
        i++;
        continue;
      }

      if (trimmed.startsWith('## ')) {
        final headingText = trimmed.substring(3).trim();
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: 18, bottom: 8),
          child: Text.rich(
            TextSpan(
              children: WrittleEditorialParser.parseInlineSpans(
                headingText,
                AppTypography.storyHeading.copyWith(
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                  height: 1.3,
                  color: AppColors.textPrimaryColor(context),
                ),
                isDark: isDark,
              ),
            ),
          ),
        ));
        i++;
        continue;
      }

      if (trimmed.startsWith('# ')) {
        final headingText = trimmed.substring(2).trim();
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: 20, bottom: 10),
          child: Text.rich(
            TextSpan(
              children: WrittleEditorialParser.parseInlineSpans(
                headingText,
                AppTypography.storyHeading.copyWith(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  height: 1.25,
                  color: AppColors.textPrimaryColor(context),
                ),
                isDark: isDark,
              ),
            ),
          ),
        ));
        i++;
        continue;
      }

      // 2. Quote block (> or |)
      if (trimmed.startsWith('> ') || trimmed.startsWith('|\t') || trimmed.startsWith('| ')) {
        final quoteLines = <String>[];
        while (i < lines.length) {
          final qLine = lines[i].trim();
          if (qLine.startsWith('> ')) {
            quoteLines.add(qLine.substring(2).trim());
            i++;
          } else if (qLine.startsWith('|\t') || qLine.startsWith('| ')) {
            quoteLines.add(qLine.substring(1).trim());
            i++;
          } else if (qLine.isEmpty || qLine.startsWith('#')) {
            break;
          } else {
            quoteLines.add(qLine);
            i++;
          }
        }

        final fullQuote = quoteLines.join('\n');
        widgets.add(
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10),
            padding: const EdgeInsets.fromLTRB(16, 12, 14, 12),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.softParchment.withValues(alpha: 0.06)
                  : AppColors.softParchment.withValues(alpha: 0.55),
              border: const Border(
                left: BorderSide(
                  color: AppColors.burntSienna,
                  width: 3.5,
                ),
              ),
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(8),
                bottomRight: Radius.circular(8),
              ),
            ),
            child: Text.rich(
              TextSpan(
                children: WrittleEditorialParser.parseInlineSpans(
                  fullQuote,
                  baseStyle.copyWith(
                    fontSize: 16.5,
                    fontStyle: FontStyle.italic,
                    height: 1.65,
                    color: AppColors.textPrimaryColor(context),
                  ),
                  isDark: isDark,
                ),
              ),
            ),
          ),
        );
        continue;
      }

      // 3. Regular paragraph
      final paragraphLines = <String>[];
      while (i < lines.length) {
        final pLine = lines[i];
        final pTrimmed = pLine.trim();
        if (pTrimmed.isEmpty ||
            pTrimmed.startsWith('#') ||
            pTrimmed.startsWith('> ') ||
            pTrimmed.startsWith('| ') ||
            pTrimmed.startsWith('|\t')) {
          break;
        }
        paragraphLines.add(pLine);
        i++;
      }

      if (paragraphLines.isNotEmpty) {
        final paragraphText = paragraphLines.join('\n');
        final spans = WrittleEditorialParser.parseInlineSpans(paragraphText, baseStyle, isDark: isDark);
        widgets.add(Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text.rich(
            TextSpan(children: spans),
          ),
        ));
      }
    }

    final contentWidget = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );

    if (isSelectable) {
      return SelectionArea(child: contentWidget);
    }
    return contentWidget;
  }
}
