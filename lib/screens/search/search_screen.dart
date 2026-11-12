import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/empty_state_widget.dart';
import '../../core/widgets/story_card.dart';
import '../../core/widgets/writtle_ambient_background.dart';
import '../../core/widgets/writtle_auth_guard.dart';
import '../../core/widgets/writtle_avatar.dart';
import '../../core/widgets/writtle_paper_surface.dart';
import '../../models/story_model.dart';
import '../../models/user_profile_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/feed_provider.dart';
import '../../repositories/follow_repository.dart';
import '../profile/public_profile_screen.dart';
import '../reader/story_reader_screen.dart';

enum SearchScope {
  stories('Chronicles', Icons.auto_stories_outlined),
  authors('Scribes', Icons.people_outline);

  final String label;
  final IconData icon;
  const SearchScope(this.label, this.icon);
}

enum StorySortOption {
  latest('Newest'),
  popular('Most Revered'),
  mostLiked('Most Beloved');

  final String label;
  const StorySortOption(this.label);
}

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _searchController = TextEditingController();
  SearchScope _selectedScope = SearchScope.stories;
  String _selectedCategorySlug = 'all';
  StorySortOption _selectedSort = StorySortOption.latest;
  Timer? _debounceTimer;

  void _onSearchChanged(String _) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 250), () {
      if (mounted) setState(() {});
    });
  }

  void _onSearchClear() {
    _debounceTimer?.cancel();
    _searchController.clear();
    setState(() {});
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final storiesAsync = ref.watch(feedStoriesProvider);

    return WrittleAmbientBackground(
      variant: AmbientVariant.explore,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new, size: 18, color: AppColors.textPrimaryColor(context)),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          title: Text(
            'Explore',
            style: AppTypography.pageHeader.copyWith(
              color: AppColors.textPrimaryColor(context),
            ),
          ),
          actions: [
            if (_searchController.text.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.clear, size: 20),
                tooltip: 'Clear inquiry',
                onPressed: _onSearchClear,
              ),
          ],
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Refined Search Input on Tactile Paper Surface
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 4, 18, 10),
              child: WrittlePaperSurface(
                variant: PaperSurfaceVariant.white,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                borderRadius: 14,
                child: TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  style: AppTypography.uiHeadline.copyWith(
                    fontWeight: FontWeight.normal,
                    fontSize: 14.5,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Seek tales, authors, or whispered truths...',
                    hintStyle: AppTypography.uiBody.copyWith(
                      color: AppColors.textTertiaryColor(context),
                      fontSize: 13.5,
                    ),
                    prefixIcon: const Icon(Icons.search, color: AppColors.burntSienna, size: 20),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close, size: 16),
                            onPressed: _onSearchClear,
                          )
                        : null,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ),

            // 2. Scope Switcher (Chronicles vs Scribes)
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 8),
              child: Row(
                children: SearchScope.values.map((scope) {
                  final isSelected = _selectedScope == scope;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: InkWell(
                      onTap: () => setState(() => _selectedScope = scope),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.burntSienna : AppColors.softParchment,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? AppColors.burntSienna : AppColors.borderLight,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              scope.icon,
                              size: 14,
                              color: isSelected ? Colors.white : AppColors.textPrimaryColor(context),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              scope.label,
                              style: AppTypography.captionMeta.copyWith(
                                fontSize: 12,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                color: isSelected ? Colors.white : AppColors.textPrimaryColor(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            if (_selectedScope == SearchScope.stories) ...[
              // 3. Sort Options (Horizontal Literary Pills)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 4.0),
                child: Row(
                  children: [
                    Text(
                      'ORDER:',
                      style: AppTypography.kicker.copyWith(
                        color: AppColors.textTertiaryColor(context),
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Row(
                          children: StorySortOption.values.map((sort) {
                            final isSelected = _selectedSort == sort;
                            return Padding(
                              padding: const EdgeInsets.only(right: 6.0),
                              child: InkWell(
                                onTap: () => setState(() => _selectedSort = sort),
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: isSelected ? AppColors.espresso : AppColors.softParchment,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: isSelected ? AppColors.espresso : AppColors.borderLight,
                                    ),
                                  ),
                                  child: Text(
                                    sort.label,
                                    style: AppTypography.captionMeta.copyWith(
                                      fontSize: 11,
                                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                      color: isSelected ? Colors.white : AppColors.textPrimaryColor(context),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 4. Topics Bar
              categoriesAsync.when(
                loading: () => const SizedBox(height: 8),
                error: (_, _) => const SizedBox(height: 8),
                data: (categories) {
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(18, 6, 18, 10),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children: [
                          _buildTopicPill(
                            label: 'All Topics',
                            isSelected: _selectedCategorySlug == 'all',
                            onTap: () => setState(() => _selectedCategorySlug = 'all'),
                          ),
                          ...categories.map(
                            (c) => _buildTopicPill(
                              label: c.name,
                              isSelected: _selectedCategorySlug == c.slug,
                              onTap: () => setState(() => _selectedCategorySlug = c.slug),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],

            Divider(
              height: 1,
              thickness: 1,
              color: AppColors.borderColor(context).withValues(alpha: 0.7),
            ),

            // 5. Results Content (Stories or Authors)
            Expanded(
              child: _selectedScope == SearchScope.stories
                  ? _buildStoriesContent(storiesAsync)
                  : _buildAuthorsContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoriesContent(AsyncValue<List<StoryModel>> storiesAsync) {
    return storiesAsync.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: CircularProgressIndicator(color: AppColors.burntSienna),
        ),
      ),
      error: (err, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text('Could not load chronicles: $err'),
        ),
      ),
      data: (allStories) {
        final query = _searchController.text.trim().toLowerCase();

        var filtered = allStories.where((s) {
          if (query.isEmpty) return true;
          return s.title.toLowerCase().contains(query) ||
              s.authorName.toLowerCase().contains(query) ||
              s.categoryName.toLowerCase().contains(query) ||
              s.content.toLowerCase().contains(query);
        }).toList();

        if (_selectedCategorySlug != 'all') {
          filtered = filtered.where((s) => s.categorySlug == _selectedCategorySlug).toList();
        }

        switch (_selectedSort) {
          case StorySortOption.latest:
            filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
            break;
          case StorySortOption.popular:
            filtered.sort((a, b) =>
                (b.viewsCount + b.likesCount * 2 + b.commentsCount * 3)
                    .compareTo(a.viewsCount + a.likesCount * 2 + a.commentsCount * 3));
            break;
          case StorySortOption.mostLiked:
            filtered.sort((a, b) => b.likesCount.compareTo(a.likesCount));
            break;
        }

        if (filtered.isEmpty) {
          return EmptyStateWidget(
            icon: Icons.search_off_outlined,
            title: 'No echoes discovered',
            message: query.isNotEmpty
                ? 'No stories match your inquiry "$query". Seek another truth or explore different topics.'
                : 'No stories dwell under this topic yet.',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: filtered.length + 1,
          itemBuilder: (context, idx) {
            if (idx == 0) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                child: Row(
                  children: [
                    Text(
                      '${filtered.length} CHRONICLES FOUND',
                      style: AppTypography.kicker.copyWith(
                        color: AppColors.mutedCocoa,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              );
            }

            final story = filtered[idx - 1];
            return RepaintBoundary(
              child: StoryCard(
                story: story,
                showBookmark: true,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => StoryReaderScreen(story: story)),
                  );
                },
                onLikeTap: () async {
                  final repo = ref.read(storyRepositoryProvider);
                  await repo.toggleLike(story.id);
                  ref.invalidate(feedStoriesProvider);
                  ref.invalidate(bookmarkedStoriesProvider);
                  ref.invalidate(myPublishedStoriesProvider);
                  ref.invalidate(myDraftStoriesProvider);
                },
                onBookmarkTap: () async {
                  final repo = ref.read(storyRepositoryProvider);
                  await repo.toggleBookmark(story.id);
                  ref.invalidate(feedStoriesProvider);
                  ref.invalidate(bookmarkedStoriesProvider);
                  ref.invalidate(myPublishedStoriesProvider);
                  ref.invalidate(myDraftStoriesProvider);
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAuthorsContent() {
    final query = _searchController.text.trim();
    final authorsAsync = ref.watch(searchAuthorsProvider(query));

    return authorsAsync.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: CircularProgressIndicator(color: AppColors.burntSienna),
        ),
      ),
      error: (err, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text('Could not seek authors: $err'),
        ),
      ),
      data: (authors) {
        if (authors.isEmpty) {
          return EmptyStateWidget(
            icon: Icons.person_search_outlined,
            title: 'No scribes discovered',
            message: query.isNotEmpty
                ? 'No author matches "$query". Search another pen name.'
                : 'Enter a pen name above to explore sanctuary authors.',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          itemCount: authors.length + 1,
          itemBuilder: (context, idx) {
            if (idx == 0) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(2, 4, 2, 10),
                child: Text(
                  '${authors.length} AUTHORS IN SANCTUARY',
                  style: AppTypography.kicker.copyWith(
                    color: AppColors.mutedCocoa,
                    fontSize: 10,
                  ),
                ),
              );
            }

            final UserProfileModel author = authors[idx - 1];
            final username = author.penName.toLowerCase().replaceAll(RegExp(r'\s+'), '');

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: WrittlePaperSurface(
                variant: PaperSurfaceVariant.white,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                borderRadius: 14,
                child: InkWell(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => PublicProfileScreen(
                          authorId: author.id,
                          initialPenName: author.penName,
                        ),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: Row(
                    children: [
                      WrittleAvatar(
                        avatarUrl: author.avatarUrl,
                        radius: 22,
                        fallbackInitial: author.penName.isNotEmpty ? author.penName[0] : 'W',
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              author.penName,
                              style: AppTypography.storyHeading.copyWith(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '@$username',
                              style: AppTypography.captionMeta.copyWith(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            if (author.bio != null && author.bio!.isNotEmpty) ...[
                              const SizedBox(height: 3),
                              Text(
                                author.bio!,
                                style: AppTypography.uiBody.copyWith(
                                  fontSize: 12,
                                  color: AppColors.textTertiary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      _AuthorFollowButton(authorId: author.id),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTopicPill({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 6.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.burntSienna.withValues(alpha: 0.14) : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? AppColors.burntSienna : AppColors.borderLight,
              width: 1,
            ),
          ),
          child: Text(
            label,
            style: AppTypography.captionMeta.copyWith(
              fontSize: 11.5,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              color: isSelected ? AppColors.burntSienna : AppColors.textSecondaryColor(context),
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthorFollowButton extends ConsumerStatefulWidget {
  final String authorId;
  const _AuthorFollowButton({required this.authorId});

  @override
  ConsumerState<_AuthorFollowButton> createState() => _AuthorFollowButtonState();
}

class _AuthorFollowButtonState extends ConsumerState<_AuthorFollowButton> {
  bool _isToggling = false;

  @override
  Widget build(BuildContext context) {
    final authRepo = ref.watch(authRepositoryProvider);
    final currentUserId = authRepo.currentUser?.id;

    if (currentUserId == widget.authorId) {
      return const SizedBox.shrink();
    }

    final isFollowingAsync = ref.watch(isFollowingTargetProvider(widget.authorId));
    final isFollowing = isFollowingAsync.value ?? false;

    return SizedBox(
      height: 32,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          backgroundColor: isFollowing ? AppColors.surfaceWarm : AppColors.burntSienna,
          foregroundColor: isFollowing ? AppColors.textPrimaryColor(context) : Colors.white,
          side: BorderSide(
            color: isFollowing ? AppColors.borderLight : Colors.transparent,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        onPressed: _isToggling
            ? null
            : () async {
                if (currentUserId == null) {
                  WrittleAuthGuard.showAuthPrompt(
                    context,
                    title: 'Follow Author',
                    message: 'Please sign in or create an account to follow this author.',
                  );
                  return;
                }

                final messenger = ScaffoldMessenger.of(context);
                setState(() => _isToggling = true);
                try {
                  final followRepo = ref.read(followRepositoryProvider);
                  if (isFollowing) {
                    await followRepo.unfollow(
                      followerId: currentUserId,
                      followingId: widget.authorId,
                    );
                  } else {
                    await followRepo.follow(
                      followerId: currentUserId,
                      followingId: widget.authorId,
                    );
                  }
                  ref.invalidate(isFollowingTargetProvider(widget.authorId));
                  ref.invalidate(userFollowStatsProvider(widget.authorId));
                  ref.invalidate(userFollowStatsProvider(currentUserId));
                  ref.invalidate(userFollowersProvider(widget.authorId));
                  ref.invalidate(userFollowingProvider(widget.authorId));
                  ref.invalidate(userFollowersProvider(currentUserId));
                  ref.invalidate(userFollowingProvider(currentUserId));
                } catch (e) {
                  if (mounted) {
                    messenger.showSnackBar(
                      SnackBar(content: Text('Could not update connection: $e')),
                    );
                  }
                } finally {
                  if (mounted) setState(() => _isToggling = false);
                }
              },
        child: _isToggling
            ? const SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.white),
              )
            : Text(
                isFollowing ? 'Following' : 'Follow',
                style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
              ),
      ),
    );
  }
}
