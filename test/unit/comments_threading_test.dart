import 'package:flutter_test/flutter_test.dart';
import 'package:writtle/models/comment_model.dart';

void main() {
  group('Comments Threading & Nesting Tests', () {
    test('CommentModel supports replyingToAuthor and nested replies', () {
      final rootComment = CommentModel(
        id: 'c-root',
        storyId: 's-1',
        userId: 'u-1',
        content: 'This was a wonderful read!',
        authorPenName: 'Alice',
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      );

      final reply1 = CommentModel(
        id: 'c-reply-1',
        storyId: 's-1',
        userId: 'u-2',
        content: 'I agree with your reflection.',
        authorPenName: 'Bob',
        parentCommentId: 'c-root',
        replyingToAuthor: 'Alice',
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
      );

      final reply2 = CommentModel(
        id: 'c-reply-2',
        storyId: 's-1',
        userId: 'u-3',
        content: 'Bob, which chapter did you like most?',
        authorPenName: 'Charlie',
        parentCommentId: 'c-reply-1',
        replyingToAuthor: 'Bob',
        createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
      );

      final rootWithReplies = rootComment.copyWith(replies: [reply1, reply2]);

      expect(rootWithReplies.id, equals('c-root'));
      expect(rootWithReplies.replies.length, equals(2));
      expect(rootWithReplies.replies[0].authorPenName, equals('Bob'));
      expect(rootWithReplies.replies[0].replyingToAuthor, equals('Alice'));
      expect(rootWithReplies.replies[1].authorPenName, equals('Charlie'));
      expect(rootWithReplies.replies[1].replyingToAuthor, equals('Bob'));
    });

    test('CommentModel serialization preserves parentCommentId and replyingToAuthor', () {
      final map = {
        'id': 'c-child-10',
        'story_id': 's-100',
        'user_id': 'u-99',
        'content': 'Heartfelt echo.',
        'parent_comment_id': 'c-parent-5',
        'replying_to_author': 'SeniorWriter',
        'created_at': DateTime.now().toIso8601String(),
        'profiles': {'pen_name': 'JuniorWriter'},
      };

      final comment = CommentModel.fromMap(map);

      expect(comment.id, equals('c-child-10'));
      expect(comment.parentCommentId, equals('c-parent-5'));
      expect(comment.replyingToAuthor, equals('SeniorWriter'));
      expect(comment.authorPenName, equals('JuniorWriter'));
    });
  });
}
