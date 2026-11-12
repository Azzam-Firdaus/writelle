import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/empty_state_widget.dart';
import '../../core/widgets/writtle_ambient_background.dart';
import '../../core/widgets/writtle_avatar.dart';
import '../../core/widgets/writtle_paper_surface.dart';
import '../../providers/auth_provider.dart';
import '../../repositories/follow_repository.dart';
import 'public_profile_screen.dart';

/// Screen allowing users to inspect the Readers (followers) and Following circle
/// for any author sanctuary profile.
class FollowListScreen extends ConsumerStatefulWidget {
  final String userId;
  final String penName;
  final int initialIndex;

  const FollowListScreen({
    super.key,
    required this.userId,
    required this.penName,
    this.initialIndex = 0,
  });

  @override
  ConsumerState<FollowListScreen> createState() => _FollowListScreenState();
}

class _FollowListScreenState extends ConsumerState<FollowListScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  RealtimeChannel? _realtimeChannel;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialIndex.clamp(0, 1),
    );
    _setupRealtime();
    // Invalidate stale caches when screen mounts
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.invalidate(userFollowersProvider(widget.userId));
        ref.invalidate(userFollowingProvider(widget.userId));
        ref.invalidate(userFollowStatsProvider(widget.userId));
      }
    });
  }

  void _setupRealtime() {
    try {
      final client = Supabase.instance.client;
      _realtimeChannel = client
          .channel('public:follow_list_${widget.userId}_${DateTime.now().millisecondsSinceEpoch}')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'follows',
            callback: (_) {
              if (mounted) {
                ref.invalidate(userFollowStatsProvider(widget.userId));
                ref.invalidate(userFollowersProvider(widget.userId));
                ref.invalidate(userFollowingProvider(widget.userId));
              }
            },
          )
          .subscribe();
    } catch (_) {}
  }

  @override
  void dispose() {
    try {
      _realtimeChannel?.unsubscribe();
    } catch (_) {}
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final statsAsync = ref.watch(userFollowStatsProvider(widget.userId));
    final stats = statsAsync.value ?? const FollowStats(followers: 0, following: 0);

    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textPrimaryColor(context)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              widget.penName,
              style: AppTypography.storyHeading.copyWith(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimaryColor(context),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 1),
            Text(
              'Circle of Souls',
              style: AppTypography.captionMeta.copyWith(
                fontSize: 11,
                color: AppColors.textTertiaryColor(context),
              ),
            ),
          ],
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.burntSienna,
          unselectedLabelColor: AppColors.textSecondaryColor(context),
          indicatorColor: AppColors.burntSienna,
          indicatorWeight: 2.5,
          labelStyle: AppTypography.uiBodyMedium.copyWith(fontWeight: FontWeight.bold),
          tabs: [
            Tab(text: 'Readers (${stats.followers})'),
            Tab(text: 'Following (${stats.following})'),
          ],
        ),
      ),
      body: WrittleAmbientBackground(
        variant: AmbientVariant.profile,
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildUsersList(isFollowers: true),
            _buildUsersList(isFollowers: false),
          ],
        ),
      ),
    );
  }

  Widget _buildUsersList({required bool isFollowers}) {
    final provider = isFollowers
        ? userFollowersProvider(widget.userId)
        : userFollowingProvider(widget.userId);
    final usersAsync = ref.watch(provider);

    return RefreshIndicator(
      color: AppColors.burntSienna,
      onRefresh: () async {
        ref.invalidate(provider);
        ref.invalidate(userFollowStatsProvider(widget.userId));
      },
      child: usersAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.burntSienna),
        ),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Text(
              'Could not load accounts: $err',
              textAlign: TextAlign.center,
              style: AppTypography.uiBody.copyWith(color: AppColors.textSecondaryColor(context)),
            ),
          ),
        ),
        data: (users) {
          if (users.isEmpty) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                const SizedBox(height: 60),
                EmptyStateWidget(
                  icon: isFollowers ? Icons.people_outline : Icons.person_add_outlined,
                  title: isFollowers ? 'No Readers Yet' : 'Not Following Anyone',
                  message: isFollowers
                      ? 'When fellow souls begin reading this sanctuary, their paths will intertwine here.'
                      : 'Step into the garden of tales to discover voices that resonate with your spirit.',
                ),
              ],
            );
          }

          final currentUserId = ref.watch(authRepositoryProvider).currentUser?.id;

          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            itemCount: users.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final user = users[index];
              final isMe = currentUserId != null && currentUserId == user.id;

              return WrittlePaperSurface(
                variant: PaperSurfaceVariant.white,
                padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
                borderRadius: 12,
                onTap: isMe
                    ? null
                    : () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => PublicProfileScreen(
                              authorId: user.id,
                              initialPenName: user.penName,
                            ),
                          ),
                        );
                      },
                child: Row(
                  children: [
                    // Author Avatar
                    WrittleAvatar(
                      avatarUrl: user.avatarUrl,
                      radius: 20,
                      fallbackInitial: user.penName.isNotEmpty ? user.penName[0] : 'W',
                    ),
                    const SizedBox(width: 12),

                    // Pen Name and Bio / Handle
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  user.penName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.uiBodyMedium.copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14.5,
                                    color: AppColors.textPrimaryColor(context),
                                  ),
                                ),
                              ),
                              if (isMe) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceWarmColor(context),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: AppColors.borderColor(context)),
                                  ),
                                  child: Text(
                                    'You',
                                    style: AppTypography.captionMeta.copyWith(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.burntSienna,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            (user.bio != null && user.bio!.trim().isNotEmpty)
                                ? user.bio!
                                : '@${user.penName.toLowerCase().replaceAll(RegExp(r'\s+'), '')}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.captionMeta.copyWith(
                              fontSize: 12,
                              color: AppColors.textSecondaryColor(context),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Interactive Follow / Unfollow Button
                    if (!isMe && currentUserId != null) ...[
                      const SizedBox(width: 8),
                      _FollowToggleButton(targetUserId: user.id),
                    ],
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

/// Compact toggle button for following/unfollowing accounts in circles list
class _FollowToggleButton extends ConsumerStatefulWidget {
  final String targetUserId;

  const _FollowToggleButton({required this.targetUserId});

  @override
  ConsumerState<_FollowToggleButton> createState() => _FollowToggleButtonState();
}

class _FollowToggleButtonState extends ConsumerState<_FollowToggleButton> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final isFollowingAsync = ref.watch(isFollowingTargetProvider(widget.targetUserId));
    final isFollowing = isFollowingAsync.value ?? false;
    final currentUserId = ref.watch(authRepositoryProvider).currentUser?.id;

    if (currentUserId == null || currentUserId == widget.targetUserId) {
      return const SizedBox.shrink();
    }

    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        foregroundColor: isFollowing ? AppColors.textSecondaryColor(context) : Colors.white,
        backgroundColor: isFollowing ? Colors.transparent : AppColors.espresso,
        side: BorderSide(
          color: isFollowing ? AppColors.borderColor(context) : AppColors.espresso,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      onPressed: _isLoading
          ? null
          : () async {
              setState(() => _isLoading = true);
              try {
                final repo = ref.read(followRepositoryProvider);
                if (isFollowing) {
                  await repo.unfollow(
                    followerId: currentUserId,
                    followingId: widget.targetUserId,
                  );
                } else {
                  await repo.follow(
                    followerId: currentUserId,
                    followingId: widget.targetUserId,
                  );
                }
                ref.invalidate(isFollowingTargetProvider(widget.targetUserId));
                ref.invalidate(userFollowStatsProvider(widget.targetUserId));
                ref.invalidate(userFollowStatsProvider(currentUserId));
                ref.invalidate(userFollowersProvider(widget.targetUserId));
                ref.invalidate(userFollowingProvider(widget.targetUserId));
                ref.invalidate(userFollowersProvider(currentUserId));
                ref.invalidate(userFollowingProvider(currentUserId));
              } catch (_) {
              } finally {
                if (mounted) setState(() => _isLoading = false);
              }
            },
      child: _isLoading
          ? const SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(strokeWidth: 1.5, color: AppColors.burntSienna),
            )
          : Text(
              isFollowing ? 'Following' : 'Follow',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: isFollowing ? AppColors.textPrimaryColor(context) : Colors.white,
              ),
            ),
    );
  }
}
