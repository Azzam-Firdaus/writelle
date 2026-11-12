import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Pill-style editorial category chip with tactile paper styling.
class CategoryChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const CategoryChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.burntSienna
                  : (isDark ? const Color(0xFF261D17) : AppColors.softParchment),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: isSelected
                    ? AppColors.burntSienna
                    : (isDark ? AppColors.borderDark : const Color(0xFFE2D6C5)),
                width: 1.2,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppColors.burntSienna.withValues(alpha: 0.28),
                        offset: const Offset(0, 2),
                        blurRadius: 8,
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isSelected) ...[
                  const Icon(Icons.circle, size: 6, color: Colors.white),
                  const SizedBox(width: 6),
                ],
                Text(
                  label,
                  style: AppTypography.uiBody.copyWith(
                    fontSize: 12.5,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    letterSpacing: isSelected ? 0.2 : 0,
                    color: isSelected
                        ? Colors.white
                        : (isDark ? AppColors.textPrimaryDark : AppColors.espresso),
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
