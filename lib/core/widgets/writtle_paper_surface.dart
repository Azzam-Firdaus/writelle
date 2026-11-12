import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

enum PaperSurfaceVariant {
  /// Pure crisp white surface with warm hairline border and soft shadow
  white,

  /// Soft warm parchment tone (#F0E8DB)
  parchment,

  /// Warm sand tone (#E5D4BE) for callouts, stats, badges
  sand,

  /// Dark luxury espresso panel (#261D17) for dramatic contrast
  espresso,

  /// Transparent with subtle editorial border
  bordered,
}

/// A tactile paper-inspired surface for cards, banners, and editorial sections.
class WrittlePaperSurface extends StatelessWidget {
  final Widget child;
  final PaperSurfaceVariant variant;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final VoidCallback? onTap;
  final bool hasShadow;
  final Border? customBorder;

  const WrittlePaperSurface({
    super.key,
    required this.child,
    this.variant = PaperSurfaceVariant.white,
    this.padding,
    this.margin,
    this.borderRadius = 14.0,
    this.onTap,
    this.hasShadow = true,
    this.customBorder,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color backgroundColor;
    Color borderColor;
    List<BoxShadow>? shadows;

    switch (variant) {
      case PaperSurfaceVariant.white:
        backgroundColor = isDark ? AppColors.surfaceDark : AppColors.pureWhite;
        borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
        if (hasShadow && !isDark) {
          shadows = [
            BoxShadow(
              color: AppColors.espresso.withValues(alpha: 0.04),
              offset: const Offset(0, 4),
              blurRadius: 16,
            ),
            BoxShadow(
              color: AppColors.warmSand.withValues(alpha: 0.25),
              offset: const Offset(0, 1),
              blurRadius: 4,
            ),
          ];
        }

      case PaperSurfaceVariant.parchment:
        backgroundColor = isDark ? const Color(0xFF221A15) : AppColors.softParchment;
        borderColor = isDark ? AppColors.borderDark : const Color(0xFFE2D7C8);
        if (hasShadow && !isDark) {
          shadows = [
            BoxShadow(
              color: AppColors.espresso.withValues(alpha: 0.03),
              offset: const Offset(0, 3),
              blurRadius: 12,
            ),
          ];
        }

      case PaperSurfaceVariant.sand:
        backgroundColor = isDark ? const Color(0xFF2E221B) : AppColors.warmSand.withValues(alpha: 0.65);
        borderColor = isDark ? AppColors.borderDark : const Color(0xFFDAC7B0);

      case PaperSurfaceVariant.espresso:
        backgroundColor = AppColors.espresso;
        borderColor = isDark ? const Color(0xFF3F3025) : const Color(0xFF382B22);
        if (hasShadow) {
          shadows = [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              offset: const Offset(0, 6),
              blurRadius: 20,
              spreadRadius: -2,
            ),
          ];
        }

      case PaperSurfaceVariant.bordered:
        backgroundColor = Colors.transparent;
        borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    }

    final decoration = BoxDecoration(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(borderRadius),
      border: customBorder ?? Border.all(color: borderColor, width: 1.0),
      boxShadow: shadows,
    );

    Widget content = Container(
      margin: margin,
      decoration: decoration,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Padding(
          padding: padding ?? const EdgeInsets.all(16.0),
          child: child,
        ),
      ),
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          child: content,
        ),
      );
    }

    return content;
  }
}
