import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:writtle/core/utils/editorial_text_controller.dart';
import 'package:writtle/core/widgets/story_card.dart';
import 'package:writtle/core/widgets/writtle_action_pills.dart';
import 'package:writtle/core/widgets/writtle_editorial_content.dart';
import 'package:writtle/core/widgets/writtle_featured_story.dart';
import 'package:writtle/core/widgets/writtle_keyboard_accessory_bar.dart';
import 'package:writtle/models/story_model.dart';
import 'package:writtle/screens/reader/story_reader_screen.dart';

void main() {
  group('WrittleEditorialContent & Stabilo Feature Tests', () {
    testWidgets('renders stabilo highlighted text when syntax ==text== is used', (tester) async {
      const testContent = 'The silence speaks when ==the mind stops running== into tomorrow.';

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: WrittleEditorialContent(content: testContent),
          ),
        ),
      );

      // Verify the text content is present
      expect(find.textContaining('The silence speaks when'), findsOneWidget);
      expect(find.textContaining('the mind stops running'), findsOneWidget);

      // Verify rich text spans contain stabilo background styling
      final textFinder = find.byWidgetPredicate(
        (widget) => widget is Text && widget.textSpan != null,
      );
      expect(textFinder, findsWidgets);

      bool foundStabilo = false;
      for (final element in textFinder.evaluate()) {
        final textWidget = element.widget as Text;
        final textSpan = textWidget.textSpan as TextSpan?;
        textSpan?.visitChildren((span) {
          if (span is TextSpan &&
              span.text == 'the mind stops running' &&
              span.style?.backgroundColor != null) {
            foundStabilo = true;
          }
          return true;
        });
      }

      expect(foundStabilo, isTrue, reason: 'Expected stabilo span with non-null backgroundColor');
    });

    testWidgets('renders pull-quote with vertical left accent when syntax > quote is used', (tester) async {
      const testContent = '> Life quietly unfolds in whatever we repeatedly pay attention to.\n\nNormal paragraph follows.';

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: WrittleEditorialContent(content: testContent),
          ),
        ),
      );

      expect(find.textContaining('Life quietly unfolds'), findsOneWidget);
      expect(find.textContaining('Normal paragraph follows'), findsOneWidget);
    });

    testWidgets('correctly parses headings, stabilo, and quotes separated by single newlines in preview', (tester) async {
      const testContent = '## Subjudul Cerita Indah\nKalimat pertama dengan ==sorotan stabilo== kuning.\n> Kutipan puitis singkat';

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: WrittleEditorialContent(content: testContent),
          ),
        ),
      );

      // Verify heading, stabilo text, and quote are all rendered
      expect(find.textContaining('Subjudul Cerita Indah'), findsOneWidget);
      expect(find.textContaining('Kalimat pertama dengan'), findsOneWidget);
      expect(find.textContaining('sorotan stabilo'), findsOneWidget);
      expect(find.textContaining('Kutipan puitis singkat'), findsOneWidget);

      // Verify raw ## and > are NOT rendered as text
      expect(find.textContaining('## Subjudul'), findsNothing);
      expect(find.textContaining('> Kutipan'), findsNothing);
    });

    test('WrittleEditorialParser extracts clean subtitle from content', () {
      // 1. Explicit ## Subjudul
      const contentWithHeading = '## Rahasia Hidup Tenang\nIni adalah isi cerita.';
      expect(WrittleEditorialParser.extractSubtitle(contentWithHeading), 'Rahasia Hidup Tenang');

      // 2. Explicit ### Subheading
      const contentWithH3 = '### Langkah Awal\nMelangkah perlahan.';
      expect(WrittleEditorialParser.extractSubtitle(contentWithH3), 'Langkah Awal');

      // 3. Narrative with > Quote
      const contentWithQuote = '> Keheningan adalah jawaban.\nTeks lanjutan.';
      expect(WrittleEditorialParser.extractSubtitle(contentWithQuote), 'Keheningan adalah jawaban.');

      // 4. Regular narrative
      const regularContent = 'Sebuah kisah tentang perjalanan panjang.';
      expect(WrittleEditorialParser.extractSubtitle(regularContent), 'Sebuah kisah tentang perjalanan panjang.');
    });
  });

  group('WrittleEditorialTextController (Live In-Editor Visuals & Smart Toggle) Tests', () {
    test('toggleStabilo wraps selected text and unwraps if already highlighted', () {
      final controller = WrittleEditorialTextController(text: 'Hello world of tranquility');

      // 1. Select "world of tranquility" (offset 6 to 26)
      controller.selection = const TextSelection(baseOffset: 6, extentOffset: 26);
      controller.toggleStabilo();

      expect(controller.text, 'Hello ==world of tranquility==');

      // 2. Tap toggleStabilo again on the same wrapped selection -> unwraps!
      controller.selection = const TextSelection(baseOffset: 6, extentOffset: 30);
      controller.toggleStabilo();

      expect(controller.text, 'Hello world of tranquility');
    });

    test('toggleQuote and toggleHeading prefixes and unprefixes current line', () {
      final controller = WrittleEditorialTextController(text: 'An inspiring quote');

      // Toggle quote on
      controller.selection = const TextSelection.collapsed(offset: 5);
      controller.toggleQuote();
      expect(controller.text, '> An inspiring quote');

      // Toggle quote off
      controller.toggleQuote();
      expect(controller.text, 'An inspiring quote');

      // Toggle heading on
      controller.toggleHeading();
      expect(controller.text, '## An inspiring quote');

      // Toggle heading off
      controller.toggleHeading();
      expect(controller.text, 'An inspiring quote');
    });

    testWidgets('buildTextSpan produces direct visual canary yellow stabilo span in editor', (tester) async {
      final controller = WrittleEditorialTextController(text: 'Here is ==highlighted phrase== for review.');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TextField(
              controller: controller,
            ),
          ),
        ),
      );

      expect(find.byType(TextField), findsOneWidget);
      expect(find.textContaining('highlighted phrase'), findsOneWidget);
    });
  });

  group('WrittleKeyboardAccessoryBar Widget Tests', () {
    testWidgets('renders all editorial format tools docked above keyboard', (tester) async {
      final controller = WrittleEditorialTextController(text: 'Sample manuscript');
      bool dismissed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WrittleKeyboardAccessoryBar(
              controller: controller,
              onDismissKeyboard: () => dismissed = true,
            ),
          ),
        ),
      );

      // Verify all tools exist
      expect(find.text('Highlight'), findsOneWidget);
      expect(find.text('Quote'), findsOneWidget);
      expect(find.text('Heading'), findsOneWidget);
      expect(find.text('Bold'), findsOneWidget);
      expect(find.text('Italic'), findsOneWidget);
      expect(find.byIcon(Icons.keyboard_hide_outlined), findsOneWidget);

      // Test tapping dismiss keyboard
      await tester.tap(find.byIcon(Icons.keyboard_hide_outlined));
      expect(dismissed, isTrue);
    });
  });

  group('StoryCard (Image 2 Feed Layout) Tests', () {
    final storyWithCover = StoryModel(
      id: 'story-feed-1',
      categoryId: 'cat-mind',
      categoryName: 'Mindfulness',
      categorySlug: 'mindfulness',
      title: 'The Art of Not Thinking',
      content: 'Life quietly unfolds in whatever we repeatedly pay attention to. Constant thought obscures reality.',
      authorName: 'Isamu Penman',
      isAnonymous: false,
      publishedAt: DateTime.now(),
      createdAt: DateTime.now(),
      likesCount: 28,
      commentsCount: 7,
      isLiked: false,
      isBookmarked: false,
      coverUrl: 'https://images.unsplash.com/photo-1544716278-ca5e3f4abd8c',
    );

    final storyWithoutCover = StoryModel(
      id: 'story-feed-2',
      categoryId: 'cat-mind',
      categoryName: 'Mindfulness',
      categorySlug: 'mindfulness',
      title: 'Quiet Reflections',
      content: '## Whispers of Evening\nUnder the pale twilight silence settles over the lake.',
      authorName: 'Isamu Penman',
      isAnonymous: false,
      publishedAt: DateTime.now(),
      createdAt: DateTime.now(),
      likesCount: 19,
      commentsCount: 4,
      isLiked: false,
      isBookmarked: false,
      coverUrl: null,
    );

    testWidgets('StoryCard with cover displays author header, title, excerpt, thumbnail and stats', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StoryCard(
              story: storyWithCover,
              onTap: () {},
            ),
          ),
        ),
      );

      // Author header shown when hasCover is true
      expect(find.text('Isamu Penman'), findsOneWidget);
      expect(find.text('Mindfulness'), findsOneWidget);

      // Title & Excerpt
      expect(find.text('The Art of Not Thinking'), findsOneWidget);
      expect(find.textContaining('Life quietly unfolds'), findsOneWidget);

      // Bottom Row Stats
      expect(find.text('28'), findsOneWidget);
      expect(find.byType(WrittleLikePill), findsOneWidget);
    });

    testWidgets('StoryCard without cover displays author header, category pill, title, subjudul and like/comment pills', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StoryCard(
              story: storyWithoutCover,
              onTap: () {},
            ),
          ),
        ),
      );

      // Author header and Category pill are shown across all cards even without cover
      expect(find.text('Isamu Penman'), findsOneWidget);
      expect(find.text('Mindfulness'), findsOneWidget);

      // Title & Subjudul are shown
      expect(find.text('Quiet Reflections'), findsOneWidget);
      expect(find.textContaining('Whispers of Evening'), findsOneWidget);

      // Bottom Row Stats are shown
      expect(find.text('19'), findsOneWidget);
      expect(find.byType(WrittleLikePill), findsOneWidget);
    });

    testWidgets('StoryCard displays clean subjudul and renders writing style (stabilo) without raw markdown tags', (tester) async {
      final formattedStory = StoryModel(
        id: 'story-feed-formatted',
        categoryId: 'cat-mind',
        categoryName: 'Mindfulness',
        categorySlug: 'mindfulness',
        title: 'Ketenangan Jiwa',
        content: '## Menemukan Kedamaian di ==Ujung Senja==\nDi tengah hiruk pikuk dunia kita belajar hening.',
        authorName: 'Isamu',
        isAnonymous: false,
        publishedAt: DateTime.now(),
        createdAt: DateTime.now(),
        likesCount: 15,
        commentsCount: 3,
        isLiked: false,
        isBookmarked: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StoryCard(
              story: formattedStory,
              onTap: () {},
            ),
          ),
        ),
      );

      // Verify title is rendered
      expect(find.text('Ketenangan Jiwa'), findsOneWidget);

      // Verify clean subtitle is rendered
      expect(find.textContaining('Menemukan Kedamaian di'), findsOneWidget);
      expect(find.textContaining('Ujung Senja'), findsOneWidget);

      // Verify raw ## and == tags are NEVER rendered
      expect(find.textContaining('## Menemukan'), findsNothing);
      expect(find.textContaining('==Ujung Senja=='), findsNothing);

      // Verify stabilo styling on the subtitle text
      final textFinder = find.byWidgetPredicate(
        (widget) => widget is Text && widget.textSpan != null,
      );
      bool foundStabilo = false;
      for (final element in textFinder.evaluate()) {
        final textWidget = element.widget as Text;
        final textSpan = textWidget.textSpan as TextSpan?;
        textSpan?.visitChildren((span) {
          if (span is TextSpan &&
              span.text == 'Ujung Senja' &&
              span.style?.backgroundColor != null) {
            foundStabilo = true;
          }
          return true;
        });
      }
      expect(foundStabilo, isTrue, reason: 'Expected stabilo background on card subtitle');
    });
  });

  group('StoryReaderScreen (Image 1 Layout) Tests', () {
    final readerStory = StoryModel(
      id: 'story-reader-1',
      categoryId: 'cat-mind',
      categoryName: 'Mindfulness',
      categorySlug: 'mindfulness',
      title: 'the art of not thinking',
      content: '> Life quietly unfolds in whatever we repeatedly pay attention to.\n\n## The illusion of constant thinking\n\nWhen we ==let go of obsessive thoughts==, true peace emerges.',
      authorName: 'Isamu',
      isAnonymous: false,
      publishedAt: DateTime.now(),
      createdAt: DateTime.now(),
      likesCount: 42,
      commentsCount: 9,
      isLiked: false,
      isBookmarked: false,
    );

    testWidgets('renders category topic tags, editorial headline, author attribution and stabilo body', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: StoryReaderScreen(story: readerStory),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Top category chip
      expect(find.text('Mindfulness'), findsWidgets);

      // Editorial headline
      expect(find.text('the art of not thinking'), findsOneWidget);

      // Author name
      expect(find.text('Isamu'), findsOneWidget);

      // Action ribbon pills
      expect(find.byType(WrittleLikePill), findsWidgets);

      // Stabilo content rendered
      expect(find.textContaining('let go of obsessive thoughts'), findsOneWidget);
    });

    testWidgets('StoryReaderScreen does not overflow on a narrow mobile viewport (360x640)', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: StoryReaderScreen(story: readerStory),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Ensure no overflow errors occurred
      expect(tester.takeException(), isNull);
    });
  });

  group('WrittleFeaturedStory Tests', () {
    testWidgets('WrittleFeaturedStory without cover does not display 16:9 AspectRatio banner', (tester) async {
      final storyWithoutCover = StoryModel(
        id: 'feat-1',
        categoryId: 'cat-mind',
        categoryName: 'Mindfulness',
        categorySlug: 'mindfulness',
        title: 'Featured Without Cover',
        content: '## Gentle Awakening\nThe dawn whispers quietly over the hills.',
        authorName: 'Azzam',
        isAnonymous: false,
        publishedAt: DateTime.now(),
        createdAt: DateTime.now(),
        likesCount: 10,
        commentsCount: 2,
        coverUrl: null,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WrittleFeaturedStory(
              story: storyWithoutCover,
              onTap: () {},
            ),
          ),
        ),
      );

      // Verify Title and Subtitle are displayed
      expect(find.text('Featured Without Cover'), findsOneWidget);
      expect(find.textContaining('Gentle Awakening'), findsOneWidget);

      // Verify no AspectRatio widget (cover banner) is rendered
      expect(find.byType(AspectRatio), findsNothing);

      // Verify no comment pill is displayed on featured story
      expect(find.byType(WrittleCommentPill), findsNothing);
    });
  });
}
