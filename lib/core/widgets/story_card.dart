import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../../models/story_model.dart';

/// Editorial Story Card for feed listings.
/// Ref: docs/UI_UX_DESIGN.md
class StoryCard extends StatelessWidget {
  final StoryModel story;
  final VoidCallback onTap;
  final VoidCallback? onBookmarkTap;

  const StoryCard({
    super.key,
    required this.story,
    required this.onTap,
    this.onBookmarkTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: AppColors.borderLight, width: 1),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category & Read Time Bar
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceWarm,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    story.categoryName.toUpperCase(),
                    style: AppTypography.captionMeta.copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: AppColors.accentPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text('•', style: AppTypography.captionMeta),
                const SizedBox(width: 8),
                Text(
                  story.readingTime,
                  style: AppTypography.captionMeta,
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Title
            Text(
              story.title,
              style: AppTypography.storyHeading.copyWith(
                fontSize: 19,
                height: 1.3,
                color: AppColors.textPrimary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),

            // Snippet Preview
            Text(
              story.content,
              style: AppTypography.storyBody.copyWith(
                fontSize: 15,
                height: 1.5,
                color: AppColors.textSecondary,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 14),

            // Footer (Author & Engagement)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Author Identifier
                Row(
                  children: [
                    Icon(
                      story.isAnonymous ? Icons.shield_outlined : Icons.person_outline,
                      size: 15,
                      color: story.isAnonymous ? AppColors.accentSubtle : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      story.authorName,
                      style: AppTypography.captionMeta.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),

                // Engagement indicators
                Row(
                  children: [
                    Icon(
                      story.isLiked ? Icons.favorite : Icons.favorite_border,
                      size: 15,
                      color: story.isLiked ? AppColors.error : AppColors.textTertiary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${story.likesCount}',
                      style: AppTypography.captionMeta.copyWith(fontSize: 11),
                    ),
                    const SizedBox(width: 14),
                    const Icon(
                      Icons.chat_bubble_outline,
                      size: 14,
                      color: AppColors.textTertiary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${story.commentsCount}',
                      style: AppTypography.captionMeta.copyWith(fontSize: 11),
                    ),
                    if (onBookmarkTap != null) ...[
                      const SizedBox(width: 14),
                      InkWell(
                        onTap: onBookmarkTap,
                        child: Icon(
                          story.isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                          size: 17,
                          color: story.isBookmarked ? AppColors.accentPrimary : AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
