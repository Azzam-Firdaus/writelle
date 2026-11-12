import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:writtle/core/widgets/writtle_auth_guard.dart';
import 'package:writtle/providers/auth_provider.dart';
import 'package:writtle/providers/feed_provider.dart';
import 'package:writtle/models/story_model.dart';
import 'package:writtle/screens/auth/login_screen.dart';
import 'package:writtle/screens/bookmarks/bookmarks_screen.dart';
import 'package:writtle/screens/profile/profile_screen.dart';

void main() {
  group('Guest Interaction Restriction & Auth Guard Tests', () {
    testWidgets('WrittleAuthGuard.showAuthPrompt renders dialog with Sign In/Join button', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () {
                    WrittleAuthGuard.showAuthPrompt(
                      context,
                      title: 'Like Story',
                      message: 'Please sign in or create an account to like this story.',
                    );
                  },
                  child: const Text('Trigger Guard'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Trigger Guard'));
      await tester.pumpAndSettle();

      expect(find.text('Like Story'), findsOneWidget);
      expect(
        find.text('Please sign in or create an account to like this story.'),
        findsOneWidget,
      );
      expect(find.text('Sign In / Join'), findsOneWidget);
      expect(find.text('Maybe Later'), findsOneWidget);

      // Tap Maybe Later closes dialog
      await tester.tap(find.text('Maybe Later'));
      await tester.pumpAndSettle();

      expect(find.text('Like Story'), findsNothing);
    });

    testWidgets('ProfileScreen renders LoginScreen directly without enter button when guest', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ProfileScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify LoginScreen is directly rendered on Profile tab
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.text('Sign In'), findsWidgets);
      expect(find.text('Create Account'), findsWidgets);
      expect(find.text('Sign In to Sanctuary'), findsOneWidget);

      // Verify old "Enter Sanctuary / Join" button is NOT present
      expect(find.text('Enter Sanctuary / Join'), findsNothing);
    });

    testWidgets('BookmarksScreen shows login prompt when guest', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            isAuthenticatedProvider.overrideWithValue(false),
            bookmarkedStoriesProvider.overrideWith((ref) => Future.value([])),
          ],
          child: const MaterialApp(
            home: BookmarksScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify guest prompt is shown
      expect(find.text('Keepsakes Sanctuary'), findsOneWidget);
      expect(find.text('Please sign in or create an account to view and manage your preserved tales.'), findsOneWidget);
      expect(find.text('Sign In / Join'), findsOneWidget);
    });

    testWidgets('BookmarksScreen displays saved keepsakes when authenticated', (tester) async {
      final sampleStory = StoryModel(
        id: 'test-story-1',
        userId: 'user-1',
        categoryId: 'cat-1',
        categoryName: 'Reflection',
        categorySlug: 'reflection',
        title: 'Whispering Winds',
        content: 'Soft winds that caress the morning soul.',
        authorName: 'Quiet Poet',
        isAnonymous: false,
        createdAt: DateTime.now(),
        isBookmarked: true,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            isAuthenticatedProvider.overrideWithValue(true),
            bookmarkedStoriesProvider.overrideWith((ref) => Future.value([sampleStory])),
          ],
          child: const MaterialApp(
            home: BookmarksScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Guest prompt should be absent
      expect(find.text('Keepsakes Sanctuary'), findsNothing);

      // Header and story card should be visible
      expect(find.text('CURATED REPOSITORY'), findsOneWidget);
      expect(find.text('Treasured Chronicles'), findsOneWidget);
      expect(find.text('Whispering Winds'), findsOneWidget);
    });

    testWidgets('BookmarksScreen dynamically updates when auth changes', (tester) async {
      final authNotifier = _TestAuthNotifier();
      final testAuthProvider = NotifierProvider<_TestAuthNotifier, bool>(() => authNotifier);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            isAuthenticatedProvider.overrideWith((ref) => ref.watch(testAuthProvider)),
            bookmarkedStoriesProvider.overrideWith((ref) => Future.value([])),
          ],
          child: MaterialApp(
            home: Consumer(
              builder: (context, ref, _) {
                return Column(
                  children: [
                    ElevatedButton(
                      onPressed: () => ref.read(testAuthProvider.notifier).setAuth(true),
                      child: const Text('Log In Button'),
                    ),
                    const Expanded(child: BookmarksScreen()),
                  ],
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Initially guest prompt
      expect(find.text('Keepsakes Sanctuary'), findsOneWidget);
      expect(find.text('Your keepsakes chest is empty'), findsNothing);

      // Simulate logging in
      await tester.tap(find.text('Log In Button'));
      await tester.pumpAndSettle();

      // Guest prompt immediately disappears and empty chest is displayed
      expect(find.text('Keepsakes Sanctuary'), findsNothing);
      expect(find.text('Your keepsakes chest is empty'), findsOneWidget);
    });
  });
}

class _TestAuthNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void setAuth(bool val) {
    state = val;
  }
}
