import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../core/widgets/writtle_auth_guard.dart';
import '../providers/auth_provider.dart';
import '../providers/feed_provider.dart';
import 'bookmarks/bookmarks_screen.dart';
import 'editor/story_editor_screen.dart';
import 'feed/home_feed_screen.dart';
import 'profile/profile_screen.dart';
import 'search/search_screen.dart';

class MainShellScreen extends ConsumerStatefulWidget {
  const MainShellScreen({super.key});

  @override
  ConsumerState<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends ConsumerState<MainShellScreen> {
  int _currentScreenIndex = 0;
  RealtimeChannel? _globalRealtimeChannel;

  final List<Widget> _screens = const [
    RepaintBoundary(child: HomeFeedScreen()),
    RepaintBoundary(child: SearchScreen()),
    RepaintBoundary(child: BookmarksScreen()),
    RepaintBoundary(child: ProfileScreen()),
  ];

  @override
  void initState() {
    super.initState();
    _setupGlobalRealtime();
  }

  @override
  void dispose() {
    if (_globalRealtimeChannel != null) {
      try {
        Supabase.instance.client.removeChannel(_globalRealtimeChannel!);
      } catch (_) {}
    }
    super.dispose();
  }

  void _setupGlobalRealtime() {
    try {
      final client = Supabase.instance.client;
      final channelName = 'public:global_feed_realtime_${DateTime.now().millisecondsSinceEpoch}';

      _globalRealtimeChannel = client
          .channel(channelName)
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'likes',
            callback: (_) {
              if (mounted) {
                ref.invalidate(feedStoriesProvider);
                ref.invalidate(bookmarkedStoriesProvider);
                ref.invalidate(myPublishedStoriesProvider);
              }
            },
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'comments',
            callback: (_) {
              if (mounted) {
                ref.invalidate(feedStoriesProvider);
                ref.invalidate(bookmarkedStoriesProvider);
                ref.invalidate(myPublishedStoriesProvider);
              }
            },
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'bookmarks',
            callback: (_) {
              if (mounted) {
                ref.invalidate(feedStoriesProvider);
                ref.invalidate(bookmarkedStoriesProvider);
                ref.invalidate(myPublishedStoriesProvider);
              }
            },
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'stories',
            callback: (_) {
              if (mounted) {
                ref.invalidate(feedStoriesProvider);
                ref.invalidate(bookmarkedStoriesProvider);
                ref.invalidate(myPublishedStoriesProvider);
              }
            },
          )
          .subscribe();
    } catch (e) {
      debugPrint('[MainShellScreen] Global Realtime setup notice: $e');
    }
  }

  void _onWritePressed() {
    final isAuth = ref.read(isAuthenticatedProvider);
    if (!isAuth) {
      WrittleAuthGuard.showAuthPrompt(
        context,
        title: 'Pen a Story',
        message: 'Please sign in or create an account to start writing and sharing your stories in the sanctuary.',
        onSuccess: () {
          if (mounted) {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const StoryEditorScreen()),
            );
          }
        },
      );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const StoryEditorScreen()),
    );
  }

  int get _navBarIndex {
    switch (_currentScreenIndex) {
      case 0:
        return 0; // Home
      case 1:
        return 1; // Explore
      case 2:
        return 3; // Keepsakes
      case 3:
        return 4; // Profile
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(authStateProvider);
    ref.watch(isAuthenticatedProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final navBgColor = isDark ? AppColors.espresso : AppColors.pureWhite;
    final borderColor = isDark ? AppColors.mutedCocoa.withValues(alpha: 0.3) : AppColors.warmSand.withValues(alpha: 0.6);

    return Scaffold(
      body: IndexedStack(
        index: _currentScreenIndex,
        children: _screens,
      ),
      bottomNavigationBar: RepaintBoundary(
        child: Container(
          decoration: BoxDecoration(
            color: navBgColor,
            border: Border(
              top: BorderSide(
                color: borderColor,
                width: 1,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.espresso.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: BottomNavigationBar(
              currentIndex: _navBarIndex,
              backgroundColor: navBgColor,
              selectedItemColor: AppColors.burntSienna,
              unselectedItemColor: AppColors.mutedCocoa,
              type: BottomNavigationBarType.fixed,
              elevation: 0,
              selectedFontSize: 11,
              unselectedFontSize: 11,
              selectedLabelStyle: AppTypography.uiBodyMedium.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 11,
                letterSpacing: 0.3,
              ),
              unselectedLabelStyle: AppTypography.captionMeta.copyWith(
                fontSize: 11,
              ),
              onTap: (navIndex) {
                if (navIndex == 2) {
                  _onWritePressed();
                } else if (navIndex == 0) {
                  setState(() => _currentScreenIndex = 0);
                } else if (navIndex == 1) {
                  setState(() => _currentScreenIndex = 1);
                } else if (navIndex == 3) {
                  final isAuth = ref.read(isAuthenticatedProvider);
                  if (!isAuth) {
                    WrittleAuthGuard.showAuthPrompt(
                      context,
                      title: 'Keepsakes Sanctuary',
                      message: 'Please sign in or create an account to access and preserve your keepsake tales.',
                      onSuccess: () {
                        if (mounted) {
                          setState(() => _currentScreenIndex = 2);
                        }
                      },
                    );
                    return;
                  }
                  setState(() => _currentScreenIndex = 2);
                } else if (navIndex == 4) {
                  setState(() => _currentScreenIndex = 3);
                }
              },
              items: [
                const BottomNavigationBarItem(
                  icon: Icon(Icons.home_outlined),
                  activeIcon: Icon(Icons.home),
                  label: 'Home',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.search),
                  activeIcon: Icon(Icons.search),
                  label: 'Explore',
                ),
                BottomNavigationBarItem(
                  icon: Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: AppColors.burntSienna,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.burntSienna.withValues(alpha: 0.35),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.edit,
                      color: AppColors.warmIvory,
                      size: 15,
                    ),
                  ),
                  label: 'Pen',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.bookmark_border),
                  activeIcon: Icon(Icons.bookmark),
                  label: 'Keepsakes',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.person_outline),
                  activeIcon: Icon(Icons.person),
                  label: 'Profile',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
