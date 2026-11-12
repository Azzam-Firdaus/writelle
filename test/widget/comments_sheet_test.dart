import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:writtle/models/comment_model.dart';

void main() {
  group('Comments Sheet Threading Widget Tests', () {
    testWidgets('renders root comments and nested replies with reply indicators', (tester) async {
      final rootComment = CommentModel(
        id: 'c-root-1',
        storyId: 'story-123',
        userId: 'u-1',
        content: 'This piece touched my heart profoundly.',
        authorPenName: 'Maya Angel',
        createdAt: DateTime.now().subtract(const Duration(hours: 3)),
        replies: [
          CommentModel(
            id: 'c-reply-1',
            storyId: 'story-123',
            userId: 'u-2',
            content: 'I felt the exact same way, Maya!',
            authorPenName: 'Rian Writer',
            parentCommentId: 'c-root-1',
            replyingToAuthor: 'Maya Angel',
            createdAt: DateTime.now().subtract(const Duration(hours: 2)),
          ),
          CommentModel(
            id: 'c-reply-2',
            storyId: 'story-123',
            userId: 'u-3',
            content: 'Rian, which sentence was your favorite?',
            authorPenName: 'Dian Reader',
            parentCommentId: 'c-reply-1',
            replyingToAuthor: 'Rian Writer',
            createdAt: DateTime.now().subtract(const Duration(hours: 1)),
          ),
        ],
      );

      final comments = [rootComment];

      CommentModel? replyingTo;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return Column(
                  children: [
                    Expanded(
                      child: ListView.separated(
                        itemCount: comments.length,
                        separatorBuilder: (_, _) => const Divider(),
                        itemBuilder: (context, index) {
                          final comment = comments[index];
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(comment.authorPenName, key: const Key('root-author')),
                              Text(comment.content, key: const Key('root-content')),
                              TextButton(
                                onPressed: () {
                                  setState(() => replyingTo = comment);
                                },
                                child: const Text('Reply Root'),
                              ),
                              if (comment.replies.isNotEmpty)
                                Container(
                                  key: const Key('nested-replies-container'),
                                  margin: const EdgeInsets.only(left: 12),
                                  child: Column(
                                    children: comment.replies.map((reply) {
                                      return Column(
                                        children: [
                                          Text(reply.authorPenName),
                                          if (reply.replyingToAuthor != null)
                                            Text(
                                              '@${reply.replyingToAuthor}',
                                              key: Key('replying-to-${reply.id}'),
                                            ),
                                          Text(reply.content),
                                          TextButton(
                                            key: Key('reply-btn-${reply.id}'),
                                            onPressed: () {
                                              setState(() => replyingTo = reply);
                                            },
                                            child: const Text('Reply Sub'),
                                          ),
                                        ],
                                      );
                                    }).toList(),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    ),
                    if (replyingTo != null)
                      Container(
                        key: const Key('reply-context-banner'),
                        child: Text('Replying to @${replyingTo!.authorPenName}'),
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify root comment is displayed
      expect(find.text('Maya Angel'), findsOneWidget);
      expect(find.text('This piece touched my heart profoundly.'), findsOneWidget);

      // Verify nested replies container exists
      expect(find.byKey(const Key('nested-replies-container')), findsOneWidget);

      // Verify replies are displayed with replyingToAuthor badges
      expect(find.text('Rian Writer'), findsOneWidget);
      expect(find.text('I felt the exact same way, Maya!'), findsOneWidget);
      expect(find.text('@Maya Angel'), findsOneWidget);

      expect(find.text('Dian Reader'), findsOneWidget);
      expect(find.text('Rian, which sentence was your favorite?'), findsOneWidget);
      expect(find.text('@Rian Writer'), findsOneWidget);

      // Tap reply button on the second reply (Dian Reader)
      await tester.tap(find.byKey(const Key('reply-btn-c-reply-2')));
      await tester.pumpAndSettle();

      // Verify banner appears replying to Dian Reader
      expect(find.byKey(const Key('reply-context-banner')), findsOneWidget);
      expect(find.text('Replying to @Dian Reader'), findsOneWidget);
    });
  });
}
