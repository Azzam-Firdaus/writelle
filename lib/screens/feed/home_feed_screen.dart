import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/category_chip.dart';
import '../../core/widgets/empty_state_widget.dart';
import '../../core/widgets/story_card.dart';
import '../../core/widgets/writtle_ambient_background.dart';
import '../../core/widgets/writtle_app_bar.dart';
import '../../core/widgets/writtle_auth_guard.dart';
import '../../core/widgets/writtle_edit_ethos_sheet.dart';
import '../../core/widgets/writtle_featured_story.dart';
import '../../core/widgets/writtle_paper_surface.dart';
import '../../core/widgets/writtle_section_header.dart';
import '../../models/story_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/ethos_provider.dart';
import '../../providers/feed_provider.dart';
import '../editor/story_editor_screen.dart';
import '../reader/story_reader_screen.dart';
import '../search/search_screen.dart';

class HomeFeedScreen extends ConsumerWidget {
  const HomeFeedScreen({super.key});

  String _generatePoeticGreeting(String? rawName) {
    final hour = DateTime.now().hour;
    final trimmed = rawName?.trim();
    final hasName = trimmed != null && trimmed.isNotEmpty && trimmed != 'Anonymous Writer';

    if (hour >= 5 && hour < 12) {
      // Dawn & Morning (05:00 - 11:59)
      return hasName ? 'Peace to your dawn, $trimmed' : 'Peace to your dawn, gentle soul';
    } else if (hour >= 12 && hour < 17) {
      // Afternoon (12:00 - 16:59)
      return hasName ? 'May quiet words find you, $trimmed' : 'May quiet words find you, wanderer';
    } else if (hour >= 17 && hour < 21) {
      // Twilight & Dusk (17:00 - 20:59)
      return hasName ? 'Soft twilight to you, $trimmed' : 'Soft twilight, quiet reader';
    } else {
      // Night (21:00 - 04:59)
      return hasName ? 'Stillness of the night, $trimmed' : 'Stillness of the night, nightfarer';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final storiesAsync = ref.watch(feedStoriesProvider);
    final penName = ref.watch(currentUserProfileProvider.select((p) => p.value?.penName));
    final authRepo = ref.watch(authRepositoryProvider);

    final rawName = penName ??
        authRepo.currentUser?.userMetadata?['pen_name'] as String? ??
        (authRepo.currentUser?.email != null ? authRepo.currentUser!.email!.split('@').first : null);

    final poeticGreeting = _generatePoeticGreeting(rawName);

    return WrittleAmbientBackground(
      variant: AmbientVariant.home,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: WrittleAppBar(
          title: 'Writelle',
          isBrandTitle: true,
          poeticGreeting: poeticGreeting,
          actions: [
            IconButton(
              icon: Icon(Icons.refresh, color: AppColors.textPrimaryColor(context)),
              tooltip: 'Refresh Sanctuary',
              onPressed: () => ref.refresh(feedStoriesProvider),
            ),
            const SizedBox(width: 4),
          ],
        ),
        body: RefreshIndicator(
          color: AppColors.burntSienna,
          backgroundColor: AppColors.softParchment,
          onRefresh: () async {
            ref.invalidate(feedStoriesProvider);
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(parent: ClampingScrollPhysics()),
            slivers: [
              // 1. Welcoming Editorial Header & Tagline
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 14,
                            height: 2,
                            decoration: BoxDecoration(
                              color: AppColors.burntSienna,
                              borderRadius: BorderRadius.circular(1),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'SANCTUARY CHRONICLES',
                            style: AppTypography.kicker,
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Stories that stay with you.',
                        style: AppTypography.heroDisplay.copyWith(
                          fontSize: 27,
                          letterSpacing: -0.4,
                          color: AppColors.textPrimaryColor(context),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Unspoken truths, private reflections, and honest literary tales.',
                        style: AppTypography.captionMeta.copyWith(
                          fontSize: 13,
                          color: AppColors.textSecondaryColor(context),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 2. Horizontal Category Filter Chips (always visible and interactive)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: categoriesAsync.when(
                    loading: () => const SizedBox(height: 38),
                    error: (_, _) => const SizedBox.shrink(),
                    data: (categories) {
                      return SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        child: Row(
                          children: [
                            CategoryChip(
                              label: 'All Tales',
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
                        ),
                      );
                    },
                  ),
                ),
              ),

              // 3. Dynamic Story Content Slivers
              ..._buildStorySlivers(context, ref, storiesAsync, selectedCategory),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildStorySlivers(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<StoryModel>> storiesAsync,
    String selectedCategory,
  ) {
    final ethos = ref.watch(ethosProvider);
    final bool isAdmin = ref.watch(currentUserProfileProvider.select((p) => p.value?.isSuperAdmin == true));

    // When initial loading (no data yet)
    if (storiesAsync.isLoading && !storiesAsync.hasValue) {
      return [
        const SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(40.0),
              child: CircularProgressIndicator(color: AppColors.burntSienna),
            ),
          ),
        ),
      ];
    }

    // When error and no data available
    if (storiesAsync.hasError && !storiesAsync.hasValue) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(28.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      color: AppColors.softParchment,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.wifi_off, size: 36, color: AppColors.burntSienna),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'The Sanctuary is momentarily quiet',
                    style: AppTypography.storyHeading.copyWith(
                      fontSize: 18,
                      color: AppColors.textPrimaryColor(context),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Could not connect to the literary feed. Please check your network and try again.',
                    textAlign: TextAlign.center,
                    style: AppTypography.uiBody.copyWith(
                      color: AppColors.textSecondaryColor(context),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => ref.refresh(feedStoriesProvider),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.burntSienna,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Reconnect'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ];
    }

    final stories = storiesAsync.value ?? [];

    // Empty state for current filter
    if (stories.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: EmptyStateWidget(
            icon: Icons.auto_stories_outlined,
            title: 'A quiet parchment awaits...',
            message: selectedCategory == 'all'
                ? 'No tales have been whispered yet. Be the first soul to write onto the parchment.'
                : 'No stories found in this topic yet. Share your voice or explore other collections.',
            action: ElevatedButton(
              onPressed: () {
                if (!WrittleAuthGuard.check(
                  context,
                  ref,
                  title: 'Pen a Story',
                  message: 'Please sign in or create an account to start writing stories in Writelle.',
                )) {
                  return;
                }
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const StoryEditorScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.burntSienna,
                foregroundColor: Colors.white,
              ),
              child: const Text('Pen a Story'),
            ),
          ),
        ),
      ];
    }

    final featuredStory = stories.first;
    final remainingStories = stories.length > 1 ? stories.sublist(1) : <StoryModel>[];

    return [
      // Subtle loading progress line if updating category in background
      if (storiesAsync.isLoading)
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: LinearProgressIndicator(
              minHeight: 2,
              color: AppColors.burntSienna,
              backgroundColor: Colors.transparent,
            ),
          ),
        ),

      // 4. Featured Hero Story
      const SliverToBoxAdapter(
        child: WrittleSectionHeader(
          kicker: 'FEATURED TALE',
          title: 'Curated for this Hour',
          padding: EdgeInsets.fromLTRB(20, 14, 20, 6),
        ),
      ),
      SliverToBoxAdapter(
        child: WrittleFeaturedStory(
          story: featuredStory,
          showBookmark: true,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => StoryReaderScreen(story: featuredStory),
              ),
            );
          },
          onLikeTap: () async {
            final repo = ref.read(storyRepositoryProvider);
            await repo.toggleLike(featuredStory.id);
            ref.invalidate(feedStoriesProvider);
            ref.invalidate(bookmarkedStoriesProvider);
            ref.invalidate(myPublishedStoriesProvider);
          },
          onBookmarkTap: () async {
            final repo = ref.read(storyRepositoryProvider);
            await repo.toggleBookmark(featuredStory.id);
            ref.invalidate(feedStoriesProvider);
            ref.invalidate(bookmarkedStoriesProvider);
            ref.invalidate(myPublishedStoriesProvider);
          },
        ),
      ),

      // 5. Contrast Feature Panel: Dark Espresso Philosophy Card
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 14.0),
          child: WrittlePaperSurface(
            variant: PaperSurfaceVariant.espresso,
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
            borderRadius: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.burntSienna.withValues(alpha: 0.25),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.edit_note_rounded,
                        size: 18,
                        color: AppColors.warmSand,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      ethos.header,
                      style: AppTypography.kicker.copyWith(
                        color: AppColors.warmSand,
                        fontSize: 10,
                        letterSpacing: 1.2,
                      ),
                    ),
                    if (isAdmin) ...[
                      const Spacer(),
                      InkWell(
                        onTap: () => WrittleEditEthosSheet.show(context),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.burntSienna.withValues(alpha: 0.20),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.warmSand.withValues(alpha: 0.25),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.edit_outlined, size: 12, color: AppColors.warmSand),
                              const SizedBox(width: 4),
                              Text(
                                'Edit',
                                style: AppTypography.captionMeta.copyWith(
                                  color: AppColors.warmSand,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  ethos.quote,
                  style: AppTypography.pullQuote.copyWith(
                    color: AppColors.warmIvory,
                    fontSize: 16,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        ethos.subtext,
                        style: AppTypography.captionMeta.copyWith(
                          color: AppColors.warmSand.withValues(alpha: 0.7),
                          fontSize: 11.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () {
                        if (!WrittleAuthGuard.check(
                          context,
                          ref,
                          title: 'Pen a Story',
                          message: 'Please sign in or create an account to start writing stories in Writelle.',
                        )) {
                          return;
                        }
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const StoryEditorScreen()),
                        );
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: AppColors.burntSienna,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.draw_outlined, size: 14, color: Colors.white),
                            const SizedBox(width: 6),
                            Text(
                              ethos.buttonLabel,
                              style: AppTypography.buttonText.copyWith(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),

      // 6. Recent Stories Section Header
      if (remainingStories.isNotEmpty) ...[
        SliverToBoxAdapter(
          child: WrittleSectionHeader(
            kicker: 'VOICES & REFLECTIONS',
            title: 'Recent Chronicles',
            subtitle: 'Latest submissions shared with the sanctuary',
            actionText: 'Explore More',
            onActionTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SearchScreen()),
              );
            },
          ),
        ),

        // 7. Editorial Story Cards
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final story = remainingStories[index];
              return RepaintBoundary(
                child: StoryCard(
                  story: story,
                  showBookmark: true,
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
                    ref.invalidate(feedStoriesProvider);
                    ref.invalidate(bookmarkedStoriesProvider);
                    ref.invalidate(myPublishedStoriesProvider);
                  },
                  onBookmarkTap: () async {
                    final repo = ref.read(storyRepositoryProvider);
                    await repo.toggleBookmark(story.id);
                    ref.invalidate(feedStoriesProvider);
                    ref.invalidate(bookmarkedStoriesProvider);
                    ref.invalidate(myPublishedStoriesProvider);
                  },
                ),
              );
            },
            childCount: remainingStories.length,
          ),
        ),
      ],

      const SliverToBoxAdapter(
        child: SizedBox(height: 32),
      ),
    ];
  }
}
