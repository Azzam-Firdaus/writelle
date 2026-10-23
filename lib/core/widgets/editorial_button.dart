import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

enum EditorialButtonVariant { primary, secondary, outlined, text }

/// A reusable button styled for Editorial Minimalism.
class EditorialButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final EditorialButtonVariant variant;
  final bool isLoading;
  final Widget? icon;
  final double? width;

  const EditorialButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = EditorialButtonVariant.primary,
    this.isLoading = false,
    this.icon,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveOnPressed = isLoading ? null : onPressed;

    Widget childContent = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading) ...[
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                variant == EditorialButtonVariant.primary
                    ? AppColors.backgroundLight
                    : AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ] else if (icon != null) ...[
          icon!,
          const SizedBox(width: 8),
        ],
        Text(
          label,
          style: AppTypography.buttonText.copyWith(
            color: _getTextColor(),
          ),
        ),
      ],
    );

    Widget button;
    switch (variant) {
      case EditorialButtonVariant.primary:
        button = ElevatedButton(
          onPressed: effectiveOnPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.textPrimary,
            foregroundColor: AppColors.backgroundLight,
            minimumSize: const Size(88, 48),
          ),
          child: childContent,
        );
        break;
      case EditorialButtonVariant.secondary:
        button = ElevatedButton(
          onPressed: effectiveOnPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accentPrimary,
            foregroundColor: Colors.white,
            minimumSize: const Size(88, 48),
          ),
          child: childContent,
        );
        break;
      case EditorialButtonVariant.outlined:
        button = OutlinedButton(
          onPressed: effectiveOnPressed,
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: AppColors.borderLight),
            minimumSize: const Size(88, 48),
          ),
          child: childContent,
        );
        break;
      case EditorialButtonVariant.text:
        button = TextButton(
          onPressed: effectiveOnPressed,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.textPrimary,
            minimumSize: const Size(64, 44),
          ),
          child: childContent,
        );
        break;
    }

    if (width != null) {
      return SizedBox(width: width, child: button);
    }
    return button;
  }

  Color _getTextColor() {
    switch (variant) {
      case EditorialButtonVariant.primary:
        return AppColors.backgroundLight;
      case EditorialButtonVariant.secondary:
        return Colors.white;
      case EditorialButtonVariant.outlined:
      case EditorialButtonVariant.text:
        return AppColors.textPrimary;
    }
  }
}
