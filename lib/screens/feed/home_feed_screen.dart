import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/category_chip.dart';
import '../../core/widgets/empty_state_widget.dart';
import '../../core/widgets/story_card.dart';
import '../../core/widgets/writtle_app_bar.dart';
import '../../providers/feed_provider.dart';
import '../editor/story_editor_screen.dart';
import '../reader/story_reader_screen.dart';

class HomeFeedScreen extends ConsumerWidget {
  const HomeFeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final storiesAsync = ref.watch(feedStoriesProvider);

    return Scaffold(
      appBar: WrittleAppBar(
        title: 'Writtle',
        isBrandTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Stories',
            onPressed: () => ref.refresh(feedStoriesProvider),
          ),
        ],
      ),
      body: Column(
        children: [
          // Horizontal Category Filter Bar
          Container(
            height: 52,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppColors.borderLight, width: 1),
              ),
            ),
            child: categoriesAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (err, stack) => const SizedBox.shrink(),
              data: (categories) {
                return ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    CategoryChip(
                      label: 'All Stories',
                      isSelected: selectedCategory == 'all',
                      onTap: () {
                        ref.read(selectedCategoryProvider.notifier).setCategory('all');
                      },
                    ),
                    ...categories.map(
                      (cat) => CategoryChip(
                        label: cat.name,
                        isSelected: selectedCategory == cat.slug,
                        onTap: () {
                          ref.read(selectedCategoryProvider.notifier).setCategory(cat.slug);
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          // Story Feed List
          Expanded(
            child: RefreshIndicator(
              color: AppColors.accentPrimary,
              backgroundColor: AppColors.surfaceLight,
              onRefresh: () async {
                ref.invalidate(feedStoriesProvider);
              },
              child: storiesAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.accentPrimary),
                ),
                error: (err, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.wifi_off, size: 40, color: AppColors.textSecondary),
                        const SizedBox(height: 12),
                        const Text(
                          'Could not load stories. Please check your connection.',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: () => ref.refresh(feedStoriesProvider),
                          child: const Text('Try Again'),
                        ),
                      ],
                    ),
                  ),
                ),
                data: (stories) {
                  if (stories.isEmpty) {
                    return EmptyStateWidget(
                      icon: Icons.auto_stories_outlined,
                      title: 'A quiet moment...',
                      message: 'No stories have been written in this category yet. Be the first to share your thoughts.',
                      action: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const StoryEditorScreen()),
                          );
                        },
                        child: const Text('Write a Story'),
                      ),
                    );
                  }

                  return ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
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
                          ref.invalidate(feedStoriesProvider);
                          ref.invalidate(bookmarkedStoriesProvider);
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
