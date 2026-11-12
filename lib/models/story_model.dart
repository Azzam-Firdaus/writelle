import '../core/cache/cover_cache.dart';
import '../core/utils/reading_time_calculator.dart';
import '../core/widgets/writtle_editorial_content.dart';

/// Story model matching public_stories_view.
/// Ref: docs/DATABASE_AND_API.md
class StoryModel {
  final String id;
  final String? userId;
  final String categoryId;
  final String categoryName;
  final String categorySlug;
  final String title;
  final String content;
  final bool isAnonymous;
  final String authorName;
  final String? authorAvatarUrl;
  final String? coverUrl;
  final DateTime? publishedAt;
  final DateTime createdAt;
  final DateTime? deletedAt;
  final bool deletedByCurator;
  final int viewsCount;
  final int likesCount;
  final bool isLiked;
  final bool isBookmarked;
  final String readingTime;
  final String subtitle;

  StoryModel({
    required this.id,
    this.userId,
    required this.categoryId,
    required this.categoryName,
    required this.categorySlug,
    required this.title,
    required this.content,
    required this.isAnonymous,
    required this.authorName,
    this.authorAvatarUrl,
    this.coverUrl,
    this.publishedAt,
    required this.createdAt,
    this.deletedAt,
    this.deletedByCurator = false,
    this.viewsCount = 0,
    this.likesCount = 0,
    this.isLiked = false,
    this.isBookmarked = false,
    String? readingTime,
    String? subtitle,
  })  : readingTime = readingTime ?? ReadingTimeCalculator.calculate(content),
        subtitle = subtitle ?? WrittleEditorialParser.extractSubtitle(content);

  /// Helper to determine if the story has been soft-deleted to 14-day retention trash
  bool get isDeleted => deletedAt != null;

  /// Number of days remaining before permanent deletion under the 14-day retention policy
  int get daysUntilPermanentDeletion {
    if (deletedAt == null) return 14;
    final deadline = deletedAt!.add(const Duration(days: 14));
    final remaining = deadline.difference(DateTime.now()).inDays;
    return remaining > 0 ? remaining : 0;
  }

  /// Whether the 14-day retention grace period has completely lapsed
  bool get isPermanentDeletionExpired {
    if (deletedAt == null) return false;
    return DateTime.now().isAfter(deletedAt!.add(const Duration(days: 14)));
  }

  factory StoryModel.fromMap(Map<String, dynamic> map, {bool isLiked = false, bool isBookmarked = false}) {
    final storyId = map['id'] as String;
    final dbCover = map['cover_url'] as String?;
    final resolvedCover = (dbCover != null && dbCover.trim().isNotEmpty)
        ? dbCover.trim()
        : CoverCache.get(storyId);
    final rawContent = map['content'] as String? ?? '';

    return StoryModel(
      id: storyId,
      userId: map['user_id'] as String?,
      categoryId: map['category_id'] as String? ?? '',
      categoryName: map['category_name'] as String? ?? 'General',
      categorySlug: map['category_slug'] as String? ?? 'general',
      title: map['title'] as String? ?? '',
      content: rawContent,
      isAnonymous: map['is_anonymous'] as bool? ?? true,
      authorName: map['author_name'] as String? ?? 'Anonymous',
      authorAvatarUrl: map['author_avatar_url'] as String?,
      coverUrl: resolvedCover,
      publishedAt: map['published_at'] != null ? DateTime.parse(map['published_at'] as String) : null,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : DateTime.now(),
      deletedAt: map['deleted_at'] != null ? DateTime.tryParse(map['deleted_at'] as String) : null,
      deletedByCurator: map['deleted_by_curator'] as bool? ?? false,
      viewsCount: (map['views_count'] as num?)?.toInt() ?? 0,
      likesCount: (map['likes_count'] as num?)?.toInt() ?? 0,
      isLiked: isLiked,
      isBookmarked: isBookmarked,
      readingTime: ReadingTimeCalculator.calculate(rawContent),
      subtitle: WrittleEditorialParser.extractSubtitle(rawContent),
    );
  }

  StoryModel copyWith({
    String? id,
    String? userId,
    String? categoryId,
    String? categoryName,
    String? categorySlug,
    String? title,
    String? content,
    bool? isAnonymous,
    String? authorName,
    String? authorAvatarUrl,
    String? coverUrl,
    DateTime? publishedAt,
    DateTime? createdAt,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
    bool? deletedByCurator,
    int? viewsCount,
    int? likesCount,
    bool? isLiked,
    bool? isBookmarked,
    String? readingTime,
    String? subtitle,
  }) {
    final updatedContent = content ?? this.content;
    return StoryModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      categorySlug: categorySlug ?? this.categorySlug,
      title: title ?? this.title,
      content: updatedContent,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      authorName: authorName ?? this.authorName,
      authorAvatarUrl: authorAvatarUrl ?? this.authorAvatarUrl,
      coverUrl: coverUrl ?? this.coverUrl,
      publishedAt: publishedAt ?? this.publishedAt,
      createdAt: createdAt ?? this.createdAt,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
      deletedByCurator: deletedByCurator ?? this.deletedByCurator,
      viewsCount: viewsCount ?? this.viewsCount,
      likesCount: likesCount ?? this.likesCount,
      isLiked: isLiked ?? this.isLiked,
      isBookmarked: isBookmarked ?? this.isBookmarked,
      readingTime: readingTime ?? (content != null ? ReadingTimeCalculator.calculate(updatedContent) : this.readingTime),
      subtitle: subtitle ?? (content != null ? WrittleEditorialParser.extractSubtitle(updatedContent) : this.subtitle),
    );
  }
}
