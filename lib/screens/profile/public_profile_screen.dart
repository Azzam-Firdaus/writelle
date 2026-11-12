import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/empty_state_widget.dart';
import '../../core/widgets/story_card.dart';
import '../../core/widgets/writtle_auth_guard.dart';
import '../../core/widgets/writtle_avatar.dart';
import '../../models/story_model.dart';
import '../../models/user_profile_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/feed_provider.dart';
import '../../repositories/block_repository.dart';
import '../../repositories/follow_repository.dart';
import '../reader/story_reader_screen.dart';
import 'follow_list_screen.dart';

final authorStoriesProvider =
    FutureProvider.family<List<StoryModel>, String>((ref, authorId) async {
  final storyRepo = ref.watch(storyRepositoryProvider);
  return await storyRepo.getStoriesByAuthor(authorId);
});

final authorProfileProvider =
    FutureProvider.family<UserProfileModel?, String>((ref, authorId) async {
  final authRepo = ref.watch(authRepositoryProvider);
  return await authRepo.getProfileById(authorId);
});

/// Screen to view another author's public profile and follow them.
class PublicProfileScreen extends ConsumerStatefulWidget {
  final String authorId;
  final String initialPenName;

  const PublicProfileScreen({
    super.key,
    required this.authorId,
    required this.initialPenName,
  });

  @override
  ConsumerState<PublicProfileScreen> createState() => _PublicProfileScreenState();
}

class _PublicProfileScreenState extends ConsumerState<PublicProfileScreen> {
  bool _isToggling = false;
  RealtimeChannel? _realtimeChannel;

  @override
  void initState() {
    super.initState();
    _setupRealtime();
  }

  @override
  void dispose() {
    if (_realtimeChannel != null) {
      try {
        Supabase.instance.client.removeChannel(_realtimeChannel!);
      } catch (_) {}
    }
    super.dispose();
  }

  void _setupRealtime() {
    try {
      final client = Supabase.instance.client;
      final currentUserId = client.auth.currentUser?.id;

      _realtimeChannel = client
          .channel('public:public_profile_${widget.authorId}_${DateTime.now().millisecondsSinceEpoch}')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'follows',
            callback: (_) {
              if (mounted) {
                ref.invalidate(userFollowStatsProvider(widget.authorId));
                ref.invalidate(authorProfileProvider(widget.authorId));
                ref.invalidate(userFollowersProvider(widget.authorId));
                ref.invalidate(userFollowingProvider(widget.authorId));
                if (currentUserId != null) {
                  ref.invalidate(userFollowStatsProvider(currentUserId));
                  ref.invalidate(isFollowingTargetProvider(widget.authorId));
                  ref.invalidate(userFollowersProvider(currentUserId));
                  ref.invalidate(userFollowingProvider(currentUserId));
                }
              }
            },
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'stories',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'user_id',
              value: widget.authorId,
            ),
            callback: (_) {
              if (mounted) {
                ref.invalidate(authorStoriesProvider(widget.authorId));
              }
            },
          )
          .subscribe();
    } catch (_) {}
  }

  Future<void> _handleToggleFollow(bool isCurrentlyFollowing, String? currentUserId) async {
    if (currentUserId == null) {
      WrittleAuthGuard.showAuthPrompt(
        context,
        title: 'Follow Author',
        message: 'Please sign in or create an account to follow this author.',
      );
      return;
    }

    if (currentUserId == widget.authorId) return;

    setState(() => _isToggling = true);
    try {
      final followRepo = ref.read(followRepositoryProvider);
      if (isCurrentlyFollowing) {
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not update connection: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isToggling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authRepo = ref.watch(authRepositoryProvider);
    final currentUserId = authRepo.currentUser?.id;
    final isMe = currentUserId != null && currentUserId == widget.authorId;

    final profileAsync = ref.watch(authorProfileProvider(widget.authorId));
    final storiesAsync = ref.watch(authorStoriesProvider(widget.authorId));
    final statsAsync = ref.watch(userFollowStatsProvider(widget.authorId));
    final isFollowingAsync = ref.watch(isFollowingTargetProvider(widget.authorId));

    final penName = profileAsync.value?.penName.isNotEmpty == true
        ? profileAsync.value!.penName
        : widget.initialPenName;
    final username = penName.toLowerCase().replaceAll(RegExp(r'\s+'), '');
    final bio = profileAsync.value?.bio?.isNotEmpty == true
        ? profileAsync.value!.bio!
        : 'A contemplative wanderer who shares thoughts with the quiet world.';

    final isFollowing = isFollowingAsync.value ?? false;
    final isBlockedAsync = ref.watch(isAuthorBlockedProvider(widget.authorId));
    final isBlocked = isBlockedAsync.value ?? false;
    final followStats = statsAsync.value ?? const FollowStats(followers: 0, following: 0);
    final publishedStories = storiesAsync.value ?? [];

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundLight,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          penName,
          style: AppTypography.pageHeader,
        ),
        actions: [
          if (!isMe)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: AppColors.espresso),
              onSelected: (val) async {
                if (val == 'block') {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: AppColors.surfaceLight,
                      title: Text(isBlocked ? 'Unblock Author' : 'Block Author'),
                      content: Text(
                        isBlocked
                            ? 'Allow tales from $penName to appear in your sanctuary feed again?'
                            : 'Block $penName? Their scrolls and words will be concealed from your sanctuary feed.',
                      ),
                      actions: [
                        TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isBlocked ? AppColors.accentPrimary : AppColors.error,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () => Navigator.of(ctx).pop(true),
                          child: Text(isBlocked ? 'Unblock' : 'Block Author'),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    final blockRepo = ref.read(blockRepositoryProvider);
                    if (isBlocked) {
                      await blockRepo.unblockAuthor(widget.authorId);
                    } else {
                      await blockRepo.blockAuthor(widget.authorId);
                    }
                    ref.invalidate(isAuthorBlockedProvider(widget.authorId));
                    ref.invalidate(blockedAuthorsProvider);
                    ref.invalidate(feedStoriesProvider);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: AppColors.burntSienna,
                          content: Text(isBlocked ? '$penName has been unblocked.' : '$penName has been blocked.'),
                        ),
                      );
                    }
                  }
                }
              },
              itemBuilder: (ctx) => [
                PopupMenuItem(
                  value: 'block',
                  child: Row(
                    children: [
                      Icon(
                        isBlocked ? Icons.check_circle_outline : Icons.block_outlined,
                        size: 18,
                        color: isBlocked ? AppColors.accentPrimary : AppColors.error,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isBlocked ? 'Unblock Author' : 'Block Author',
                        style: TextStyle(
                          color: isBlocked ? AppColors.accentPrimary : AppColors.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.accentPrimary,
        backgroundColor: AppColors.surfaceLight,
        onRefresh: () async {
          ref.invalidate(authorProfileProvider(widget.authorId));
          ref.invalidate(authorStoriesProvider(widget.authorId));
          ref.invalidate(userFollowStatsProvider(widget.authorId));
          ref.invalidate(isFollowingTargetProvider(widget.authorId));
          ref.invalidate(isAuthorBlockedProvider(widget.authorId));
        },
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
          children: [
            if (isBlocked) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.block, color: AppColors.error, size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'You have blocked this author. Their scrolls are concealed from your sanctuary feed.',
                        style: TextStyle(fontSize: 12.5, color: AppColors.error, height: 1.35),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 8),

            // Large Avatar
            Center(
              child: WrittleAvatar(
                avatarUrl: profileAsync.value?.avatarUrl,
                radius: 42,
                fallbackInitial: penName.isNotEmpty ? penName[0] : 'W',
              ),
            ),
            const SizedBox(height: 12),

            // Pen Name
            Text(
              penName,
              style: AppTypography.storyHeading.copyWith(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),

            // Username handle
            Text(
              '@$username',
              style: AppTypography.captionMeta.copyWith(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),

            // Bio
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                bio,
                style: AppTypography.uiBody.copyWith(
                  fontSize: 13.5,
                  color: AppColors.textSecondary,
                  height: 1.45,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 18),

            // Follow / Unfollow / Self Action Button
            Center(
              child: isMe
                  ? Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceWarm,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.borderLight),
                      ),
                      child: Text(
                        'Your Sanctuary Profile',
                        style: AppTypography.captionMeta.copyWith(
                          color: AppColors.accentPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  : SizedBox(
                      width: 160,
                      child: ElevatedButton.icon(
                        icon: _isToggling
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Icon(
                                isFollowing ? Icons.check : Icons.person_add_outlined,
                                size: 16,
                              ),
                        label: Text(
                          isFollowing ? 'Following' : 'Follow',
                          style: AppTypography.buttonText.copyWith(
                            fontSize: 13,
                            color: isFollowing ? AppColors.textPrimary : Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              isFollowing ? AppColors.surfaceWarm : AppColors.accentPrimary,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                              color: isFollowing ? AppColors.borderLight : Colors.transparent,
                            ),
                          ),
                        ),
                        onPressed: _isToggling
                            ? null
                            : () => _handleToggleFollow(isFollowing, currentUserId),
                      ),
                    ),
            ),
            const SizedBox(height: 20),

            // 3 Real-time Stats Counters
            Container(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem('${publishedStories.length}', 'Writings'),
                  Container(height: 28, width: 1, color: AppColors.borderLight),
                  _buildStatItem(
                    '${followStats.followers}',
                    'Readers',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => FollowListScreen(
                            userId: widget.authorId,
                            penName: penName,
                            initialIndex: 0,
                          ),
                        ),
                      );
                    },
                  ),
                  Container(height: 28, width: 1, color: AppColors.borderLight),
                  _buildStatItem(
                    '${followStats.following}',
                    'Following',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => FollowListScreen(
                            userId: widget.authorId,
                            penName: penName,
                            initialIndex: 1,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Stories Section Title
            Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Text(
                'Tales from this Soul',
                style: AppTypography.uiHeadline.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),

            // Published stories list
            storiesAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: CircularProgressIndicator(color: AppColors.accentPrimary),
                ),
              ),
              error: (err, _) => Center(
                child: Text('Unable to load writings: $err'),
              ),
              data: (stories) {
                if (stories.isEmpty) {
                  return const EmptyStateWidget(
                    icon: Icons.auto_stories_outlined,
                    title: 'No public writings yet',
                    message: 'This author has not yet released published tales into the open sanctuary.',
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: stories.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (ctx, index) {
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
                      onLikeTap: () async {
                        try {
                          await ref.read(storyRepositoryProvider).toggleLike(story.id);
                          ref.invalidate(authorStoriesProvider(widget.authorId));
                          ref.invalidate(feedStoriesProvider);
                          ref.invalidate(myPublishedStoriesProvider);
                        } catch (_) {}
                      },
                      onBookmarkToggle: () async {
                        try {
                          await ref.read(storyRepositoryProvider).toggleBookmark(story.id);
                          ref.invalidate(authorStoriesProvider(widget.authorId));
                          ref.invalidate(bookmarkedStoriesProvider);
                        } catch (_) {}
                      },
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String count, String label, {VoidCallback? onTap}) {
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          count,
          style: AppTypography.uiHeadline.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 17,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: AppTypography.captionMeta.copyWith(
            color: AppColors.textSecondary,
            fontSize: 12,
          ),
        ),
      ],
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: content,
        ),
      );
    }
    return content;
  }
}
