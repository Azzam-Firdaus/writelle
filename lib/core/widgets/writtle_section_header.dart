import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Literary section header with kicker eyebrow, serif title, and optional action link.
class WrittleSectionHeader extends StatelessWidget {
  final String? kicker;
  final String title;
  final String? subtitle;
  final String? actionText;
  final VoidCallback? onActionTap;
  final EdgeInsetsGeometry padding;

  const WrittleSectionHeader({
    super.key,
    this.kicker,
    required this.title,
    this.subtitle,
    this.actionText,
    this.onActionTap,
    this.padding = const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (kicker != null && kicker!.isNotEmpty) ...[
                  Row(
                    children: [
                      Container(
                        width: 14,
                        height: 2,
                        decoration: BoxDecoration(
                          color: AppColors.burntSienna,
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        kicker!.toUpperCase(),
                        style: AppTypography.kicker,
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                ],
                Text(
                  title,
                  style: AppTypography.storyHeading.copyWith(
                    fontSize: 21,
                    letterSpacing: -0.3,
                    color: AppColors.textPrimaryColor(context),
                  ),
                ),
                if (subtitle != null && subtitle!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: AppTypography.captionMeta.copyWith(
                      color: AppColors.textSecondaryColor(context),
                      height: 1.35,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (actionText != null && onActionTap != null)
            InkWell(
              onTap: onActionTap,
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      actionText!,
                      style: AppTypography.uiBody.copyWith(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.burntSienna,
                      ),
                    ),
                    const SizedBox(width: 3),
                    const Icon(
                      Icons.arrow_forward_ios,
                      size: 11,
                      color: AppColors.burntSienna,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
