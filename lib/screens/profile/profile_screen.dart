import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/editorial_button.dart';
import '../../core/widgets/empty_state_widget.dart';
import '../../core/widgets/writtle_app_bar.dart';
import '../../models/story_model.dart';
import '../../providers/auth_provider.dart';
import '../auth/login_screen.dart';
import '../reader/story_reader_screen.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showEditProfileDialog(String currentPenName, String? currentBio) {
    final penNameCtrl = TextEditingController(text: currentPenName);
    final bioCtrl = TextEditingController(text: currentBio ?? '');
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: AppColors.surfaceLight,
            title: const Text('Edit Pen Name & Bio'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: penNameCtrl,
                  decoration: const InputDecoration(labelText: 'Pen Name (Alias)'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: bioCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Bio (Optional)'),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: isSaving
                    ? null
                    : () async {
                        final newPenName = penNameCtrl.text.trim();
                        if (newPenName.isEmpty) return;
                        final navigator = Navigator.of(ctx);
                        final messenger = ScaffoldMessenger.of(context);
                        setDialogState(() => isSaving = true);
                        try {
                          final authRepo = ref.read(authRepositoryProvider);
                          await authRepo.updateProfile(
                            penName: newPenName,
                            bio: bioCtrl.text.trim(),
                          );
                          ref.invalidate(currentUserProfileProvider);
                          if (ctx.mounted) navigator.pop();
                        } catch (e) {
                          if (mounted) {
                            messenger.showSnackBar(
                              SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
                            );
                          }
                        } finally {
                          setDialogState(() => isSaving = false);
                        }
                      },
                child: isSaving
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authRepo = ref.watch(authRepositoryProvider);
    final isAuth = authRepo.isAuthenticated;

    if (!isAuth) {
      return Scaffold(
        appBar: const WrittleAppBar(title: 'My Profile'),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.person_outline, size: 48, color: AppColors.textSecondary),
                const SizedBox(height: 16),
                Text(
                  'Join the Sanctuary',
                  style: AppTypography.storyHeading.copyWith(fontSize: 22),
                ),
                const SizedBox(height: 8),
                Text(
                  'Sign in or register to publish your stories, save drafts privately, and manage your pen name.',
                  textAlign: TextAlign.center,
                  style: AppTypography.uiBody.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 24),
                EditorialButton(
                  label: 'Sign In / Register',
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      );
    }

    final profileAsync = ref.watch(currentUserProfileProvider);

    return Scaffold(
      appBar: WrittleAppBar(
        title: 'My Profile',
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, size: 20, color: AppColors.textSecondary),
            tooltip: 'Sign Out',
            onPressed: () async {
              await authRepo.signOut();
              ref.invalidate(currentUserProfileProvider);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Profile Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
            child: profileAsync.when(
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.accentPrimary)),
              error: (err, _) => Text('Error loading profile: $err'),
              data: (profile) {
                final penName = profile?.penName ?? 'Author';
                final bio = profile?.bio ?? 'No bio yet.';

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '@$penName',
                          style: AppTypography.storyHeading.copyWith(fontSize: 24),
                        ),
                        OutlinedButton(
                          onPressed: () => _showEditProfileDialog(penName, profile?.bio),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            minimumSize: const Size(60, 32),
                          ),
                          child: const Text('Edit', style: TextStyle(fontSize: 12)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      bio,
                      style: AppTypography.uiBody.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                );
              },
            ),
          ),

          // Tabs for Published vs Drafts
          TabBar(
            controller: _tabController,
            labelColor: AppColors.textPrimary,
            unselectedLabelColor: AppColors.textTertiary,
            indicatorColor: AppColors.accentPrimary,
            tabs: const [
              Tab(text: 'Published Stories'),
              Tab(text: 'Private Drafts'),
            ],
          ),

          // Tab views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildStoriesList(draftsOnly: false),
                _buildStoriesList(draftsOnly: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoriesList({required bool draftsOnly}) {
    final authRepo = ref.read(authRepositoryProvider);

    return FutureBuilder<List<StoryModel>>(
      future: authRepo.getMyStories(draftsOnly: draftsOnly),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.accentPrimary));
        }

        final stories = snapshot.data ?? [];
        if (stories.isEmpty) {
          return EmptyStateWidget(
            icon: draftsOnly ? Icons.edit_note : Icons.auto_stories_outlined,
            title: draftsOnly ? 'No drafts' : 'No published stories',
            message: draftsOnly
                ? 'Ideas you save before publishing will appear here.'
                : 'Stories you publish will be listed here.',
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: stories.length,
          separatorBuilder: (context, index) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final story = stories[index];
            return ListTile(
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
              title: Text(
                story.title,
                style: AppTypography.storyHeading.copyWith(fontSize: 17),
              ),
              subtitle: Text(
                '${story.isAnonymous ? "🛡️ Anonymous" : "✍️ Pen Name"} • ${story.categoryName}',
                style: AppTypography.captionMeta,
              ),
              trailing: const Icon(Icons.chevron_right, size: 18),
              onTap: () {
                if (!draftsOnly) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => StoryReaderScreen(story: story),
                    ),
                  );
                }
              },
            );
          },
        );
      },
    );
  }
}
