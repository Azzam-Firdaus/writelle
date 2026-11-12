import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:writtle/core/widgets/story_card.dart';
import 'package:writtle/core/widgets/writtle_action_pills.dart';
import 'package:writtle/models/story_model.dart';

void main() {
  final testStory = StoryModel(
    id: 'test-story-1',
    title: 'Judul Cerita Panjang Yang Menarik Sekali',
    content: 'Isi konten cerita yang sangat panjang untuk testing subtitle dan reading time.',
    isAnonymous: false,
    authorName: 'Author Name',
    coverUrl: 'https://example.com/cover.jpg',
    categoryId: 'cat-1',
    categoryName: 'Reflections',
    categorySlug: 'reflections',
    createdAt: DateTime.now(),
    likesCount: 12,
  );

  testWidgets('StoryCard renders cleanly without overflow on 360px screens with trailing and actions', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StoryCard(
            story: testStory,
            showBookmark: true,
            onTap: () {},
            onLikeTap: () {},
            onBookmarkTap: () {},
            trailing: PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              itemBuilder: (_) => [],
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.byType(StoryCard), findsOneWidget);
    expect(find.text('Reflections'), findsOneWidget);
    expect(find.text('Author Name'), findsOneWidget);
    expect(find.byType(WrittleLikePill), findsOneWidget);
    expect(find.byType(WrittleBookmarkPill), findsOneWidget);
    expect(find.byType(PopupMenuButton<String>), findsOneWidget);
  });

  testWidgets('StoryCard with showActions: false hides like, comment, and bookmark pills (Drafts)', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StoryCard(
            story: testStory,
            showActions: false,
            onTap: () {},
            trailing: PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              itemBuilder: (_) => [],
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.byType(StoryCard), findsOneWidget);
    expect(find.text('Reflections'), findsOneWidget);
    expect(find.byType(WrittleLikePill), findsNothing);
    expect(find.byType(WrittleBookmarkPill), findsNothing);
    expect(find.byType(PopupMenuButton<String>), findsOneWidget);
  });

  testWidgets('StoryCard without cover and without trailing renders category badge and author', (tester) async {
    final coverlessStory = testStory.copyWith(coverUrl: null);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StoryCard(
            story: coverlessStory,
            onTap: () {},
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.byType(StoryCard), findsOneWidget);
    expect(find.text('Reflections'), findsOneWidget);
    expect(find.text('Author Name'), findsOneWidget);
  });
}
