/// Comment model representing discussions on stories.
/// Ref: docs/DATABASE_AND_API.md
class CommentModel {
  final String id;
  final String storyId;
  final String userId;
  final String content;
  final String authorPenName;
  final DateTime createdAt;
  final String? parentCommentId;
  final String? replyingToAuthor;
  final List<CommentModel> replies;

  const CommentModel({
    required this.id,
    required this.storyId,
    required this.userId,
    required this.content,
    required this.authorPenName,
    required this.createdAt,
    this.parentCommentId,
    this.replyingToAuthor,
    this.replies = const [],
  });

  factory CommentModel.fromMap(
    Map<String, dynamic> map, {
    List<CommentModel> replies = const [],
    String? replyingToAuthor,
  }) {
    String penName = 'Anonymous';
    if (map['profiles'] != null && map['profiles'] is Map) {
      penName = map['profiles']['pen_name'] as String? ?? 'Anonymous';
    }

    return CommentModel(
      id: map['id'] as String,
      storyId: map['story_id'] as String,
      userId: map['user_id'] as String,
      content: map['content'] as String,
      authorPenName: penName,
      parentCommentId: map['parent_comment_id'] as String?,
      replyingToAuthor: replyingToAuthor ?? map['replying_to_author'] as String?,
      replies: replies,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : DateTime.now(),
    );
  }

  CommentModel copyWith({
    String? id,
    String? storyId,
    String? userId,
    String? content,
    String? authorPenName,
    DateTime? createdAt,
    String? parentCommentId,
    String? replyingToAuthor,
    List<CommentModel>? replies,
  }) {
    return CommentModel(
      id: id ?? this.id,
      storyId: storyId ?? this.storyId,
      userId: userId ?? this.userId,
      content: content ?? this.content,
      authorPenName: authorPenName ?? this.authorPenName,
      createdAt: createdAt ?? this.createdAt,
      parentCommentId: parentCommentId ?? this.parentCommentId,
      replyingToAuthor: replyingToAuthor ?? this.replyingToAuthor,
      replies: replies ?? this.replies,
    );
  }

  String get timeAgo {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }
}
