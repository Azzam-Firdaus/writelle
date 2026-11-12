import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/empty_state_widget.dart';
import '../../core/widgets/story_card.dart';
import '../../core/widgets/writtle_ambient_background.dart';
import '../../core/widgets/writtle_app_bar.dart';
import '../../core/widgets/writtle_auth_guard.dart';
import '../../core/widgets/writtle_paper_surface.dart';
import '../../providers/auth_provider.dart';
import '../../providers/feed_provider.dart';
import '../reader/story_reader_screen.dart';

class BookmarksScreen extends ConsumerWidget {
  const BookmarksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(authStateProvider);
    final isAuth = ref.watch(isAuthenticatedProvider);

    if (!isAuth) {
      return Scaffold(
        backgroundColor: AppColors.background(context),
        appBar: const WrittleAppBar(
          title: 'Keepsakes',
          isBrandTitle: false,
        ),
        body: WrittleAmbientBackground(
          variant: AmbientVariant.keepsakes,
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: EmptyStateWidget(
                icon: Icons.bookmark_border_rounded,
                title: 'Keepsakes Sanctuary',
                message:
                    'Please sign in or create an account to view and manage your preserved tales.',
                action: ElevatedButton(
                  onPressed: () {
                    WrittleAuthGuard.showAuthPrompt(
                      context,
                      title: 'Keepsakes Sanctuary',
                      message:
                          'Please sign in or create an account to access and preserve your keepsake tales.',
                      onSuccess: () {
                        ref.invalidate(bookmarkedStoriesProvider);
                      },
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.burntSienna,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Sign In / Join'),
                ),
              ),
            ),
          ),
        ),
      );
    }

    final bookmarksAsync = ref.watch(bookmarkedStoriesProvider);

    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: const WrittleAppBar(
        title: 'Keepsakes',
        isBrandTitle: false,
      ),
      body: WrittleAmbientBackground(
        variant: AmbientVariant.keepsakes,
        child: RefreshIndicator(
          color: AppColors.accent(context),
          backgroundColor: AppColors.surface(context),
          onRefresh: () async {
            ref.invalidate(bookmarkedStoriesProvider);
          },
          child: bookmarksAsync.when(
            loading: () => Center(
              child: CircularProgressIndicator(color: AppColors.accent(context)),
            ),
            error: (err, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text('Could not load keepsakes: $err'),
              ),
            ),
            data: (stories) {
              if (stories.isEmpty) {
                return const Center(
                  child: SingleChildScrollView(
                    physics: AlwaysScrollableScrollPhysics(),
                    child: EmptyStateWidget(
                      icon: Icons.bookmark_border_rounded,
                      title: 'Your keepsakes chest is empty',
                      message: 'When words touch your quiet soul, tap the bookmark icon on any tale to preserve it here.',
                    ),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.only(top: 12, bottom: 32),
                itemCount: stories.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return _buildHeader(context, stories.length);
                  }

                  final story = stories[index - 1];
                  return RepaintBoundary(
                    child: StoryCard(
                      story: story,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => StoryReaderScreen(story: story),
                          ),
                        );
                      },
                      onLikeTap: () async {
                        final repo = ref.read(storyRepositoryProvider);
                        await repo.toggleLike(story.id);
                        ref.invalidate(bookmarkedStoriesProvider);
                        ref.invalidate(feedStoriesProvider);
                        ref.invalidate(myPublishedStoriesProvider);
                      },
                      onBookmarkTap: () async {
                        final repo = ref.read(storyRepositoryProvider);
                        await repo.toggleBookmark(story.id);
                        ref.invalidate(bookmarkedStoriesProvider);
                        ref.invalidate(feedStoriesProvider);
                        ref.invalidate(myPublishedStoriesProvider);
                      },
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: WrittlePaperSurface(
        variant: PaperSurfaceVariant.sand,
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.burntSienna.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.bookmark_added_rounded,
                color: AppColors.burntSienna,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CURATED REPOSITORY',
                    style: AppTypography.kicker.copyWith(
                      color: AppColors.burntSienna,
                      letterSpacing: 1.4,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Treasured Chronicles',
                    style: AppTypography.storyHeading.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.espresso,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$count ${count == 1 ? 'tale' : 'tales'} preserved in quiet reflection',
                    style: AppTypography.captionMeta.copyWith(
                      color: AppColors.mutedCocoa,
                    ),
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
