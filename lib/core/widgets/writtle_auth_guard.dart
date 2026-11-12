import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../../providers/auth_provider.dart';
import '../../screens/auth/login_screen.dart';

/// Guard and presentation helper for restricting guest actions in Writelle.
/// When guest users try to perform member interactions (like, save, comment, write),
/// this displays a refined tactile dialog inviting them to sign in or create an account.
class WrittleAuthGuard {
  /// Checks if the current user is authenticated.
  /// If authenticated, returns true.
  /// If unauthenticated (guest), presents the auth prompt dialog and returns false.
  static bool check(
    BuildContext context,
    WidgetRef ref, {
    String? title,
    String? message,
    VoidCallback? onSuccess,
  }) {
    final isAuth = ref.read(isAuthenticatedProvider);
    if (isAuth) {
      return true;
    }

    showAuthPrompt(
      context,
      title: title,
      message: message,
      onSuccess: onSuccess,
    );
    return false;
  }

  /// Displays the official Writelle Auth Prompt dialog.
  static void showAuthPrompt(
    BuildContext context, {
    String? title,
    String? message,
    VoidCallback? onSuccess,
  }) {
    showDialog(
      context: context,
      builder: (dialogCtx) => _WrittleAuthDialog(
        title: title ?? 'Sign in to Writelle',
        message: message ??
            'Please sign in or create an account to like, bookmark, or write stories in Writelle.',
        onSuccess: onSuccess,
      ),
    );
  }
}

class _WrittleAuthDialog extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onSuccess;

  const _WrittleAuthDialog({
    required this.title,
    required this.message,
    this.onSuccess,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: AppColors.borderColor(context), width: 1),
      ),
      contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.burntSienna.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.auto_stories_rounded,
              color: AppColors.burntSienna,
              size: 28,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTypography.storyHeading.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimaryColor(context),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTypography.uiBody.copyWith(
              color: AppColors.textSecondaryColor(context),
              fontSize: 13.5,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    'Maybe Later',
                    style: TextStyle(
                      color: AppColors.textSecondaryColor(context),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.burntSienna,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () async {
                    Navigator.of(context).pop();
                    final loggedIn = await Navigator.of(context).push<bool>(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    );
                    if (loggedIn == true && onSuccess != null) {
                      onSuccess!();
                    }
                  },
                  child: const Text(
                    'Sign In / Join',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
