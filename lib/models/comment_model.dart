/// Comment model representing discussions on stories.
/// Ref: docs/DATABASE_AND_API.md
class CommentModel {
  final String id;
  final String storyId;
  final String userId;
  final String content;
  final String authorPenName;
  final DateTime createdAt;

  const CommentModel({
    required this.id,
    required this.storyId,
    required this.userId,
    required this.content,
    required this.authorPenName,
    required this.createdAt,
  });

  factory CommentModel.fromMap(Map<String, dynamic> map) {
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
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : DateTime.now(),
    );
  }
}
