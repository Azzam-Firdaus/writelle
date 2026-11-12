import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

enum EditorialButtonVariant { primary, secondary, outlined, text }

/// A reusable tactile button styled for Editorial Luxury.
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
                    ? AppColors.warmIvory
                    : AppColors.espresso,
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
            color: _getTextColor(context),
            fontWeight: FontWeight.w600,
            fontSize: 13.5,
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
            backgroundColor: AppColors.burntSienna,
            foregroundColor: Colors.white,
            elevation: 0,
            minimumSize: const Size(88, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: childContent,
        );

      case EditorialButtonVariant.secondary:
        button = ElevatedButton(
          onPressed: effectiveOnPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.espresso,
            foregroundColor: AppColors.warmIvory,
            elevation: 0,
            minimumSize: const Size(88, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: childContent,
        );

      case EditorialButtonVariant.outlined:
        button = OutlinedButton(
          onPressed: effectiveOnPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.textPrimaryColor(context),
            side: BorderSide(color: AppColors.borderColor(context), width: 1.5),
            minimumSize: const Size(88, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: childContent,
        );

      case EditorialButtonVariant.text:
        button = TextButton(
          onPressed: effectiveOnPressed,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.burntSienna,
            minimumSize: const Size(64, 44),
          ),
          child: childContent,
        );
    }

    if (width != null) {
      return SizedBox(width: width, child: button);
    }

    return button;
  }

  Color _getTextColor(BuildContext context) {
    switch (variant) {
      case EditorialButtonVariant.primary:
        return Colors.white;
      case EditorialButtonVariant.secondary:
        return AppColors.warmIvory;
      case EditorialButtonVariant.outlined:
        return AppColors.textPrimaryColor(context);
      case EditorialButtonVariant.text:
        return AppColors.burntSienna;
    }
  }
}
