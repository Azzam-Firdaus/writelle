import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/empty_state_widget.dart';
import '../../core/widgets/story_card.dart';
import '../../core/widgets/writtle_app_bar.dart';
import '../../providers/feed_provider.dart';
import '../reader/story_reader_screen.dart';

class BookmarksScreen extends ConsumerWidget {
  const BookmarksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookmarksAsync = ref.watch(bookmarkedStoriesProvider);

    return Scaffold(
      appBar: const WrittleAppBar(
        title: 'Saved Stories',
        isBrandTitle: false,
      ),
      body: RefreshIndicator(
        color: AppColors.accentPrimary,
        backgroundColor: AppColors.surfaceLight,
        onRefresh: () async {
          ref.invalidate(bookmarkedStoriesProvider);
        },
        child: bookmarksAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.accentPrimary),
          ),
          error: (err, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Text('Could not load saved stories: $err'),
            ),
          ),
          data: (stories) {
            if (stories.isEmpty) {
              return const EmptyStateWidget(
                icon: Icons.bookmark_border,
                title: 'No saved stories yet',
                message: 'When you find words that stay with you, bookmark them here to revisit later.',
              );
            }

            return ListView.builder(
              itemCount: stories.length,
              itemBuilder: (context, index) {
                final story = stories[index];
                return StoryCard(
                  story: story,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => StoryReaderScreen(story: story),
                      ),
                    );
                  },
                  onBookmarkTap: () async {
                    final repo = ref.read(storyRepositoryProvider);
                    await repo.toggleBookmark(story.id);
                    ref.invalidate(bookmarkedStoriesProvider);
                    ref.invalidate(feedStoriesProvider);
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}
