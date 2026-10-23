import '../core/utils/reading_time_calculator.dart';

/// Story model matching public_stories_view.
/// Ref: docs/DATABASE_AND_API.md
class StoryModel {
  final String id;
  final String categoryId;
  final String categoryName;
  final String categorySlug;
  final String title;
  final String content;
  final bool isAnonymous;
  final String authorName;
  final String? authorAvatarUrl;
  final DateTime? publishedAt;
  final DateTime createdAt;
  final int viewsCount;
  final int likesCount;
  final int commentsCount;
  final bool isLiked;
  final bool isBookmarked;

  const StoryModel({
    required this.id,
    required this.categoryId,
    required this.categoryName,
    required this.categorySlug,
    required this.title,
    required this.content,
    required this.isAnonymous,
    required this.authorName,
    this.authorAvatarUrl,
    this.publishedAt,
    required this.createdAt,
    this.viewsCount = 0,
    this.likesCount = 0,
    this.commentsCount = 0,
    this.isLiked = false,
    this.isBookmarked = false,
  });

  String get readingTime => ReadingTimeCalculator.calculate(content);

  factory StoryModel.fromMap(Map<String, dynamic> map, {bool isLiked = false, bool isBookmarked = false}) {
    return StoryModel(
      id: map['id'] as String,
      categoryId: map['category_id'] as String,
      categoryName: map['category_name'] as String? ?? 'General',
      categorySlug: map['category_slug'] as String? ?? 'general',
      title: map['title'] as String,
      content: map['content'] as String,
      isAnonymous: map['is_anonymous'] as bool? ?? true,
      authorName: map['author_name'] as String? ?? 'Anonymous',
      authorAvatarUrl: map['author_avatar_url'] as String?,
      publishedAt: map['published_at'] != null ? DateTime.parse(map['published_at'] as String) : null,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : DateTime.now(),
      viewsCount: (map['views_count'] as num?)?.toInt() ?? 0,
      likesCount: (map['likes_count'] as num?)?.toInt() ?? 0,
      commentsCount: (map['comments_count'] as num?)?.toInt() ?? 0,
      isLiked: isLiked,
      isBookmarked: isBookmarked,
    );
  }

  StoryModel copyWith({
    String? id,
    String? categoryId,
    String? categoryName,
    String? categorySlug,
    String? title,
    String? content,
    bool? isAnonymous,
    String? authorName,
    String? authorAvatarUrl,
    DateTime? publishedAt,
    DateTime? createdAt,
    int? viewsCount,
    int? likesCount,
    int? commentsCount,
    bool? isLiked,
    bool? isBookmarked,
  }) {
    return StoryModel(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      categorySlug: categorySlug ?? this.categorySlug,
      title: title ?? this.title,
      content: content ?? this.content,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      authorName: authorName ?? this.authorName,
      authorAvatarUrl: authorAvatarUrl ?? this.authorAvatarUrl,
      publishedAt: publishedAt ?? this.publishedAt,
      createdAt: createdAt ?? this.createdAt,
      viewsCount: viewsCount ?? this.viewsCount,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      isLiked: isLiked ?? this.isLiked,
      isBookmarked: isBookmarked ?? this.isBookmarked,
    );
  }
}
