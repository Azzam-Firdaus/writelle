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
        color: isAnonymous ? AppColors.surfaceWarmColor(context) : AppColors.surface(context),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isAnonymous
              ? AppColors.burntSienna.withValues(alpha: 0.3)
              : AppColors.borderColor(context),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isAnonymous
                  ? AppColors.burntSienna.withValues(alpha: 0.12)
                  : AppColors.surfaceWarmColor(context),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isAnonymous ? Icons.shield_outlined : Icons.edit_note_outlined,
              size: 20,
              color: isAnonymous ? AppColors.burntSienna : AppColors.textPrimaryColor(context),
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
                    color: AppColors.textPrimaryColor(context),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isAnonymous
                      ? 'Your name and profile remain completely private.'
                      : 'Your story will be linked to your pen name alias.',
                  style: AppTypography.captionMeta.copyWith(
                    color: AppColors.textSecondaryColor(context),
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: isAnonymous,
            activeTrackColor: AppColors.burntSienna,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
