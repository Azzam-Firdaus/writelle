import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Reassuring toggle banner for selecting between Anonymous and Pen Name mode.
/// Ref: docs/BUSINESS_AND_SYSTEM_DESIGN.md (BR-002, BR-003) and docs/UI_UX_DESIGN.md
class AnonymityToggle extends StatelessWidget {
  final bool isAnonymous;
  final String penName;
  final ValueChanged<bool> onChanged;

  const AnonymityToggle({
    super.key,
    required this.isAnonymous,
    required this.penName,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isAnonymous ? AppColors.surfaceWarm : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isAnonymous ? AppColors.accentSubtle.withValues(alpha: 0.4) : AppColors.borderLight,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isAnonymous
                  ? AppColors.accentPrimary.withValues(alpha: 0.12)
                  : AppColors.surfaceWarm,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isAnonymous ? Icons.shield_outlined : Icons.edit_note_outlined,
              size: 20,
              color: isAnonymous ? AppColors.accentPrimary : AppColors.textPrimary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isAnonymous ? 'Publishing Anonymously' : 'Publishing as $penName',
                  style: AppTypography.uiBodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isAnonymous
                      ? 'Your name and profile remain completely private.'
                      : 'Your story will be linked to your pen name alias.',
                  style: AppTypography.captionMeta.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: isAnonymous,
            activeThumbColor: AppColors.accentPrimary,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
