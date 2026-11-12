import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'story_cover_image.dart';
import 'writtle_action_pills.dart';
import 'writtle_auth_guard.dart';
import 'writtle_avatar.dart';
import 'writtle_editorial_content.dart';
import 'writtle_paper_surface.dart';
import '../../models/story_model.dart';
import '../../providers/auth_provider.dart';
import '../../screens/profile/public_profile_screen.dart';

/// Redesigned Editorial Story Card matching modern literary feed standards (Image 2).
/// Features:
/// - Author header row with circular avatar, pen name, and publication meta
/// - Two-column body with prominent editorial title & excerpt on left, compact square thumbnail on right
/// - Clean bottom row displaying curated like count and comments count
class StoryCard extends StatelessWidget {
  final StoryModel story;
  final VoidCallback onTap;
  final VoidCallback? onBookmarkTap;
  final VoidCallback? onBookmarkToggle;
  final Widget? trailing;
  final VoidCallback? onLikeTap;
  final bool? showBookmark;
  final bool showActions;
  final bool? isAuthenticated;

  const StoryCard({
    super.key,
    required this.story,
    required this.onTap,
    this.onBookmarkTap,
    this.onBookmarkToggle,
    this.onLikeTap,
    this.showBookmark,
    this.showActions = true,
    this.isAuthenticated,
    this.trailing,
  });

  void _onAuthorTapped(BuildContext context) {
    if (story.isAnonymous) {
      showModalBottomSheet(
        context: context,
        backgroundColor: AppColors.surface(context),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (ctx) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.surfaceWarmColor(context),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.shield_outlined, color: AppColors.textSecondaryColor(context), size: 26),
              ),
              const SizedBox(height: 14),
              Text(
                'Veiled in Anonymity',
                style: AppTypography.storyHeading.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimaryColor(context),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'This author chose to share this tale under a cloak of quiet silence. Their identity remains sheltered in Writtle.',
                textAlign: TextAlign.center,
                style: AppTypography.uiBody.copyWith(color: AppColors.textSecondaryColor(context), height: 1.45),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      );
    } else {
      if (story.userId == null || story.userId!.isEmpty) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PublicProfileScreen(
            authorId: story.userId!,
            initialPenName: story.authorName,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final readingTime = story.readingTime;
    final hasCover = story.coverUrl != null && story.coverUrl!.trim().isNotEmpty;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    bool isAuth = isAuthenticated ?? false;
    if (isAuthenticated == null) {
      try {
        final container = ProviderScope.containerOf(context, listen: false);
        isAuth = container.read(isAuthenticatedProvider);
      } catch (_) {
        isAuth = true; // Fallback for standalone widget tests without ProviderScope
      }
    }

    // Determine whether to display the bookmark pill:
    final bool shouldDisplayBookmark = showActions && (showBookmark ?? (onBookmarkTap != null || onBookmarkToggle != null));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 5.0),
      child: WrittlePaperSurface(
        variant: PaperSurfaceVariant.white,
        padding: const EdgeInsets.all(14.0),
        borderRadius: 14,
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Top Header Row: Author info on left, Category badge & Trailing menu on right (Always visible)
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _onAuthorTapped(context),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (story.isAnonymous)
                          CircleAvatar(
                            radius: 11,
                            backgroundColor: AppColors.warmSand.withValues(alpha: isDark ? 0.3 : 0.6),
                            child: const Icon(
                              Icons.shield_outlined,
                              size: 13,
                              color: AppColors.burntSienna,
                            ),
                          )
                        else
                          WrittleAvatar(
                            avatarUrl: story.authorAvatarUrl,
                            radius: 11,
                            fallbackInitial: story.authorName.isNotEmpty ? story.authorName[0] : 'W',
                          ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            story.authorName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.captionMeta.copyWith(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimaryColor(context),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Category Badge (always displayed on every story card)
                if (story.categoryName.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                    decoration: BoxDecoration(
                      color: AppColors.burntSienna.withValues(alpha: isDark ? 0.16 : 0.08),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: AppColors.burntSienna.withValues(alpha: isDark ? 0.35 : 0.20),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      story.categoryName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.captionMeta.copyWith(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.burntSienna,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),

                if (trailing != null) ...[
                  const SizedBox(width: 4),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {},
                    child: trailing!,
                  ),
                ],
              ],
            ),
            const SizedBox(height: 10),

            // 2. Middle Content Row: Editorial Title + Excerpt (Left) & Square Thumbnail (Right)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Column: Title & Excerpt
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Judul (Story Title)
                      WrittleEditorialParser.buildTitle(
                        story.title,
                        AppTypography.storyHeading.copyWith(
                          fontSize: 16.5,
                          fontWeight: FontWeight.bold,
                          height: 1.28,
                          letterSpacing: -0.2,
                          color: AppColors.textPrimaryColor(context),
                        ),
                        isDark: isDark,
                        maxLines: 2,
                      ),
                      const SizedBox(height: 6),
                      // Subjudul (Story Subtitle / Excerpt with writing styles)
                      WrittleEditorialParser.buildSubtitle(
                        story.content,
                        AppTypography.uiBody.copyWith(
                          fontSize: 13,
                          height: 1.45,
                          color: AppColors.textSecondaryColor(context),
                        ),
                        isDark: isDark,
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),

                // Right Column: Square Thumbnail Image (Image 2 style: 74x74)
                if (hasCover) ...[
                  const SizedBox(width: 14),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(9),
                    child: SizedBox(
                      width: 74,
                      height: 74,
                      child: StoryCoverImage(
                        coverUrl: story.coverUrl,
                        fit: BoxFit.cover,
                        cacheWidth: 220,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),

            // 3. Bottom Row: Reading Time Badge & Like/Comment Stats
            Row(
              children: [
                // Reading Time Meta
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.softParchment.withValues(alpha: 0.08)
                        : AppColors.softParchment.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: AppColors.warmSand.withValues(alpha: isDark ? 0.2 : 0.4),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.schedule,
                        size: 11,
                        color: AppColors.textSecondaryColor(context),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        readingTime,
                        style: AppTypography.captionMeta.copyWith(
                          fontSize: 10.5,
                          color: AppColors.textSecondaryColor(context),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Spacer(),

                // Action buttons (only shown if showActions is true, e.g. hidden on drafts)
                if (showActions)
                  Flexible(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {}, // Blocks tap propagation to outer card InkWell
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerRight,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Interactive Like Pill with Bouncy Heart Animation
                              WrittleLikePill(
                                key: ValueKey('like_${story.id}'),
                                isLiked: story.isLiked,
                                likesCount: story.likesCount,
                                onBeforeTap: () => isAuth,
                                onTap: () {
                                  if (!isAuth) {
                                    WrittleAuthGuard.showAuthPrompt(
                                      context,
                                      title: 'Like Story',
                                      message: 'Please sign in or create an account to like this story.',
                                    );
                                    return;
                                  }
                                  onLikeTap?.call();
                                },
                                isCompact: true,
                              ),

                              // Optional Bookmark Pill (only shown when requested or on keepsakes screen)
                              if (shouldDisplayBookmark && (onBookmarkTap != null || onBookmarkToggle != null)) ...[
                                const SizedBox(width: 6),
                                WrittleBookmarkPill(
                                  key: ValueKey('bookmark_${story.id}'),
                                  isBookmarked: story.isBookmarked,
                                  onBeforeTap: () => isAuth,
                                  onTap: () {
                                    if (!isAuth) {
                                      WrittleAuthGuard.showAuthPrompt(
                                        context,
                                        title: 'Save to Keepsakes',
                                        message: 'Please sign in or create an account to preserve this story in your keepsakes.',
                                      );
                                      return;
                                    }
                                    (onBookmarkTap ?? onBookmarkToggle)?.call();
                                  },
                                  isCompact: true,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
