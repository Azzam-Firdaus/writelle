/// Models representing administration, analytics, moderation, and curator audit logs.
/// Ref: docs/DATABASE_AND_API.md
library;

class AdminStatsModel {
  final int totalStories;
  final int publishedStories;
  final int moderatedStories;
  final int draftStories;
  final int deletedStories;
  final int pendingReports;
  final int totalReports;
  final int totalAuthors;
  final int totalCurators;
  final int totalCategories;

  const AdminStatsModel({
    this.totalStories = 0,
    this.publishedStories = 0,
    this.moderatedStories = 0,
    this.draftStories = 0,
    this.deletedStories = 0,
    this.pendingReports = 0,
    this.totalReports = 0,
    this.totalAuthors = 0,
    this.totalCurators = 0,
    this.totalCategories = 0,
  });

  AdminStatsModel copyWith({
    int? totalStories,
    int? publishedStories,
    int? moderatedStories,
    int? draftStories,
    int? deletedStories,
    int? pendingReports,
    int? totalReports,
    int? totalAuthors,
    int? totalCurators,
    int? totalCategories,
  }) {
    return AdminStatsModel(
      totalStories: totalStories ?? this.totalStories,
      publishedStories: publishedStories ?? this.publishedStories,
      moderatedStories: moderatedStories ?? this.moderatedStories,
      draftStories: draftStories ?? this.draftStories,
      deletedStories: deletedStories ?? this.deletedStories,
      pendingReports: pendingReports ?? this.pendingReports,
      totalReports: totalReports ?? this.totalReports,
      totalAuthors: totalAuthors ?? this.totalAuthors,
      totalCurators: totalCurators ?? this.totalCurators,
      totalCategories: totalCategories ?? this.totalCategories,
    );
  }
}

class AdminReportModel {
  final String id;
  final String storyId;
  final String storyTitle;
  final String? storyContent;
  final String? reporterId;
  final String reason;
  final String? details;
  final String status; // 'pending' | 'reviewed' | 'dismissed'
  final DateTime createdAt;
  final String? storyStatus; // 'published' | 'moderated' | 'draft'
  final String? storyAuthor;
  final bool isStoryAnonymous;

  const AdminReportModel({
    required this.id,
    required this.storyId,
    required this.storyTitle,
    this.storyContent,
    this.reporterId,
    required this.reason,
    this.details,
    required this.status,
    required this.createdAt,
    this.storyStatus,
    this.storyAuthor,
    this.isStoryAnonymous = false,
  });

  factory AdminReportModel.fromMap(Map<String, dynamic> map) {
    String title = 'Untitled Scroll';
    String? content;
    String? sStatus;
    String? sAuthor;
    bool isAnon = true;

    if (map['stories'] != null && map['stories'] is Map) {
      final s = map['stories'] as Map<String, dynamic>;
      title = s['title'] as String? ?? title;
      content = s['content'] as String?;
      sStatus = s['status'] as String?;
      isAnon = s['is_anonymous'] as bool? ?? true;

      if (!isAnon && s['profiles'] != null && s['profiles'] is Map) {
        sAuthor = s['profiles']['pen_name'] as String?;
      }
    }

    return AdminReportModel(
      id: map['id'] as String,
      storyId: map['story_id'] as String,
      storyTitle: title,
      storyContent: content,
      reporterId: map['reporter_id'] as String?,
      reason: map['reason'] as String? ?? 'other',
      details: map['details'] as String?,
      status: map['status'] as String? ?? 'pending',
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : DateTime.now(),
      storyStatus: sStatus,
      storyAuthor: isAnon ? 'Anonymous Scribe' : (sAuthor ?? 'Veiled Author'),
      isStoryAnonymous: isAnon,
    );
  }

  AdminReportModel copyWith({
    String? id,
    String? storyId,
    String? storyTitle,
    String? storyContent,
    String? reporterId,
    String? reason,
    String? details,
    String? status,
    DateTime? createdAt,
    String? storyStatus,
    String? storyAuthor,
    bool? isStoryAnonymous,
  }) {
    return AdminReportModel(
      id: id ?? this.id,
      storyId: storyId ?? this.storyId,
      storyTitle: storyTitle ?? this.storyTitle,
      storyContent: storyContent ?? this.storyContent,
      reporterId: reporterId ?? this.reporterId,
      reason: reason ?? this.reason,
      details: details ?? this.details,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      storyStatus: storyStatus ?? this.storyStatus,
      storyAuthor: storyAuthor ?? this.storyAuthor,
      isStoryAnonymous: isStoryAnonymous ?? this.isStoryAnonymous,
    );
  }
}

class AdminAuthorModel {
  final String id;
  final String penName;
  final String? bio;
  final String? avatarUrl;
  final String role;
  final DateTime createdAt;
  final int storiesCount;

  const AdminAuthorModel({
    required this.id,
    required this.penName,
    this.bio,
    this.avatarUrl,
    this.role = 'user',
    required this.createdAt,
    this.storiesCount = 0,
  });

  bool get isAdmin => role == 'admin' || role == 'curator';
  bool get isSuperAdmin => role == 'admin';
  bool get isCurator => role == 'curator';

  factory AdminAuthorModel.fromMap(Map<String, dynamic> map, {int storiesCount = 0}) {
    return AdminAuthorModel(
      id: map['id'] as String,
      penName: map['pen_name'] as String? ?? 'Anonymous Scribe',
      bio: map['bio'] as String?,
      avatarUrl: map['avatar_url'] as String?,
      role: map['role'] as String? ?? 'user',
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : DateTime.now(),
      storiesCount: storiesCount,
    );
  }

  AdminAuthorModel copyWith({
    String? id,
    String? penName,
    String? bio,
    String? avatarUrl,
    String? role,
    DateTime? createdAt,
    int? storiesCount,
  }) {
    return AdminAuthorModel(
      id: id ?? this.id,
      penName: penName ?? this.penName,
      bio: bio ?? this.bio,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      storiesCount: storiesCount ?? this.storiesCount,
    );
  }
}

/// Audit log entry capturing actions performed by curators and administrators
class CuratorAuditLogModel {
  final String id;
  final String curatorId;
  final String curatorName;
  final String action; // 'moderate_story' | 'restore_story' | 'delete_story' | 'review_report' | 'dismiss_report' | 'create_category' | 'update_category' | 'delete_category' | 'assign_curator' | 'demote_curator'
  final String targetType; // 'story' | 'report' | 'category' | 'user'
  final String? targetId;
  final String? targetTitle;
  final String? details;
  final DateTime createdAt;

  const CuratorAuditLogModel({
    required this.id,
    required this.curatorId,
    required this.curatorName,
    required this.action,
    required this.targetType,
    this.targetId,
    this.targetTitle,
    this.details,
    required this.createdAt,
  });

  factory CuratorAuditLogModel.fromMap(Map<String, dynamic> map) {
    String cName = map['curator_name'] as String? ?? 'Curator';
    if (map['profiles'] != null && map['profiles'] is Map) {
      cName = map['profiles']['pen_name'] as String? ?? cName;
    }

    return CuratorAuditLogModel(
      id: map['id'] as String? ?? 'log-${DateTime.now().millisecondsSinceEpoch}',
      curatorId: map['curator_id'] as String? ?? '',
      curatorName: cName,
      action: map['action'] as String? ?? 'unknown',
      targetType: map['target_type'] as String? ?? 'general',
      targetId: map['target_id'] as String?,
      targetTitle: map['target_title'] as String?,
      details: map['details'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : DateTime.now(),
    );
  }
}
