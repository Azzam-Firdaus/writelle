import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'writtle_paper_surface.dart';

/// Reusable literary empty state widget with layered organic parchment styling.
class EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: WrittlePaperSurface(
          variant: PaperSurfaceVariant.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
          borderRadius: 16,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Layered organic icon circle
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.softParchment,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.warmSand,
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: Icon(
                    icon,
                    size: 26,
                    color: AppColors.burntSienna,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Title
              Text(
                title,
                textAlign: TextAlign.center,
                style: AppTypography.storyHeading.copyWith(
                  fontSize: 17,
                  letterSpacing: -0.2,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimaryColor(context),
                ),
              ),
              const SizedBox(height: 6),

              // Poetic Message
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 300),
                child: Text(
                  message,
                  textAlign: TextAlign.center,
                  style: AppTypography.uiBody.copyWith(
                    color: AppColors.textSecondaryColor(context),
                    height: 1.45,
                    fontSize: 12.5,
                  ),
                ),
              ),

              if (action != null) ...[
                const SizedBox(height: 16),
                action!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
