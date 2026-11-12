import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:writtle/core/widgets/story_card.dart';
import 'package:writtle/core/widgets/writtle_avatar.dart';
import 'package:writtle/models/story_model.dart';

void main() {
  group('WrittleAvatar Tests', () {
    testWidgets('WrittleAvatar renders letter monogram when avatarUrl is null', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: WrittleAvatar(
              avatarUrl: null,
              radius: 40,
              fallbackInitial: 'Isamu',
            ),
          ),
        ),
      );

      expect(find.text('I'), findsOneWidget);
    });

    testWidgets('WrittleAvatar handles tap callback when provided', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WrittleAvatar(
              avatarUrl: null,
              radius: 40,
              fallbackInitial: 'Writelle',
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(WrittleAvatar));
      expect(tapped, isTrue);
    });

    test('getWrittleImageProvider handles different URI schemes', () {
      expect(getWrittleImageProvider(null), isNull);
      expect(getWrittleImageProvider(''), isNull);
      expect(getWrittleImageProvider('https://example.com/avatar.jpg'), isA<NetworkImage>());
    });
  });

  group('StoryCard Interactions Tests', () {
    final testStory = StoryModel(
      id: 'story-123',
      categoryId: 'cat-1',
      categoryName: 'Reflections',
      categorySlug: 'reflections',
      title: 'Solitude of Twilight',
      content: 'A thoughtful tale woven beneath the fading amber skies of a distant autumn day.',
      isAnonymous: false,
      authorName: 'Penman',
      publishedAt: DateTime.now(),
      createdAt: DateTime.now(),
      likesCount: 14,
      commentsCount: 3,
      isLiked: false,
      isBookmarked: false,
    );

    testWidgets('StoryCard calls onLikeTap and onBookmarkTap', (tester) async {
      bool likeTapped = false;
      bool bookmarkTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StoryCard(
              story: testStory,
              onTap: () {},
              onLikeTap: () => likeTapped = true,
              onBookmarkTap: () => bookmarkTapped = true,
            ),
          ),
        ),
      );

      // Verify stats rendered
      expect(find.text('14'), findsOneWidget);

      // Tap like heart
      await tester.tap(find.byIcon(Icons.favorite_border));
      expect(likeTapped, isTrue);

      // Tap bookmark icon
      await tester.tap(find.byIcon(Icons.bookmark_border));
      expect(bookmarkTapped, isTrue);
    });
  });
}
