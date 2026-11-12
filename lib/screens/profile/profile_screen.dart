import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/empty_state_widget.dart';
import '../../core/widgets/story_card.dart';
import '../../core/widgets/writelle_logo.dart';
import '../../core/widgets/writtle_ambient_background.dart';
import '../../core/widgets/writtle_avatar.dart';
import '../../core/widgets/writtle_edit_ethos_sheet.dart';
import '../../core/widgets/writtle_paper_surface.dart';
import '../../models/story_model.dart';
import '../../models/user_profile_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/feed_provider.dart';
import '../../repositories/follow_repository.dart';
import '../auth/login_screen.dart';
import '../editor/story_editor_screen.dart';
import '../reader/story_reader_screen.dart';
import '../admin/admin_cms_screen.dart';
import '../legal/privacy_policy_screen.dart';
import '../legal/terms_of_service_screen.dart';
import 'edit_profile_screen.dart';
import 'follow_list_screen.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  RealtimeChannel? _realtimeChannel;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _setupRealtimeSubscriptions();
  }

  void _setupRealtimeSubscriptions() {
    try {
      final client = Supabase.instance.client;
      final currentUserId = client.auth.currentUser?.id;
      if (currentUserId == null) return;

      _realtimeChannel = client
          .channel('public:profile_realtime_$currentUserId')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'stories',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'user_id',
              value: currentUserId,
            ),
            callback: (_) {
              if (mounted) {
                ref.invalidate(myPublishedStoriesProvider);
                ref.invalidate(myDraftStoriesProvider);
                ref.invalidate(myTrashStoriesProvider);
              }
            },
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'likes',
            callback: (_) {
              if (mounted) {
                ref.invalidate(myPublishedStoriesProvider);
                ref.invalidate(myDraftStoriesProvider);
                ref.invalidate(feedStoriesProvider);
              }
            },
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'bookmarks',
            callback: (_) {
              if (mounted) {
                ref.invalidate(myPublishedStoriesProvider);
                ref.invalidate(myDraftStoriesProvider);
                ref.invalidate(bookmarkedStoriesProvider);
              }
            },
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'follows',
            callback: (_) {
              if (mounted) {
                ref.invalidate(userFollowStatsProvider(currentUserId));
                ref.invalidate(userFollowersProvider(currentUserId));
                ref.invalidate(userFollowingProvider(currentUserId));
              }
            },
          )
          .subscribe();
    } catch (_) {}
  }

  @override
  void dispose() {
    _realtimeChannel?.unsubscribe();
    _tabController.dispose();
    super.dispose();
  }

  void _openEditProfile(UserProfileModel? profile) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EditProfileScreen(initialProfile: profile),
      ),
    );
  }

  void _showSettingsBottomSheet(UserProfileModel? profile) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface(context),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bottomCtx) {
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 4,
                  width: 36,
                  decoration: BoxDecoration(
                    color: AppColors.borderLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.edit_outlined, color: AppColors.burntSienna),
                  title: const Text('Edit Identity & Portrait'),
                  subtitle: const Text('Customize avatar, pen name, and bio', style: TextStyle(fontSize: 12)),
                  onTap: () {
                    Navigator.of(bottomCtx).pop();
                    _openEditProfile(profile);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.lock_outline, color: AppColors.mutedCocoa),
                  title: const Text('Change Sanctuary Key'),
                  subtitle: const Text('Update account password securely', style: TextStyle(fontSize: 12)),
                  onTap: () {
                    Navigator.of(bottomCtx).pop();
                    _openEditProfile(profile);
                  },
                ),
                if (profile?.isAdmin == true)
                  ListTile(
                    leading: const Icon(Icons.admin_panel_settings, color: AppColors.burntSienna),
                    title: Row(
                      children: [
                        const Text('Curator Chamber (Admin CMS)'),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.burntSienna.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'ADMIN',
                            style: TextStyle(
                              color: AppColors.burntSienna,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    subtitle: const Text('Platform moderation & management', style: TextStyle(fontSize: 12)),
                    onTap: () {
                      Navigator.of(bottomCtx).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const AdminCmsScreen()),
                      );
                    },
                  ),
                if (profile?.isSuperAdmin == true)
                  ListTile(
                    leading: const Icon(Icons.edit_note, color: AppColors.burntSienna),
                    title: const Text('Edit The Writelle Ethos'),
                    subtitle: const Text('Customize homepage quotes & philosophical subtext', style: TextStyle(fontSize: 12)),
                    onTap: () {
                      Navigator.of(bottomCtx).pop();
                      WrittleEditEthosSheet.show(context);
                    },
                  ),
                ListTile(
                  leading: const Icon(Icons.info_outline, color: AppColors.mutedCocoa),
                  title: const Text('About Writelle'),
                  subtitle: const Text('v1.0.0 • Sanctuary of Words', style: TextStyle(fontSize: 12)),
                  onTap: () {
                    Navigator.of(bottomCtx).pop();
                    showAboutDialog(
                      context: context,
                      applicationName: 'Writelle',
                      applicationVersion: '1.0.0',
                      applicationIcon: const WritelleLogo(height: 48, width: 48),
                      applicationLegalese: 'A tranquil sanctuary for stories, expressions, and honest thoughts.',
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.privacy_tip_outlined, color: AppColors.mutedCocoa),
                  title: const Text('Privacy Policy'),
                  subtitle: const Text('Review data handling & your rights', style: TextStyle(fontSize: 12)),
                  onTap: () {
                    Navigator.of(bottomCtx).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.description_outlined, color: AppColors.mutedCocoa),
                  title: const Text('Terms of Service'),
                  subtitle: const Text('Community guidelines & zero-tolerance EULA', style: TextStyle(fontSize: 12)),
                  onTap: () {
                    Navigator.of(bottomCtx).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const TermsOfServiceScreen()),
                    );
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.logout, color: AppColors.mutedCocoa),
                  title: const Text('Depart from Sanctuary (Sign Out)'),
                  onTap: () async {
                    Navigator.of(bottomCtx).pop();
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (c) => AlertDialog(
                        backgroundColor: AppColors.surface(context),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        title: const Text('Sign Out'),
                        content: const Text('Are you sure you wish to depart from your Writelle sanctuary?'),
                        actions: [
                          TextButton(onPressed: () => Navigator.of(c).pop(false), child: const Text('Cancel')),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.burntSienna,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () => Navigator.of(c).pop(true),
                            child: const Text('Depart'),
                          ),
                        ],
                      ),
                    );
                    if (confirmed == true) {
                      await ref.read(authRepositoryProvider).signOut();
                      ref.invalidate(currentUserProfileProvider);
                      ref.invalidate(myPublishedStoriesProvider);
                      ref.invalidate(myDraftStoriesProvider);
                      ref.invalidate(bookmarkedStoriesProvider);
                      ref.invalidate(feedStoriesProvider);
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete_forever_outlined, color: AppColors.error),
                  title: const Text(
                    'Delete Sanctuary Account',
                    style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Text(
                    'Permanently delete account and all authored tales',
                    style: TextStyle(fontSize: 12, color: AppColors.error),
                  ),
                  onTap: () async {
                    Navigator.of(bottomCtx).pop();
                    final messenger = ScaffoldMessenger.of(context);
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (c) => AlertDialog(
                        backgroundColor: AppColors.surface(context),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        title: Row(
                          children: [
                            const Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 24),
                            const SizedBox(width: 8),
                            const Expanded(child: Text('Delete Account Permanently?')),
                          ],
                        ),
                        content: const SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'This action is irreversible. All your authored scrolls, drafts, bookmarks, likes, followers, and profile identity will be permanently erased from the sanctuary.',
                                style: TextStyle(height: 1.4),
                              ),
                              SizedBox(height: 12),
                              Text(
                                'In compliance with Google Play User Data policies, your data cannot be recovered once confirmed.',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.error),
                              ),
                            ],
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(c).pop(false),
                            child: const Text('Keep My Account'),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.error,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () => Navigator.of(c).pop(true),
                            child: const Text('Delete Permanently'),
                          ),
                        ],
                      ),
                    );

                    if (confirmed == true) {
                      try {
                        await ref.read(authRepositoryProvider).deleteAccount();
                        ref.invalidate(currentUserProfileProvider);
                        ref.invalidate(myPublishedStoriesProvider);
                        ref.invalidate(myDraftStoriesProvider);
                        ref.invalidate(bookmarkedStoriesProvider);
                        ref.invalidate(feedStoriesProvider);

                        messenger.showSnackBar(
                          const SnackBar(
                            backgroundColor: AppColors.burntSienna,
                            content: Text('Your Writelle account and data have been permanently erased.'),
                          ),
                        );
                      } catch (err) {
                        messenger.showSnackBar(
                          SnackBar(
                            backgroundColor: AppColors.error,
                            content: Text('Failed to complete account deletion: $err'),
                          ),
                        );
                      }
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(authStateProvider);
    final isAuth = ref.watch(isAuthenticatedProvider);
    final authRepo = ref.watch(authRepositoryProvider);

    if (!isAuth) {
      return const LoginScreen(isEmbedded: true);
    }

    final currentUserId = authRepo.currentUser?.id;
    final profileAsync = ref.watch(currentUserProfileProvider);
    final publishedAsync = ref.watch(myPublishedStoriesProvider);
    final followStatsAsync = currentUserId != null
        ? ref.watch(userFollowStatsProvider(currentUserId))
        : null;
    final followStats = followStatsAsync?.value ?? const FollowStats(followers: 0, following: 0);

    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Sanctuary',
          style: AppTypography.pageHeader.copyWith(
            color: AppColors.textPrimaryColor(context),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.settings_outlined, color: AppColors.textPrimaryColor(context)),
            tooltip: 'Settings',
            onPressed: () {
              _showSettingsBottomSheet(profileAsync.value);
            },
          ),
        ],
      ),
      body: WrittleAmbientBackground(
        variant: AmbientVariant.profile,
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                  child: profileAsync.when(
                    loading: () => const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24.0),
                        child: CircularProgressIndicator(color: AppColors.burntSienna),
                      ),
                    ),
                    error: (err, _) => Center(child: Text('Could not load profile: $err')),
                    data: (profile) {
                      final penName = (profile != null && profile.penName.isNotEmpty)
                          ? profile.penName
                          : 'Writelle Author';
                      final username = penName.toLowerCase().replaceAll(RegExp(r'\s+'), '');
                      final bio = (profile?.bio?.isNotEmpty == true)
                          ? profile!.bio!
                          : 'A contemplative soul weaving thoughts into quiet words.';
                      final publishedCount = publishedAsync.value?.length ?? 0;
                      final avatarUrl = profile?.avatarUrl;

                      return WrittlePaperSurface(
                        variant: PaperSurfaceVariant.sand,
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Author Avatar with burnt sienna ring
                            GestureDetector(
                              onTap: () => _openEditProfile(profile),
                              child: Stack(
                                alignment: Alignment.bottomRight,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(3),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: AppColors.burntSienna.withValues(alpha: 0.35),
                                        width: 2,
                                      ),
                                    ),
                                    child: WrittleAvatar(
                                      avatarUrl: avatarUrl,
                                      radius: 40,
                                      fallbackInitial: penName.isNotEmpty ? penName[0] : 'W',
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.all(5),
                                    decoration: BoxDecoration(
                                      color: AppColors.burntSienna,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: AppColors.surfaceLight, width: 2),
                                    ),
                                    child: const Icon(
                                      Icons.edit,
                                      size: 12,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Pen Name (Editorial serif)
                            Text(
                              penName,
                              style: AppTypography.storyHeading.copyWith(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: AppColors.espresso,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 2),

                            // Username handle
                            Text(
                              '@$username',
                              style: AppTypography.captionMeta.copyWith(
                                fontSize: 13,
                                color: AppColors.mutedCocoa,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 10),

                            // Bio
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8.0),
                              child: Text(
                                bio,
                                style: AppTypography.uiBody.copyWith(
                                  fontSize: 13,
                                  color: AppColors.espresso.withValues(alpha: 0.85),
                                  height: 1.45,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(height: 14),

                            // Edit Sanctuary Identity Pill Button
                            OutlinedButton.icon(
                              onPressed: () => _openEditProfile(profile),
                              icon: const Icon(Icons.edit_outlined, size: 14, color: AppColors.burntSienna),
                              label: const Text(
                                'Edit Portfolio',
                                style: TextStyle(
                                  color: AppColors.burntSienna,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: AppColors.burntSienna.withValues(alpha: 0.4)),
                                backgroundColor: AppColors.pureWhite.withValues(alpha: 0.6),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // 3 Real-time Stats Counters: [Writings, Readers, Following]
                            Container(
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                              decoration: BoxDecoration(
                                color: AppColors.pureWhite.withValues(alpha: 0.85),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.softParchment),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  _buildStatItem('$publishedCount', 'Writings'),
                                  Container(height: 28, width: 1, color: AppColors.softParchment),
                                  _buildStatItem(
                                    '${followStats.followers}',
                                    'Readers',
                                    onTap: currentUserId != null
                                        ? () {
                                            Navigator.of(context).push(
                                              MaterialPageRoute(
                                                builder: (_) => FollowListScreen(
                                                  userId: currentUserId,
                                                  penName: penName,
                                                  initialIndex: 0,
                                                ),
                                              ),
                                            );
                                          }
                                        : null,
                                  ),
                                  Container(height: 28, width: 1, color: AppColors.softParchment),
                                  _buildStatItem(
                                    '${followStats.following}',
                                    'Following',
                                    onTap: currentUserId != null
                                        ? () {
                                            Navigator.of(context).push(
                                              MaterialPageRoute(
                                                builder: (_) => FollowListScreen(
                                                  userId: currentUserId,
                                                  penName: penName,
                                                  initialIndex: 1,
                                                ),
                                              ),
                                            );
                                          }
                                        : null,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),

              // TabBar as pinned header: [ Writings | Drafts ]
              SliverPersistentHeader(
                pinned: true,
                delegate: _SliverTabBarDelegate(
                  TabBar(
                    controller: _tabController,
                    labelColor: AppColors.burntSienna,
                    unselectedLabelColor: AppColors.mutedCocoa,
                    indicatorColor: AppColors.burntSienna,
                    indicatorWeight: 2.5,
                    labelStyle: AppTypography.uiBodyMedium.copyWith(fontWeight: FontWeight.bold),
                    tabs: const [
                      Tab(text: 'Writings'),
                      Tab(text: 'Drafts'),
                      Tab(text: 'Trash (14d)'),
                    ],
                  ),
                  backgroundColor: AppColors.background(context),
                ),
              ),
            ];
          },
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildPublishedList(),
              _buildDraftsList(),
              _buildTrashList(),
            ],
          ),
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
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.espresso,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: AppTypography.captionMeta.copyWith(
            fontSize: 12,
            color: AppColors.mutedCocoa,
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

  Widget _buildPublishedList() {
    final publishedAsync = ref.watch(myPublishedStoriesProvider);

    return RefreshIndicator(
      color: AppColors.burntSienna,
      onRefresh: () async {
        ref.invalidate(myPublishedStoriesProvider);
        if (ref.read(authRepositoryProvider).currentUser?.id != null) {
          ref.invalidate(userFollowStatsProvider(ref.read(authRepositoryProvider).currentUser!.id));
        }
      },
      child: publishedAsync.when(
        skipLoadingOnReload: true,
        skipLoadingOnRefresh: true,
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.burntSienna),
        ),
        error: (err, _) => Center(child: Text('Could not load writings: $err')),
        data: (stories) {
          if (stories.isEmpty) {
            return const EmptyStateWidget(
              icon: Icons.auto_stories_outlined,
              title: 'No writings shared yet',
              message: 'Stories you release to the world will find their quiet sanctuary here.',
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 32),
            itemCount: stories.length,
            itemBuilder: (context, index) {
              final story = stories[index];
              return StoryCard(
                key: ValueKey('published_${story.id}'),
                story: story,
                trailing: PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 18, color: AppColors.mutedCocoa),
                  padding: EdgeInsets.zero,
                  onSelected: (val) {
                    if (val == 'edit') {
                      _openEditor(story);
                    } else if (val == 'delete') {
                      _confirmDeleteStory(story, isDraft: false);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined, size: 18),
                          SizedBox(width: 8),
                          Text('Edit Tale'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                          SizedBox(width: 8),
                          Text('Erase Tale', style: TextStyle(color: AppColors.error)),
                        ],
                      ),
                    ),
                  ],
                ),
                showBookmark: true,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => StoryReaderScreen(story: story),
                    ),
                  ).then((_) {
                    ref.invalidate(myPublishedStoriesProvider);
                    ref.invalidate(myDraftStoriesProvider);
                    ref.invalidate(bookmarkedStoriesProvider);
                  });
                },
                onLikeTap: () async {
                  final repo = ref.read(storyRepositoryProvider);
                  await repo.toggleLike(story.id);
                  ref.invalidate(myPublishedStoriesProvider);
                  ref.invalidate(myDraftStoriesProvider);
                  ref.invalidate(feedStoriesProvider);
                  ref.invalidate(bookmarkedStoriesProvider);
                },
                onBookmarkTap: () async {
                  final repo = ref.read(storyRepositoryProvider);
                  await repo.toggleBookmark(story.id);
                  ref.invalidate(bookmarkedStoriesProvider);
                  ref.invalidate(feedStoriesProvider);
                  ref.invalidate(myPublishedStoriesProvider);
                  ref.invalidate(myDraftStoriesProvider);
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildDraftsList() {
    final draftsAsync = ref.watch(myDraftStoriesProvider);

    return RefreshIndicator(
      color: AppColors.burntSienna,
      onRefresh: () async {
        ref.invalidate(myDraftStoriesProvider);
      },
      child: draftsAsync.when(
        skipLoadingOnReload: true,
        skipLoadingOnRefresh: true,
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.burntSienna),
        ),
        error: (err, _) => Center(child: Text('Could not load drafts: $err')),
        data: (stories) {
          if (stories.isEmpty) {
            return const EmptyStateWidget(
              icon: Icons.edit_note,
              title: 'Parchment is clear',
              message: 'Whispers and tales preserved in progress will wait quietly here.',
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 32),
            itemCount: stories.length,
            itemBuilder: (context, index) {
              final draft = stories[index];
              return StoryCard(
                key: ValueKey('draft_${draft.id}'),
                story: draft,
                showActions: false,
                trailing: PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 18, color: AppColors.mutedCocoa),
                  padding: EdgeInsets.zero,
                  onSelected: (val) {
                    if (val == 'edit') {
                      _openEditor(draft);
                    } else if (val == 'delete') {
                      _confirmDeleteStory(draft, isDraft: true);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined, size: 18),
                          SizedBox(width: 8),
                          Text('Resume Crafting'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                          SizedBox(width: 8),
                          Text('Discard Draft', style: TextStyle(color: AppColors.error)),
                        ],
                      ),
                    ),
                  ],
                ),
                onTap: () => _openEditor(draft),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildTrashList() {
    final trashAsync = ref.watch(myTrashStoriesProvider);

    return RefreshIndicator(
      color: AppColors.burntSienna,
      onRefresh: () async {
        ref.invalidate(myTrashStoriesProvider);
      },
      child: trashAsync.when(
        skipLoadingOnReload: true,
        skipLoadingOnRefresh: true,
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.burntSienna),
        ),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: AppColors.error, size: 36),
                const SizedBox(height: 12),
                Text(
                  'Could not load trash',
                  style: AppTypography.storyHeading.copyWith(fontSize: 16, color: AppColors.espresso),
                ),
                const SizedBox(height: 6),
                Text(
                  '$err',
                  textAlign: TextAlign.center,
                  style: AppTypography.captionMeta.copyWith(color: AppColors.mutedCocoa, fontSize: 12),
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => ref.invalidate(myTrashStoriesProvider),
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Try Again'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.burntSienna,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
        data: (stories) {
          if (stories.isEmpty) {
            return const EmptyStateWidget(
              icon: Icons.delete_outline,
              title: 'Trash is clear',
              message: 'Tales deleted by you are preserved for 14 days before permanent erasure.',
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 32),
            itemCount: stories.length,
            itemBuilder: (context, index) {
              final story = stories[index];
              final daysLeft = story.daysUntilPermanentDeletion;

              return StoryCard(
                key: ValueKey('trash_${story.id}'),
                story: story,
                showActions: false,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${daysLeft}d left',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.error,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: const Icon(Icons.restore_outlined, size: 20, color: AppColors.success),
                      tooltip: 'Restore Tale',
                      onPressed: () => _confirmRestoreStory(story),
                    ),
                  ],
                ),
                onTap: () => _confirmRestoreStory(story),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _confirmRestoreStory(StoryModel story) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Restore Tale?', style: AppTypography.storyHeading.copyWith(fontSize: 18, color: AppColors.burntSienna)),
        content: Text(
          'Restore "${story.title}" back to your parchment? It will become visible again.',
          style: AppTypography.uiBody,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.burntSienna,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Restore Tale'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        final repo = ref.read(storyRepositoryProvider);
        await repo.restoreStory(story.id);

        ref.invalidate(myTrashStoriesProvider);
        ref.invalidate(myPublishedStoriesProvider);
        ref.invalidate(myDraftStoriesProvider);
        ref.invalidate(feedStoriesProvider);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Tale "${story.title}" restored successfully.'),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Could not restore tale: $e'),
            ),
          );
        }
      }
    }
  }

  Future<void> _openEditor(StoryModel story) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => StoryEditorScreen(initialStory: story),
      ),
    );
    ref.invalidate(myPublishedStoriesProvider);
    ref.invalidate(myDraftStoriesProvider);
    ref.invalidate(feedStoriesProvider);
  }

  Future<void> _confirmDeleteStory(StoryModel story, {required bool isDraft}) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(isDraft ? 'Discard Draft?' : 'Erase Tale?'),
        content: Text(
          isDraft
              ? 'Discard this draft? It will be safely retained in your trash for 14 days before permanent erasure.'
              : 'Move "${story.title}" to trash? It will be safely kept for 14 days and can be restored before permanent erasure.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Keep'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Erase'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        final repo = ref.read(storyRepositoryProvider);
        await repo.deleteStory(story.id);

        ref.invalidate(myPublishedStoriesProvider);
        ref.invalidate(myDraftStoriesProvider);
        ref.invalidate(myTrashStoriesProvider);
        ref.invalidate(feedStoriesProvider);
        ref.invalidate(bookmarkedStoriesProvider);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isDraft ? 'Draft discarded.' : 'Tale returned to silence.'),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not erase: $e')),
          );
        }
      }
    }
  }
}

class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  final Color backgroundColor;

  _SliverTabBarDelegate(this.tabBar, {required this.backgroundColor});

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: backgroundColor,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return oldDelegate.backgroundColor != backgroundColor;
  }
}
