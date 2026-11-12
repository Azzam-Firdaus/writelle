import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import '../utils/editorial_text_controller.dart';

/// Sleek Keyboard Accessory Toolbar docked directly above the virtual soft keyboard.
/// Inspired by Substack, Apple Notes, and Bear.
/// Provides immediate, single-thumb access to formatting tools while typing:
/// - 🖍️ Stabilo (Live Canary Yellow Highlighter)
/// - ❝ Kutipan (Pull-Quote Standfirst)
/// - H Subjudul (Editorial Subheading)
/// - B Tebal (Bold)
/// - I Miring (Italic)
/// - ⌨ Sembunyikan (Keyboard Dismiss)
class WrittleKeyboardAccessoryBar extends StatelessWidget {
  final WrittleEditorialTextController controller;
  final VoidCallback? onDismissKeyboard;

  const WrittleKeyboardAccessoryBar({
    super.key,
    required this.controller,
    this.onDismissKeyboard,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1815) : AppColors.pureWhite,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.warmSand.withValues(alpha: 0.2) : AppColors.warmSand,
            width: 1.0,
          ),
          bottom: BorderSide(
            color: isDark ? Colors.black38 : AppColors.warmSand.withValues(alpha: 0.3),
            width: 0.8,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
            blurRadius: 6,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Scrollable tools
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                children: [
                  // 1. Stabilo Button (Vibrant Canary Yellow Pill)
                  _buildToolButton(
                    context: context,
                    icon: Icons.border_color,
                    label: 'Stabilo',
                    tooltip: 'Sorot teks pilihan dengan stabilo (==teks==)',
                    isStabilo: true,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      controller.toggleStabilo();
                    },
                  ),
                  const SizedBox(width: 6),

                  // 2. Kutipan (Quote) Button
                  _buildToolButton(
                    context: context,
                    icon: Icons.format_quote_rounded,
                    label: 'Kutipan',
                    tooltip: 'Jadikan kutipan dengan garis aksen (> kutipan)',
                    onTap: () {
                      HapticFeedback.lightImpact();
                      controller.toggleQuote();
                    },
                  ),
                  const SizedBox(width: 6),

                  // 3. Subjudul (Heading) Button
                  _buildToolButton(
                    context: context,
                    icon: Icons.title_rounded,
                    label: 'Subjudul',
                    tooltip: 'Tambah subjudul bagian (## Judul)',
                    onTap: () {
                      HapticFeedback.lightImpact();
                      controller.toggleHeading();
                    },
                  ),
                  const SizedBox(width: 6),

                  // 4. Tebal (Bold) Button
                  _buildToolButton(
                    context: context,
                    icon: Icons.format_bold_rounded,
                    label: 'Tebal',
                    tooltip: 'Format teks tebal (**teks**)',
                    onTap: () {
                      HapticFeedback.lightImpact();
                      controller.toggleBold();
                    },
                  ),
                  const SizedBox(width: 6),

                  // 5. Miring (Italic) Button
                  _buildToolButton(
                    context: context,
                    icon: Icons.format_italic_rounded,
                    label: 'Miring',
                    tooltip: 'Format teks miring (*teks*)',
                    onTap: () {
                      HapticFeedback.lightImpact();
                      controller.toggleItalic();
                    },
                  ),
                ],
              ),
            ),
          ),

          // Divider
          Container(
            height: 24,
            width: 1,
            color: AppColors.warmSand.withValues(alpha: isDark ? 0.25 : 0.6),
          ),

          // Dismiss Keyboard Button
          Tooltip(
            message: 'Dismiss Keyboard',
            child: InkWell(
              onTap: () {
                HapticFeedback.selectionClick();
                if (onDismissKeyboard != null) {
                  onDismissKeyboard!();
                } else {
                  FocusScope.of(context).unfocus();
                }
              },
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Icon(
                  Icons.keyboard_hide_outlined,
                  size: 20,
                  color: isDark ? AppColors.warmSand : AppColors.mutedCocoa,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String tooltip,
    required VoidCallback onTap,
    bool isStabilo = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = isStabilo
        ? (isDark ? const Color(0xFF854D0E).withValues(alpha: 0.5) : const Color(0xFFFEF08A))
        : (isDark ? Colors.white.withValues(alpha: 0.08) : AppColors.softParchment.withValues(alpha: 0.65));

    final borderColor = isStabilo
        ? const Color(0xFFEAB308)
        : AppColors.warmSand.withValues(alpha: isDark ? 0.3 : 0.5);

    final textColor = isStabilo
        ? (isDark ? const Color(0xFFFEF08A) : const Color(0xFF854D0E))
        : (isDark ? Colors.white : AppColors.espresso);

    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: borderColor, width: 1.1),
              boxShadow: isStabilo
                  ? [
                      BoxShadow(
                        color: const Color(0xFFEAB308).withValues(alpha: isDark ? 0.25 : 0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      )
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 15, color: textColor),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: isStabilo ? FontWeight.bold : FontWeight.w600,
                    color: textColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
