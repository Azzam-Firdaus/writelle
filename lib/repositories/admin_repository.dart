import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/admin_models.dart';
import '../models/category_model.dart';
import '../models/story_model.dart';

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return AdminRepository();
});

/// Repository handling all Curator / Admin CMS data operations.
/// Ref: docs/DATABASE_AND_API.md
class AdminRepository {
  final SupabaseClient? _customClient;

  AdminRepository({SupabaseClient? supabase}) : _customClient = supabase;

  SupabaseClient? get _supabase {
    if (_customClient != null) return _customClient;
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  // Local fallback storage for interactive testing or RLS fallback
  final List<AdminReportModel> _localReports = [];
  final List<CategoryModel> _localCategories = [];
  final List<CuratorAuditLogModel> _localAuditLogs = [];
  final List<AdminAuthorModel> _localAuthors = [];

  static final RegExp _uuidRegex = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
    caseSensitive: false,
  );

  bool _isValidUuid(String str) {
    return _uuidRegex.hasMatch(str.trim());
  }

  /// Fetches comprehensive platform metrics concurrently
  Future<AdminStatsModel> getStats() async {
    final client = _supabase;
    if (client == null) {
      return const AdminStatsModel(
        totalStories: 12,
        publishedStories: 10,
        moderatedStories: 1,
        draftStories: 1,
        pendingReports: 2,
        totalReports: 3,
        totalAuthors: 8,
        totalCurators: 2,
        totalCategories: 6,
      );
    }

    int totalStories = 0;
    int publishedStories = 0;
    int moderatedStories = 0;
    int draftStories = 0;
    int deletedStories = 0;
    int pendingReports = 0;
    int totalReports = 0;
    int totalAuthors = 0;
    int totalCurators = 0;
    int totalCategories = 0;

    // Trigger auto-purge of any expired 14-day deleted stories in the background
    unawaited(purgeExpiredDeletedStories());

    // Execute all 5 metrics queries in parallel to minimize network latency
    final results = await Future.wait([
      client.from('stories').select('id, status').isFilter('deleted_at', null).then((v) => v as List).catchError((e) {
        debugPrint('AdminRepository.getStats stories query fallback: $e');
        return <dynamic>[];
      }),
      client.from('stories').select('id').not('deleted_at', 'is', null).then((v) => v as List).catchError((e) {
        debugPrint('AdminRepository.getStats deleted stories query fallback: $e');
        return <dynamic>[];
      }),
      client.from('reports').select('id, status').then((v) => v as List).catchError((e) {
        debugPrint('AdminRepository.getStats reports query fallback: $e');
        return <dynamic>[];
      }),
      client.from('profiles').select('id, role').then((v) => v as List).catchError((e) {
        debugPrint('AdminRepository.getStats profiles query fallback: $e');
        return <dynamic>[];
      }),
      client.from('categories').select('id').then((v) => v as List).catchError((e) {
        debugPrint('AdminRepository.getStats categories query fallback: $e');
        return <dynamic>[];
      }),
    ]);

    // 1. Stories breakdown
    final storiesRes = results[0];
    totalStories = storiesRes.length;
    for (final item in storiesRes) {
      final s = item['status'] as String? ?? 'published';
      if (s == 'published') publishedStories++;
      if (s == 'moderated') moderatedStories++;
      if (s == 'draft') draftStories++;
    }

    // 2. Deleted stories in 14-day retention
    deletedStories = results[1].length;

    // 3. Reports breakdown
    final reportsRes = results[2];
    totalReports = reportsRes.length;
    for (final item in reportsRes) {
      final s = item['status'] as String? ?? 'pending';
      if (s == 'pending') pendingReports++;
    }

    // 4. Authors & Curators breakdown
    final authorsRes = results[3];
    totalAuthors = authorsRes.length;
    for (final item in authorsRes) {
      final r = item['role'] as String? ?? 'user';
      if (r == 'curator' || r == 'admin') {
        totalCurators++;
      }
    }

    // 5. Categories count
    totalCategories = results[4].length;

    return AdminStatsModel(
      totalStories: totalStories,
      publishedStories: publishedStories,
      moderatedStories: moderatedStories,
      draftStories: draftStories,
      deletedStories: deletedStories,
      pendingReports: pendingReports,
      totalReports: totalReports,
      totalAuthors: totalAuthors,
      totalCurators: totalCurators,
      totalCategories: totalCategories,
    );
  }

  /// Records an audit log for an action performed by a curator or administrator
  Future<void> recordAuditLog({
    required String action,
    required String targetType,
    String? targetId,
    String? targetTitle,
    String? details,
  }) async {
    final client = _supabase;
    final currentUser = client?.auth.currentUser;
    String curatorName = 'Curator';

    if (client != null && currentUser != null) {
      try {
        final profileRes = await client
            .from('profiles')
            .select('pen_name')
            .eq('id', currentUser.id)
            .maybeSingle();
        if (profileRes != null && profileRes['pen_name'] != null) {
          curatorName = profileRes['pen_name'] as String;
        }
      } catch (_) {}
    }

    final newLog = CuratorAuditLogModel(
      id: 'log-${DateTime.now().millisecondsSinceEpoch}',
      curatorId: currentUser?.id ?? 'system',
      curatorName: curatorName,
      action: action,
      targetType: targetType,
      targetId: targetId,
      targetTitle: targetTitle,
      details: details,
      createdAt: DateTime.now(),
    );

    // Keep in local cache
    _localAuditLogs.removeWhere((l) => l.id == newLog.id);
    _localAuditLogs.insert(0, newLog);

    if (client == null || currentUser == null) return;

    try {
      // 1. Try dedicated RPC first (bypasses RLS issues safely)
      try {
        await client.rpc('record_audit_log_admin', params: {
          'p_action': action,
          'p_target_type': targetType,
          'p_target_id': targetId,
          'p_target_title': targetTitle,
          'p_details': details,
        });
        debugPrint('AdminRepository.recordAuditLog RPC succeeded');
        return;
      } catch (rpcErr) {
        debugPrint('record_audit_log_admin RPC failed/absent ($rpcErr), falling back to direct insert');
      }

      // 2. Direct table insert fallback
      await client.from('curator_audit_logs').insert({
        'curator_id': currentUser.id,
        'curator_name': curatorName,
        'action': action,
        'target_type': targetType,
        'target_id': targetId,
        'target_title': targetTitle,
        'details': details,
      });
      debugPrint('AdminRepository.recordAuditLog direct insert succeeded');
    } catch (e) {
      debugPrint('AdminRepository.recordAuditLog fallback to local: $e');
    }
  }

  /// Fetches audit logs for supervisory tracking
  Future<List<CuratorAuditLogModel>> getAuditLogs({
    String? actionFilter,
    String? targetTypeFilter,
  }) async {
    final client = _supabase;
    if (client == null) {
      if (_localAuditLogs.isEmpty) _seedMockAuditLogs();
      return _filterAuditLogs(_localAuditLogs, actionFilter, targetTypeFilter);
    }

    try {
      // Direct select * prevents PostgREST relationship schema cache failures
      var filterBuilder = client
          .from('curator_audit_logs')
          .select('*');

      if (actionFilter != null && actionFilter != 'all') {
        filterBuilder = filterBuilder.eq('action', actionFilter);
      }
      if (targetTypeFilter != null && targetTypeFilter != 'all') {
        filterBuilder = filterBuilder.eq('target_type', targetTypeFilter);
      }

      final response = await filterBuilder.order('created_at', ascending: false).limit(100);
      final logs = (response as List)
          .map((item) => CuratorAuditLogModel.fromMap(item as Map<String, dynamic>))
          .toList();

      if (logs.isNotEmpty) {
        for (final l in logs) {
          if (!_localAuditLogs.any((x) => x.id == l.id)) {
            _localAuditLogs.add(l);
          }
        }
        return logs;
      }

      if (_localAuditLogs.isNotEmpty) {
        return _filterAuditLogs(_localAuditLogs, actionFilter, targetTypeFilter);
      }

      return logs;
    } catch (e) {
      debugPrint('AdminRepository.getAuditLogs error: $e');
      if (_localAuditLogs.isNotEmpty) {
        return _filterAuditLogs(_localAuditLogs, actionFilter, targetTypeFilter);
      }
      return [];
    }
  }

  List<CuratorAuditLogModel> _filterAuditLogs(
    List<CuratorAuditLogModel> list,
    String? actionFilter,
    String? targetTypeFilter,
  ) {
    return list.where((log) {
      if (actionFilter != null && actionFilter != 'all' && log.action != actionFilter) {
        return false;
      }
      if (targetTypeFilter != null && targetTypeFilter != 'all' && log.targetType != targetTypeFilter) {
        return false;
      }
      return true;
    }).toList();
  }

  /// Updates an author's role (e.g. appoint as 'curator' or demote to 'user')
  Future<void> updateAuthorRole({
    required String authorId,
    required String newRole,
    required String authorPenName,
  }) async {
    // 1. Update in local cache if present
    for (int i = 0; i < _localAuthors.length; i++) {
      if (_localAuthors[i].id == authorId) {
        _localAuthors[i] = _localAuthors[i].copyWith(role: newRole);
      }
    }

    final client = _supabase;
    if (client != null && _isValidUuid(authorId)) {
      try {
        // Try calling the dedicated RPC function first (bypasses RLS issues safely)
        try {
          await client.rpc('set_user_role', params: {
            'target_user_id': authorId,
            'target_role': newRole,
          });
          debugPrint('AdminRepository.updateAuthorRole RPC set_user_role succeeded');
        } catch (rpcErr) {
          debugPrint('set_user_role RPC failed ($rpcErr), attempting direct update');
          final res = await client
              .from('profiles')
              .update({'role': newRole, 'updated_at': DateTime.now().toIso8601String()})
              .eq('id', authorId)
              .select();

          if ((res as List).isEmpty) {
            throw Exception(
              'Profile update was rejected by database permissions (0 rows affected). '
              'Please ensure the Supabase Admin RLS migration or set_user_role RPC has been executed.',
            );
          }
        }
      } catch (e) {
        debugPrint('AdminRepository.updateAuthorRole error: $e');
        rethrow;
      }
    }

    String actionLabel = 'assign_curator';
    if (newRole == 'user') actionLabel = 'demote_curator';
    if (newRole == 'admin') actionLabel = 'assign_admin';

    await recordAuditLog(
      action: actionLabel,
      targetType: 'user',
      targetId: authorId,
      targetTitle: authorPenName,
      details: 'Role updated to $newRole',
    );
  }

  /// Fetches moderation reports with joined story data
  Future<List<AdminReportModel>> getReports({String? statusFilter}) async {
    final client = _supabase;
    if (client == null) {
      if (_localReports.isEmpty) {
        _seedMockReports();
      }
      return _localReports
          .where((r) => statusFilter == null || statusFilter == 'all' || r.status == statusFilter)
          .toList();
    }

    try {
      var filterBuilder = client
          .from('reports')
          .select('*, stories:story_id(id, title, content, status, is_anonymous, user_id, profiles:user_id(pen_name))');

      if (statusFilter != null && statusFilter != 'all') {
        filterBuilder = filterBuilder.eq('status', statusFilter);
      }

      final response = await filterBuilder.order('created_at', ascending: false);
      final reports = (response as List)
          .map((item) => AdminReportModel.fromMap(item as Map<String, dynamic>))
          .toList();

      return reports;
    } catch (e) {
      debugPrint('AdminRepository.getReports error: $e');
      return [];
    }
  }

  /// Updates report status ('reviewed' | 'dismissed' | 'pending')
  Future<void> updateReportStatus(String reportId, String newStatus, {String? storyTitle}) async {
    // Update local cache
    final idx = _localReports.indexWhere((r) => r.id == reportId);
    if (idx != -1) {
      _localReports[idx] = _localReports[idx].copyWith(status: newStatus);
    }

    final client = _supabase;
    if (client != null && _isValidUuid(reportId)) {
      try {
        try {
          await client.rpc('update_report_status_admin', params: {
            'target_report_id': reportId,
            'new_status': newStatus,
          });
        } catch (_) {
          await client
              .from('reports')
              .update({'status': newStatus})
              .eq('id', reportId);
        }
      } catch (e) {
        debugPrint('AdminRepository.updateReportStatus error: $e');
      }
    }

    await recordAuditLog(
      action: newStatus == 'reviewed' ? 'review_report' : 'dismiss_report',
      targetType: 'report',
      targetId: reportId,
      targetTitle: storyTitle,
      details: 'Report status marked as $newStatus',
    );
  }

  /// Sets story status to 'moderated' (hidden from public feed) or restores it to 'published'
  Future<void> moderateStory(
    String storyId, {
    bool unmoderate = false,
    String? storyTitle,
  }) async {
    final newStatus = unmoderate ? 'published' : 'moderated';

    // Update in local reports cache
    for (int i = 0; i < _localReports.length; i++) {
      if (_localReports[i].storyId == storyId) {
        _localReports[i] = _localReports[i].copyWith(storyStatus: newStatus);
      }
    }

    final client = _supabase;
    if (client != null && _isValidUuid(storyId)) {
      try {
        try {
          await client.rpc('moderate_story_admin', params: {
            'target_story_id': storyId,
            'new_status': newStatus,
          });
          debugPrint('AdminRepository.moderateStory RPC succeeded');
        } catch (rpcErr) {
          debugPrint('moderate_story_admin RPC failed ($rpcErr), attempting direct table update');
          final res = await client
              .from('stories')
              .update({'status': newStatus, 'updated_at': DateTime.now().toIso8601String()})
              .eq('id', storyId)
              .select();

          if ((res as List).isEmpty) {
            throw Exception(
              'Story moderation update was rejected by database permissions (0 rows affected). '
              'Please ensure Admin RLS policies or moderate_story_admin RPC has been executed.',
            );
          }
        }
      } catch (e) {
        debugPrint('AdminRepository.moderateStory error: $e');
        rethrow;
      }
    }

    await recordAuditLog(
      action: unmoderate ? 'restore_story' : 'moderate_story',
      targetType: 'story',
      targetId: storyId,
      targetTitle: storyTitle,
      details: unmoderate ? 'Scroll restored to public sanctuary' : 'Scroll veiled under moderation shelter',
    );
  }

  /// Soft deletes a story into 14-day retention trash (by curator/admin)
  Future<void> softDeleteStory(String storyId, {String? storyTitle}) async {
    final client = _supabase;
    if (client != null) {
      try {
        // 1. Try dedicated RPC if available
        try {
          await client.rpc('soft_delete_story_admin', params: {
            'target_story_id': storyId,
          });
          debugPrint('AdminRepository.softDeleteStory RPC succeeded');
        } catch (_) {
          // 2. Direct table update fallback
          await client
              .from('stories')
              .update({
                'deleted_at': DateTime.now().toIso8601String(),
                'updated_at': DateTime.now().toIso8601String(),
              })
              .eq('id', storyId);
        }
      } catch (e) {
        debugPrint('AdminRepository.softDeleteStory error: $e');
        rethrow;
      }
    }

    await recordAuditLog(
      action: 'delete_story',
      targetType: 'story',
      targetId: storyId,
      targetTitle: storyTitle,
      details: 'Scroll moved to 14-day retention trash by curator/admin',
    );
  }

  /// Restores a soft-deleted story from 14-day trash back to public sanctuary
  Future<void> restoreStory(String storyId, {String? storyTitle}) async {
    final client = _supabase;
    if (client != null) {
      try {
        try {
          await client.rpc('restore_story_admin', params: {
            'target_story_id': storyId,
          });
          debugPrint('AdminRepository.restoreStory RPC succeeded');
        } catch (_) {
          await client
              .from('stories')
              .update({
                'deleted_at': null,
                'updated_at': DateTime.now().toIso8601String(),
              })
              .eq('id', storyId);
        }
      } catch (e) {
        debugPrint('AdminRepository.restoreStory error: $e');
        rethrow;
      }
    }

    await recordAuditLog(
      action: 'restore_story',
      targetType: 'story',
      targetId: storyId,
      targetTitle: storyTitle,
      details: 'Scroll restored to sanctuary from 14-day retention',
    );
  }

  /// Permanently deletes a story from the sanctuary database (admin/curator override)
  Future<void> permanentlyDeleteStory(String storyId, {String? storyTitle}) async {
    final client = _supabase;
    if (client != null) {
      try {
        try {
          await client.rpc('hard_delete_story_admin', params: {
            'target_story_id': storyId,
          });
          debugPrint('AdminRepository.permanentlyDeleteStory RPC succeeded');
        } catch (_) {
          await client.from('stories').delete().eq('id', storyId);
        }
      } catch (e) {
        debugPrint('AdminRepository.permanentlyDeleteStory error: $e');
        rethrow;
      }
    }

    await recordAuditLog(
      action: 'permanent_delete_story',
      targetType: 'story',
      targetId: storyId,
      targetTitle: storyTitle,
      details: 'Scroll permanently purged from sanctuary database',
    );
  }

  /// Automatically purges stories whose 14-day retention grace period has elapsed
  Future<int> purgeExpiredDeletedStories() async {
    final client = _supabase;
    if (client == null) return 0;

    try {
      // 1. Try dedicated RPC cleanup
      try {
        final res = await client.rpc('cleanup_expired_deleted_stories');
        if (res is Map && res['purged_count'] != null) {
          final count = (res['purged_count'] as num).toInt();
          if (count > 0) {
            debugPrint('[AdminRepository] Cleaned up $count stories expired past 14 days.');
          }
          return count;
        }
      } catch (_) {}

      // 2. Direct table cleanup fallback
      final cutoff = DateTime.now().subtract(const Duration(days: 14)).toIso8601String();
      final res = await client
          .from('stories')
          .delete()
          .not('deleted_at', 'is', null)
          .lt('deleted_at', cutoff)
          .select('id');
      final count = (res as List).length;
      if (count > 0) {
        debugPrint('[AdminRepository] Direct purge removed $count stories expired past 14 days.');
      }
      return count;
    } catch (e) {
      debugPrint('[AdminRepository] purgeExpiredDeletedStories error: $e');
      return 0;
    }
  }

  /// Fetches all stories for Admin CMS catalogue with filtering and search
  Future<List<StoryModel>> getAllStoriesAdmin({
    String? statusFilter,
    String? searchQuery,
  }) async {
    final client = _supabase;
    if (client == null) return [];

    // Trigger auto-purge of any expired 14-day deleted stories in the background
    unawaited(purgeExpiredDeletedStories());

    try {
      var filterBuilder = client
          .from('stories')
          .select('*, categories:category_id(name, slug), profiles:user_id(pen_name, avatar_url)');

      if (statusFilter == 'deleted') {
        filterBuilder = filterBuilder.not('deleted_at', 'is', null);
      } else {
        filterBuilder = filterBuilder.isFilter('deleted_at', null);

        if (statusFilter != null && statusFilter != 'all') {
          filterBuilder = filterBuilder.eq('status', statusFilter);
        }
      }

      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        filterBuilder = filterBuilder.ilike('title', '%${searchQuery.trim()}%');
      }

      final response = statusFilter == 'deleted'
          ? await filterBuilder.order('deleted_at', ascending: false)
          : await filterBuilder.order('created_at', ascending: false);

      final stories = <StoryModel>[];

      for (final item in response as List) {
        final map = item as Map<String, dynamic>;
        final isAnon = map['is_anonymous'] as bool? ?? true;

        String authorName = 'Anonymous Scribe';
        String? authorAvatar;
        if (!isAnon && map['profiles'] != null && map['profiles'] is Map) {
          authorName = map['profiles']['pen_name'] as String? ?? 'Veiled Author';
          authorAvatar = map['profiles']['avatar_url'] as String?;
        }

        String catName = 'General';
        String catSlug = 'general';
        if (map['categories'] != null && map['categories'] is Map) {
          catName = map['categories']['name'] as String? ?? 'General';
          catSlug = map['categories']['slug'] as String? ?? 'general';
        }

        stories.add(
          StoryModel(
            id: map['id'] as String,
            userId: map['user_id'] as String?,
            categoryId: map['category_id'] as String? ?? '',
            categoryName: catName,
            categorySlug: catSlug,
            title: map['title'] as String? ?? 'Untitled Scroll',
            content: map['content'] as String? ?? '',
            isAnonymous: isAnon,
            authorName: authorName,
            authorAvatarUrl: authorAvatar,
            coverUrl: map['cover_url'] as String?,
            publishedAt: map['published_at'] != null ? DateTime.tryParse(map['published_at'] as String) : null,
            createdAt: map['created_at'] != null ? DateTime.tryParse(map['created_at'] as String) ?? DateTime.now() : DateTime.now(),
            deletedAt: map['deleted_at'] != null ? DateTime.tryParse(map['deleted_at'] as String) : null,
            viewsCount: (map['views_count'] as num?)?.toInt() ?? 0,
            likesCount: (map['likes_count'] as num?)?.toInt() ?? 0,
            commentsCount: (map['comments_count'] as num?)?.toInt() ?? 0,
          ),
        );
      }

      return stories;
    } catch (e) {
      debugPrint('AdminRepository.getAllStoriesAdmin error: $e');
      return [];
    }
  }

  /// Fetches all categories
  Future<List<CategoryModel>> getCategories() async {
    final client = _supabase;
    if (client == null) return _localCategories;

    try {
      final response = await client
          .from('categories')
          .select()
          .order('name', ascending: true);

      final list = (response as List)
          .map((item) => CategoryModel.fromMap(item as Map<String, dynamic>))
          .toList();

      if (list.isNotEmpty) {
        _localCategories.clear();
        _localCategories.addAll(list);
      }
      return list;
    } catch (e) {
      debugPrint('AdminRepository.getCategories error: $e');
      return _localCategories;
    }
  }

  /// Creates a new category
  Future<CategoryModel> createCategory({
    required String name,
    String? description,
  }) async {
    final client = _supabase;
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) throw Exception('Realm name cannot be empty.');

    final slug = trimmedName
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');

    final newCat = CategoryModel(
      id: 'cat-${DateTime.now().millisecondsSinceEpoch}',
      name: trimmedName,
      slug: slug.isEmpty ? 'realm-${DateTime.now().millisecondsSinceEpoch}' : slug,
      description: description?.trim(),
    );

    if (client == null) {
      _localCategories.add(newCat);
      await recordAuditLog(
        action: 'create_category',
        targetType: 'category',
        targetId: newCat.id,
        targetTitle: newCat.name,
        details: 'Forged realm #${newCat.slug}',
      );
      return newCat;
    }

    try {
      final insertData = {
        'name': trimmedName,
        'slug': slug.isEmpty ? 'realm-${DateTime.now().millisecondsSinceEpoch}' : slug,
        'description': description?.trim(),
      };
      final res = await client.from('categories').insert(insertData).select().single();
      final cat = CategoryModel.fromMap(res);
      _localCategories.add(cat);
      await recordAuditLog(
        action: 'create_category',
        targetType: 'category',
        targetId: cat.id,
        targetTitle: cat.name,
        details: 'Forged realm #${cat.slug}',
      );
      return cat;
    } catch (e) {
      debugPrint('AdminRepository.createCategory error (adding to local fallback): $e');
      _localCategories.add(newCat);
      await recordAuditLog(
        action: 'create_category',
        targetType: 'category',
        targetId: newCat.id,
        targetTitle: newCat.name,
        details: 'Forged realm #${newCat.slug}',
      );
      return newCat;
    }
  }

  /// Updates an existing category
  Future<void> updateCategory({
    required String id,
    required String name,
    String? description,
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) throw Exception('Realm name cannot be empty.');

    // Update in local cache
    final idx = _localCategories.indexWhere((c) => c.id == id);
    if (idx != -1) {
      _localCategories[idx] = CategoryModel(
        id: id,
        name: trimmedName,
        slug: _localCategories[idx].slug,
        description: description?.trim(),
      );
    }

    final client = _supabase;
    if (client != null) {
      try {
        await client.from('categories').update({
          'name': trimmedName,
          'description': description?.trim(),
        }).eq('id', id);
      } catch (e) {
        debugPrint('AdminRepository.updateCategory error: $e');
      }
    }

    await recordAuditLog(
      action: 'update_category',
      targetType: 'category',
      targetId: id,
      targetTitle: trimmedName,
      details: 'Updated realm details',
    );
  }

  /// Deletes a category
  Future<void> deleteCategory(String id, {String? categoryName}) async {
    _localCategories.removeWhere((c) => c.id == id);

    final client = _supabase;
    if (client != null) {
      try {
        await client.from('categories').delete().eq('id', id);
      } catch (e) {
        debugPrint('AdminRepository.deleteCategory error: $e');
        rethrow;
      }
    }

    await recordAuditLog(
      action: 'delete_category',
      targetType: 'category',
      targetId: id,
      targetTitle: categoryName,
      details: 'Dissolved realm from sanctuary',
    );
  }

  /// Fetches registered authors directory
  Future<List<AdminAuthorModel>> getAllAuthorsAdmin({String? searchQuery}) async {
    final client = _supabase;
    if (client == null) {
      if (_localAuthors.isEmpty) {
        _seedMockAuthors();
      }
      return _localAuthors.where((a) {
        if (searchQuery == null || searchQuery.trim().isEmpty) return true;
        return a.penName.toLowerCase().contains(searchQuery.trim().toLowerCase());
      }).toList();
    }

    try {
      var filterBuilder = client
          .from('profiles')
          .select('id, pen_name, bio, avatar_url, role, created_at');

      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        filterBuilder = filterBuilder.ilike('pen_name', '%${searchQuery.trim()}%');
      }

      final response = await filterBuilder.order('created_at', ascending: false);
      final authors = <AdminAuthorModel>[];

      for (final item in response as List) {
        final authorId = item['id'] as String;
        int count = 0;
        try {
          final countRes = await client
              .from('stories')
              .select('id')
              .eq('user_id', authorId)
              .isFilter('deleted_at', null);
          count = countRes.length;
        } catch (_) {}

        authors.add(AdminAuthorModel.fromMap(item as Map<String, dynamic>, storiesCount: count));
      }

      // Sync local cache
      _localAuthors.clear();
      _localAuthors.addAll(authors);

      return authors;
    } catch (e) {
      debugPrint('AdminRepository.getAllAuthorsAdmin error: $e');
      return [];
    }
  }

  void _seedMockAuthors() {
    _localAuthors.addAll([
      AdminAuthorModel(
        id: 'mock-author-1',
        penName: 'BundaRahma',
        role: 'user',
        bio: 'Reflections of maternal warmth and quiet wisdom.',
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
        storiesCount: 3,
      ),
      AdminAuthorModel(
        id: 'mock-author-2',
        penName: 'SanctuaryKeeper',
        role: 'curator',
        bio: 'Guardian of the quiet word and poetic sanctuary.',
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        storiesCount: 8,
      ),
    ]);
  }

  void _seedMockReports() {
    _localReports.addAll([
      AdminReportModel(
        id: 'rep-001',
        storyId: 'story-mock-1',
        storyTitle: 'Whispers Beneath the Autumn Boughs',
        reason: 'spam',
        details: 'Repetitive advertising links inserted in paragraph 3.',
        status: 'pending',
        createdAt: DateTime.now().subtract(const Duration(hours: 3)),
        storyStatus: 'published',
        storyAuthor: 'AutumnPoet',
        isStoryAnonymous: false,
      ),
      AdminReportModel(
        id: 'rep-002',
        storyId: 'story-mock-2',
        storyTitle: 'Echoes of Midnight Solitude',
        reason: 'harassment',
        details: 'Contains targeted aggressive rhetoric toward another user.',
        status: 'pending',
        createdAt: DateTime.now().subtract(const Duration(hours: 14)),
        storyStatus: 'published',
        storyAuthor: 'Anonymous Scribe',
        isStoryAnonymous: true,
      ),
    ]);
  }

  void _seedMockAuditLogs() {
    _localAuditLogs.addAll([
      CuratorAuditLogModel(
        id: 'log-01',
        curatorId: 'admin-01',
        curatorName: 'AzzamTes',
        action: 'assign_curator',
        targetType: 'user',
        targetId: 'user-02',
        targetTitle: 'SanctuaryKeeper',
        details: 'Role updated to curator',
        createdAt: DateTime.now().subtract(const Duration(minutes: 25)),
      ),
      CuratorAuditLogModel(
        id: 'log-02',
        curatorId: 'curator-02',
        curatorName: 'SanctuaryKeeper',
        action: 'moderate_story',
        targetType: 'story',
        targetId: 'story-99',
        targetTitle: 'Violent Outbursts in the Grove',
        details: 'Scroll veiled under moderation shelter',
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      CuratorAuditLogModel(
        id: 'log-03',
        curatorId: 'curator-02',
        curatorName: 'SanctuaryKeeper',
        action: 'review_report',
        targetType: 'report',
        targetId: 'rep-001',
        targetTitle: 'Whispers Beneath the Autumn Boughs',
        details: 'Report status marked as reviewed',
        createdAt: DateTime.now().subtract(const Duration(hours: 4)),
      ),
    ]);
  }
}
