import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../models/story_model.dart';
import '../../providers/auth_provider.dart';
import 'story_cover_image.dart';
import 'writtle_action_pills.dart';
import 'writtle_auth_guard.dart';
import 'writtle_editorial_content.dart';
import 'writtle_paper_surface.dart';

/// Centerpiece editorial hero card for Home and Explore screens.
class WrittleFeaturedStory extends StatelessWidget {
  final StoryModel story;
  final VoidCallback onTap;
  final VoidCallback? onLikeTap;
  final VoidCallback? onBookmarkTap;
  final VoidCallback? onCommentTap;
  final bool showBookmark;
  final bool? isAuthenticated;

  const WrittleFeaturedStory({
    super.key,
    required this.story,
    required this.onTap,
    this.onLikeTap,
    this.onBookmarkTap,
    this.onCommentTap,
    this.showBookmark = false,
    this.isAuthenticated,
  });

  @override
  Widget build(BuildContext context) {
    final readingTime = story.readingTime;
    final hasCover = story.coverUrl != null && story.coverUrl!.trim().isNotEmpty;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    bool isAuth = isAuthenticated ?? false;
    if (isAuthenticated == null) {
      try {
        final container = ProviderScope.containerOf(context, listen: false);
        isAuth = container.read(authRepositoryProvider).isAuthenticated;
      } catch (_) {
        isAuth = true; // Fallback for standalone widget tests without ProviderScope
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 8.0),
      child: WrittlePaperSurface(
        variant: PaperSurfaceVariant.white,
        padding: EdgeInsets.zero,
        borderRadius: 16,
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Cover Image (Only rendered if story has a cover)
            if (hasCover)
              Stack(
                children: [
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: StoryCoverImage(
                      coverUrl: story.coverUrl,
                      fit: BoxFit.cover,
                      cacheWidth: 640,
                    ),
                  ),

                // Gradient scrim on bottom for readability
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.35),
                        ],
                      ),
                    ),
                  ),
                ),

                // Category pill on top-left
                Positioned(
                  top: 14,
                  left: 14,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.burntSienna,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          offset: const Offset(0, 2),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star_rounded, size: 12, color: Colors.white),
                        const SizedBox(width: 4),
                        Text(
                          story.categoryName.toUpperCase(),
                          style: AppTypography.kicker.copyWith(
                            color: Colors.white,
                            fontSize: 10,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Reading time on top-right
                Positioned(
                  top: 14,
                  right: 14,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      readingTime,
                      style: AppTypography.captionMeta.copyWith(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),

          // Fallback Header for coverless featured stories: Category badge & Reading time
          if (!hasCover)
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
                    decoration: BoxDecoration(
                      color: AppColors.burntSienna.withValues(alpha: isDark ? 0.20 : 0.10),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: AppColors.burntSienna.withValues(alpha: isDark ? 0.40 : 0.25),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      story.categoryName.toUpperCase(),
                      style: AppTypography.kicker.copyWith(
                        color: AppColors.burntSienna,
                        fontSize: 10,
                        letterSpacing: 0.8,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.softParchment.withValues(alpha: 0.08)
                          : AppColors.softParchment.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      readingTime,
                      style: AppTypography.captionMeta.copyWith(
                        color: AppColors.textSecondaryColor(context),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 2. Editorial Metadata & Narrative Content
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Headline (Judul)
                  WrittleEditorialParser.buildTitle(
                    story.title,
                    AppTypography.displayTitle.copyWith(
                      fontSize: 22,
                      height: 1.3,
                      letterSpacing: -0.3,
                      color: AppColors.textPrimaryColor(context),
                    ),
                    isDark: isDark,
                    maxLines: 2,
                  ),
                  const SizedBox(height: 8),

                  // Atmospheric Excerpt / Subtitle (Subjudul)
                  WrittleEditorialParser.buildSubtitle(
                    story.content,
                    AppTypography.uiBody.copyWith(
                      color: AppColors.textSecondaryColor(context),
                      fontSize: 13.5,
                      height: 1.5,
                    ),
                    isDark: isDark,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),

                  // Divider
                  Divider(
                    height: 1,
                    thickness: 1,
                    color: AppColors.borderColor(context),
                  ),
                  const SizedBox(height: 12),

                  // Author & Actions Row
                  Row(
                    children: [
                      // Author Avatar / Monogram
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: AppColors.warmSand.withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.borderLight),
                        ),
                        child: Center(
                          child: Icon(
                            story.isAnonymous ? Icons.shield_outlined : Icons.person_outline,
                            size: 15,
                            color: AppColors.burntSienna,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Author Pen Name
                      Expanded(
                        child: Text(
                          story.authorName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.captionMeta.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimaryColor(context),
                          ),
                        ),
                      ),

                      // Interactive Engagement Actions isolated with opaque GestureDetector
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {},
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Interactive Like Pill with Bouncy Heart Animation
                            WrittleLikePill(
                              key: ValueKey('feat_like_${story.id}'),
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

                            // Optional Bookmark Pill
                            if (showBookmark && onBookmarkTap != null) ...[
                              const SizedBox(width: 8),
                              WrittleBookmarkPill(
                                key: ValueKey('feat_bookmark_${story.id}'),
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
                                  onBookmarkTap?.call();
                                },
                                isCompact: true,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
