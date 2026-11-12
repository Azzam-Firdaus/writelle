import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/cache/cover_cache.dart';
import '../models/category_model.dart';
import '../models/story_model.dart';
import 'admin_repository.dart';

/// Repository for handling all story-related data operations.
/// Ref: docs/DATABASE_AND_API.md
class StoryRepository {
  final SupabaseClient? _customClient;

  StoryRepository({SupabaseClient? supabase}) : _customClient = supabase;

  SupabaseClient? get _supabase {
    if (_customClient != null) return _customClient;
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  /// Fetches all active categories.
  Future<List<CategoryModel>> getCategories() async {
    final client = _supabase;
    if (client == null) return [];

    final response = await client
        .from('categories')
        .select()
        .order('name', ascending: true);

    return (response as List)
        .map((item) => CategoryModel.fromMap(item as Map<String, dynamic>))
        .toList();
  }

  /// Creates a new category and returns the model.
  Future<CategoryModel> createCategory({
    required String name,
    String? description,
  }) async {
    final client = _supabase;
    if (client == null) throw Exception('Database connection not initialized.');

    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw Exception('Category name cannot be empty.');
    }

    final slug = trimmedName
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');

    // Check if category with this name already exists
    try {
      final existing = await client
          .from('categories')
          .select()
          .ilike('name', trimmedName)
          .maybeSingle();

      if (existing != null) {
        return CategoryModel.fromMap(existing);
      }
    } catch (_) {}

    final insertData = <String, dynamic>{
      'name': trimmedName,
      'slug': slug.isEmpty ? 'category-${DateTime.now().millisecondsSinceEpoch}' : slug,
      'description': description?.trim(),
    };

    try {
      final response = await client
          .from('categories')
          .insert(insertData)
          .select()
          .single();

      return CategoryModel.fromMap(response);
    } catch (e) {
      final errStr = e.toString();
      if (errStr.contains('42501') || errStr.contains('row-level security')) {
        throw Exception(
          'Supabase database permissions do not allow adding new categories (RLS 42501). '
          'Please run the INSERT policy SQL script in the Supabase SQL Editor.',
        );
      } else if (errStr.contains('duplicate key') || errStr.contains('23505')) {
        final existing = await client
            .from('categories')
            .select()
            .ilike('name', trimmedName)
            .maybeSingle();
        if (existing != null) {
          return CategoryModel.fromMap(existing);
        }
      }
      rethrow;
    }
  }

  /// Fetches published stories from public_stories_view ensuring anonymity.
  Future<List<StoryModel>> getPublicStories({
    String? categorySlug,
    int page = 0,
    int limit = 15,
  }) async {
    final client = _supabase;
    if (client == null) return [];

    final from = page * limit;
    final to = from + limit - 1;

    var query = client.from('public_stories_view').select();

    if (categorySlug != null && categorySlug.isNotEmpty && categorySlug != 'all') {
      query = query.eq('category_slug', categorySlug);
    }

    List<dynamic> responseList = [];
    try {
      final response = await query
          .order('published_at', ascending: false)
          .range(from, to);
      responseList = response as List;
    } catch (e) {
      debugPrint('[StoryRepository] public_stories_view query notice: $e. Falling back to direct stories table query.');
      try {
        var directQuery = client
            .from('stories')
            .select('*, categories:category_id(name, slug)')
            .eq('status', 'published')
            .isFilter('deleted_at', null);

        if (categorySlug != null && categorySlug.isNotEmpty && categorySlug != 'all') {
          directQuery = directQuery.eq('categories.slug', categorySlug);
        }

        final directRes = await directQuery
            .order('published_at', ascending: false)
            .range(from, to);

        final rawList = directRes as List;
        final nonAnonUserIds = rawList
            .where((item) => (item['is_anonymous'] as bool? ?? true) == false)
            .map((item) => item['user_id'] as String?)
            .where((uid) => uid != null && uid.isNotEmpty)
            .cast<String>()
            .toSet()
            .toList();

        final penNames = <String, String>{};
        final avatars = <String, String>{};
        if (nonAnonUserIds.isNotEmpty) {
          try {
            final profilesRes = await client
                .from('profiles')
                .select('id, pen_name, avatar_url')
                .filter('id', 'in', nonAnonUserIds);
            for (final p in profilesRes as List) {
              final pid = p['id'] as String?;
              final pname = p['pen_name'] as String?;
              final pavatar = p['avatar_url'] as String?;
              if (pid != null) {
                if (pname != null) penNames[pid] = pname;
                if (pavatar != null) avatars[pid] = pavatar;
              }
            }
          } catch (_) {}
        }

        responseList = rawList.map((item) {
          final m = Map<String, dynamic>.from(item as Map<String, dynamic>);
          final cat = m['categories'] as Map<String, dynamic>?;
          final isAnon = m['is_anonymous'] as bool? ?? true;
          final uId = m['user_id'] as String?;
          m['category_name'] = cat?['name'] ?? 'Reflections';
          m['category_slug'] = cat?['slug'] ?? 'reflections';
          m['author_name'] = isAnon ? 'Anonymous' : (uId != null ? (penNames[uId] ?? 'Author') : 'Author');
          m['author_avatar_url'] = isAnon ? null : (uId != null ? avatars[uId] : null);
          return m;
        }).toList();
      } catch (fallbackErr) {
        debugPrint('[StoryRepository] Direct query fallback error: $fallbackErr');
        return [];
      }
    }

    final currentUserId = client.auth.currentUser?.id;
    final stories = <StoryModel>[];

    final Map<String, int> likesCountMap = {};
    final Set<String> likedStoryIds = {};
    final Set<String> bookmarkedStoryIds = {};

    if (responseList.isNotEmpty) {
      final storyIds = responseList
          .map((item) => (item as Map<String, dynamic>)['id'] as String)
          .toList();

      try {
        await Future.wait([
          () async {
            try {
              final likesRes = await client
                  .from('likes')
                  .select('story_id, user_id')
                  .inFilter('story_id', storyIds);
              for (final item in likesRes as List) {
                final sId = item['story_id'] as String?;
                final uId = item['user_id'] as String?;
                if (sId != null) {
                  likesCountMap[sId] = (likesCountMap[sId] ?? 0) + 1;
                  if (currentUserId != null && uId == currentUserId) {
                    likedStoryIds.add(sId);
                  }
                }
              }
            } catch (_) {}
          }(),
          if (currentUserId != null)
            () async {
              try {
                final bookmarksRes = await client
                    .from('bookmarks')
                    .select('story_id')
                    .eq('user_id', currentUserId)
                    .inFilter('story_id', storyIds);
                for (final item in bookmarksRes as List) {
                  final sId = item['story_id'] as String?;
                  if (sId != null) {
                    bookmarkedStoryIds.add(sId);
                  }
                }
              } catch (_) {}
            }(),
        ]);
      } catch (e) {
        debugPrint('[StoryRepository] Batch metrics fetch notice: $e');
      }
    }

    for (final item in responseList) {
      final map = Map<String, dynamic>.from(item as Map<String, dynamic>);
      final storyId = map['id'] as String;
      final isLiked = likedStoryIds.contains(storyId);
      final isBookmarked = bookmarkedStoryIds.contains(storyId);

      map['likes_count'] = likesCountMap[storyId] ?? (map['likes_count'] as num?)?.toInt() ?? 0;

      stories.add(StoryModel.fromMap(map, isLiked: isLiked, isBookmarked: isBookmarked));
    }

    return stories;
  }

  /// Creates a new story (Draft or Published).
  Future<StoryModel> createStory({
    required String categoryId,
    required String title,
    required String content,
    required bool isAnonymous,
    required bool isDraft,
    String? coverUrl,
  }) async {
    final client = _supabase;
    if (client == null) throw Exception('Database connection not initialized.');

    final user = client.auth.currentUser;
    if (user == null) {
      throw Exception('User must be logged in to create stories.');
    }

    final now = DateTime.now().toIso8601String();
    final insertData = <String, dynamic>{
      'user_id': user.id,
      'category_id': categoryId,
      'title': title.trim(),
      'content': content.trim(),
      'is_anonymous': isAnonymous,
      'status': isDraft ? 'draft' : 'published',
      'published_at': isDraft ? null : now,
    };

    if (coverUrl != null && coverUrl.trim().isNotEmpty) {
      insertData['cover_url'] = coverUrl.trim();
    }

    Map<String, dynamic> response;
    try {
      response = await client
          .from('stories')
          .insert(insertData)
          .select()
          .single();
    } catch (e) {
      // In case cover_url column is not yet added in Supabase, fallback gracefully
      if (insertData.containsKey('cover_url') && e.toString().contains('cover_url')) {
        insertData.remove('cover_url');
        response = await client
            .from('stories')
            .insert(insertData)
            .select()
            .single();
      } else {
        rethrow;
      }
    }

    final createdId = response['id'] as String;
    if (coverUrl != null && coverUrl.trim().isNotEmpty) {
      CoverCache.set(createdId, coverUrl.trim());
    }

    return StoryModel(
      id: createdId,
      userId: user.id,
      categoryId: categoryId,
      categoryName: '',
      categorySlug: '',
      title: title,
      content: content,
      isAnonymous: isAnonymous,
      authorName: isAnonymous ? 'Anonymous' : 'You',
      coverUrl: coverUrl,
      publishedAt: isDraft ? null : DateTime.parse(now),
      createdAt: DateTime.now(),
    );
  }

  /// Uploads a local cover image picked from device gallery to Supabase Storage bucket 'story_covers'.
  /// Gracefully falls back to local file path or base64 Data URI if storage bucket is not configured.
  Future<String> uploadCoverImage(XFile imageFile) async {
    final client = _supabase;
    final bytes = await imageFile.readAsBytes();
    final ext = imageFile.name.contains('.')
        ? imageFile.name.split('.').last.toLowerCase()
        : 'jpg';
    final mimeType = ext == 'png' ? 'image/png' : 'image/jpeg';
    final userId = client?.auth.currentUser?.id ?? 'anon';
    final fileName = '${userId}_${DateTime.now().millisecondsSinceEpoch}.$ext';
    final filePath = 'covers/$fileName';

    if (client != null) {
      try {
        await client.storage.from('story_covers').uploadBinary(
          filePath,
          bytes,
          fileOptions: FileOptions(contentType: mimeType, upsert: true),
        );
        final publicUrl = client.storage.from('story_covers').getPublicUrl(filePath);
        debugPrint('Story cover successfully uploaded to Supabase Storage: $publicUrl');
        return publicUrl;
      } catch (storageError) {
        debugPrint('Supabase storage upload notice ($storageError), using resilient fallback.');
      }
    }

    // Local filesystem path on device: instant preview, reliable loading & zero base64 memory bloat
    if (!kIsWeb && imageFile.path.isNotEmpty) {
      return imageFile.path;
    }

    final base64Data = base64Encode(bytes);
    return 'data:$mimeType;base64,$base64Data';
  }

  /// Checks if current user is the author of the story
  Future<bool> isStoryAuthor(String storyId) async {
    final client = _supabase;
    if (client == null) return false;
    final user = client.auth.currentUser;
    if (user == null) return false;

    try {
      final res = await client
          .from('stories')
          .select('id')
          .eq('id', storyId)
          .eq('user_id', user.id)
          .maybeSingle();
      return res != null;
    } catch (_) {
      return false;
    }
  }

  /// Deletes a story (by author, or by admin/curator)
  Future<void> deleteStory(String storyId, {bool? asAdmin, String? storyTitle}) async {
    final client = _supabase;
    if (client == null) throw Exception('Database connection not initialized.');

    final user = client.auth.currentUser;
    if (user == null) {
      throw Exception('User must be logged in to delete stories.');
    }

    bool isAdmin = asAdmin ?? false;
    if (asAdmin == null) {
      try {
        final profileRes = await client
            .from('profiles')
            .select('role')
            .eq('id', user.id)
            .maybeSingle();
        final role = profileRes?['role'] as String?;
        if (role == 'admin' || role == 'curator') {
          isAdmin = true;
        }
      } catch (_) {}
    }

    // Resolve story title if deleting as admin/curator for audit trail
    String resolvedTitle = storyTitle ?? 'Untitled Tale';
    if (storyTitle == null && isAdmin) {
      try {
        final sRes = await client.from('stories').select('title').eq('id', storyId).maybeSingle();
        if (sRes != null && sRes['title'] != null) {
          resolvedTitle = sRes['title'] as String;
        }
      } catch (_) {}
    }

    try {
      if (isAdmin) {
        try {
          await client.rpc('soft_delete_story_admin', params: {
            'target_story_id': storyId,
          });
        } catch (_) {
          var query = client
              .from('stories')
              .update({
                'deleted_at': DateTime.now().toUtc().toIso8601String(),
                'deleted_by_curator': true,
                'updated_at': DateTime.now().toUtc().toIso8601String(),
              })
              .eq('id', storyId);
          await query;
        }
      } else {
        try {
          await client
              .from('stories')
              .update({
                'deleted_at': DateTime.now().toUtc().toIso8601String(),
                'deleted_by_curator': false,
                'updated_at': DateTime.now().toUtc().toIso8601String(),
              })
              .eq('id', storyId)
              .eq('user_id', user.id);
        } catch (_) {
          // Fallback if deleted_by_curator column is not yet migrated in PostgreSQL
          await client
              .from('stories')
              .update({
                'deleted_at': DateTime.now().toUtc().toIso8601String(),
                'updated_at': DateTime.now().toUtc().toIso8601String(),
              })
              .eq('id', storyId)
              .eq('user_id', user.id);
        }
      }
    } catch (e) {
      debugPrint('[StoryRepository.deleteStory] Soft delete update error: $e');
      rethrow;
    }

    // If an administrator or curator deletes a story, record an audit log!
    if (isAdmin) {
      try {
        final adminRepo = AdminRepository(supabase: client);
        await adminRepo.recordAuditLog(
          action: 'delete_story',
          targetType: 'story',
          targetId: storyId,
          targetTitle: resolvedTitle,
          details: 'Scroll moved to 14-day retention trash by administrator/curator',
        );
      } catch (e) {
        debugPrint('[StoryRepository] Failed to record audit log on story delete: $e');
      }
    }
  }

  /// Restores a soft-deleted story from 14-day retention back to the sanctuary.
  /// Throws an exception if the story was deleted by a curator/admin for moderation.
  Future<void> restoreStory(String storyId) async {
    final client = _supabase;
    if (client == null) throw Exception('Database connection not initialized.');

    final user = client.auth.currentUser;
    if (user == null) throw Exception('User must be logged in to restore stories.');

    // 1. Try dedicated RPC restore_soft_deleted_story (enforces deleted_by_curator = false in DB)
    try {
      await client.rpc('restore_soft_deleted_story', params: {
        'target_story_id': storyId,
      });
      return;
    } catch (e) {
      debugPrint('[StoryRepository.restoreStory] RPC notice: $e');
    }

    // 2. Direct fallback check: ensure the story was NOT deleted by a curator!
    try {
      final check = await client
          .from('stories')
          .select('deleted_by_curator, user_id, deleted_at')
          .eq('id', storyId)
          .maybeSingle();

      if (check != null) {
        if (check['deleted_by_curator'] == true) {
          throw Exception('This tale was quarantined by a sanctuary curator and cannot be self-restored.');
        }
        if (check['user_id'] != user.id) {
          throw Exception('You can only restore your own tales.');
        }
      }
    } catch (e) {
      if (e.toString().contains('quarantined') || e.toString().contains('only restore your own')) {
        rethrow;
      }
      debugPrint('[StoryRepository.restoreStory] Pre-check notice: $e');
    }

    try {
      await client
          .from('stories')
          .update({
            'deleted_at': null,
            'deleted_by_curator': false,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', storyId)
          .eq('user_id', user.id);
    } catch (_) {
      // Fallback if deleted_by_curator column is not present
      await client
          .from('stories')
          .update({
            'deleted_at': null,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', storyId)
          .eq('user_id', user.id);
    }
  }

  /// Updates an existing story (draft or published)
  Future<void> updateStory({
    required String storyId,
    required String categoryId,
    required String title,
    required String content,
    required bool isAnonymous,
    required bool isDraft,
    String? coverUrl,
  }) async {
    final client = _supabase;
    if (client == null) throw Exception('Database connection not initialized.');

    final user = client.auth.currentUser;
    if (user == null) {
      throw Exception('User must be logged in to update stories.');
    }

    final updateData = <String, dynamic>{
      'category_id': categoryId,
      'title': title.trim(),
      'content': content.trim(),
      'is_anonymous': isAnonymous,
      'status': isDraft ? 'draft' : 'published',
      if (coverUrl != null && coverUrl.isNotEmpty) 'cover_url': coverUrl,
      if (!isDraft) 'published_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };

    try {
      await client.from('stories').update(updateData).eq('id', storyId).eq('user_id', user.id);
    } catch (e) {
      if (updateData.containsKey('cover_url') && e.toString().contains('cover_url')) {
        updateData.remove('cover_url');
        await client.from('stories').update(updateData).eq('id', storyId).eq('user_id', user.id);
      } else {
        rethrow;
      }
    }

    if (coverUrl != null && coverUrl.trim().isNotEmpty) {
      CoverCache.set(storyId, coverUrl.trim());
    }
  }

  /// Toggles like on a story. Returns new isLiked state.
  Future<bool> toggleLike(String storyId) async {
    final client = _supabase;
    if (client == null) throw Exception('Database connection not initialized.');

    final user = client.auth.currentUser;
    if (user == null) throw Exception('Please log in to like stories.');

    final existing = await client
        .from('likes')
        .select('id')
        .eq('story_id', storyId)
        .eq('user_id', user.id)
        .maybeSingle();

    if (existing != null) {
      await client
          .from('likes')
          .delete()
          .eq('story_id', storyId)
          .eq('user_id', user.id);
      return false;
    } else {
      await client.from('likes').insert({
        'story_id': storyId,
        'user_id': user.id,
      });
      return true;
    }
  }

  /// Toggles bookmark on a story. Returns new isBookmarked state.
  Future<bool> toggleBookmark(String storyId) async {
    final client = _supabase;
    if (client == null) throw Exception('Database connection not initialized.');

    final user = client.auth.currentUser;
    if (user == null) throw Exception('Please log in to bookmark stories.');

    final existing = await client
        .from('bookmarks')
        .select('id')
        .eq('story_id', storyId)
        .eq('user_id', user.id)
        .maybeSingle();

    if (existing != null) {
      await client
          .from('bookmarks')
          .delete()
          .eq('story_id', storyId)
          .eq('user_id', user.id);
      return false;
    } else {
      await client.from('bookmarks').insert({
        'story_id': storyId,
        'user_id': user.id,
      });
      return true;
    }
  }

  /// Fetches stories bookmarked by current user.
  Future<List<StoryModel>> getBookmarkedStories() async {
    final client = _supabase;
    if (client == null) return [];

    final user = client.auth.currentUser;
    if (user == null) return [];

    final bookmarks = await client
        .from('bookmarks')
        .select('story_id')
        .eq('user_id', user.id)
        .order('created_at', ascending: false);

    final storyIds = (bookmarks as List).map((b) => b['story_id'] as String).toList();
    if (storyIds.isEmpty) return [];

    List<dynamic> responseList = [];
    try {
      final response = await client
          .from('public_stories_view')
          .select()
          .filter('id', 'in', storyIds);
      responseList = response as List;
    } catch (e) {
      debugPrint('[StoryRepository] Bookmarks view query notice: $e. Falling back to direct stories table query.');
      try {
        final directRes = await client
            .from('stories')
            .select('*, categories:category_id(name, slug)')
            .filter('id', 'in', storyIds);

        final rawList = directRes as List;
        final nonAnonUserIds = rawList
            .where((item) => (item['is_anonymous'] as bool? ?? true) == false)
            .map((item) => item['user_id'] as String?)
            .where((uid) => uid != null && uid.isNotEmpty)
            .cast<String>()
            .toSet()
            .toList();

        final penNames = <String, String>{};
        final avatars = <String, String>{};
        if (nonAnonUserIds.isNotEmpty) {
          try {
            final profilesRes = await client
                .from('profiles')
                .select('id, pen_name, avatar_url')
                .filter('id', 'in', nonAnonUserIds);
            for (final p in profilesRes as List) {
              final pid = p['id'] as String?;
              final pname = p['pen_name'] as String?;
              final pavatar = p['avatar_url'] as String?;
              if (pid != null) {
                if (pname != null) penNames[pid] = pname;
                if (pavatar != null) avatars[pid] = pavatar;
              }
            }
          } catch (_) {}
        }

        responseList = rawList.map((item) {
          final m = Map<String, dynamic>.from(item as Map<String, dynamic>);
          final cat = m['categories'] as Map<String, dynamic>?;
          final isAnon = m['is_anonymous'] as bool? ?? true;
          final uId = m['user_id'] as String?;
          m['category_name'] = cat?['name'] ?? 'Reflections';
          m['category_slug'] = cat?['slug'] ?? 'reflections';
          m['author_name'] = isAnon ? 'Anonymous' : (uId != null ? (penNames[uId] ?? 'Author') : 'Author');
          m['author_avatar_url'] = isAnon ? null : (uId != null ? avatars[uId] : null);
          return m;
        }).toList();
      } catch (_) {
        return [];
      }
    }

    final Map<String, int> likesCountMap = {};
    final Set<String> likedStoryIds = {};

    if (storyIds.isNotEmpty) {
      try {
        await Future.wait([
          () async {
            try {
              final likesRes = await client
                  .from('likes')
                  .select('story_id, user_id')
                  .inFilter('story_id', storyIds);
              for (final item in likesRes as List) {
                final sId = item['story_id'] as String?;
                final uId = item['user_id'] as String?;
                if (sId != null) {
                  likesCountMap[sId] = (likesCountMap[sId] ?? 0) + 1;
                  if (uId == user.id) {
                    likedStoryIds.add(sId);
                  }
                }
              }
            } catch (_) {}
          }(),
        ]);
      } catch (_) {}
    }

    return responseList.map((item) {
      final map = Map<String, dynamic>.from(item as Map<String, dynamic>);
      final storyId = map['id'] as String;
      map['likes_count'] = likesCountMap[storyId] ?? (map['likes_count'] as num?)?.toInt() ?? 0;
      final isLiked = likedStoryIds.contains(storyId);
      return StoryModel.fromMap(map, isLiked: isLiked, isBookmarked: true);
    }).toList();
  }

  /// Submits a report for a story.
  Future<void> reportStory(String storyId, String reason, String? details) async {
    final client = _supabase;
    if (client == null) throw Exception('Database connection not initialized.');

    final user = client.auth.currentUser;
    if (user == null) throw Exception('Please log in to report.');

    try {
      await client.from('reports').insert({
        'story_id': storyId,
        'reporter_id': user.id,
        'reason': reason,
        'details': details?.trim(),
      });
    } on PostgrestException catch (e) {
      // 23505 = Postgres unique violation (unique_story_report)
      if (e.code == '23505' || e.message.contains('unique_story_report')) {
        throw Exception('You have already submitted a report for this story.');
      }
      // If RLS blocked SELECT returning on inserted row (42501)
      if (e.code == '42501' || e.message.contains('row-level security') || e.message.contains('violates row-level security')) {
        debugPrint('[StoryRepository.reportStory] Notice: RLS SELECT restricted on reports, but insert succeeded.');
        return;
      }
      rethrow;
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('23505') || msg.contains('unique_story_report')) {
        throw Exception('You have already submitted a report for this story.');
      }
      if (msg.contains('row-level security') || msg.contains('42501')) {
        debugPrint('[StoryRepository.reportStory] Notice: RLS SELECT restricted on reports, but insert succeeded.');
        return;
      }
      rethrow;
    }
  }

  /// Fetches public published stories by a specific author
  Future<List<StoryModel>> getStoriesByAuthor(String authorId) async {
    final client = _supabase;
    if (client == null) return [];

    try {
      final response = await client
          .from('stories')
          .select('*, categories:category_id(name, slug)')
          .eq('user_id', authorId)
          .eq('status', 'published')
          .isFilter('deleted_at', null)
          .order('published_at', ascending: false);

      final currentUserId = client.auth.currentUser?.id;
      final stories = <StoryModel>[];
      final storyList = response as List;
      final nonAnonStoryIds = storyList
          .where((item) => (item['is_anonymous'] as bool? ?? false) == false)
          .map((item) => item['id'] as String)
          .toList();

      final Map<String, int> likesCountMap = {};
      final Set<String> userLikedStoryIds = {};
      final Set<String> userBookmarkedStoryIds = {};

      if (nonAnonStoryIds.isNotEmpty) {
        await Future.wait([
          () async {
            try {
              final likesRes = await client
                  .from('likes')
                  .select('story_id, user_id')
                  .inFilter('story_id', nonAnonStoryIds);
              for (final item in likesRes as List) {
                final sId = item['story_id'] as String?;
                final uId = item['user_id'] as String?;
                if (sId != null) {
                  likesCountMap[sId] = (likesCountMap[sId] ?? 0) + 1;
                  if (currentUserId != null && uId == currentUserId) {
                    userLikedStoryIds.add(sId);
                  }
                }
              }
            } catch (_) {}
          }(),
          if (currentUserId != null)
            () async {
              try {
                final bookmarksRes = await client
                    .from('bookmarks')
                    .select('story_id')
                    .eq('user_id', currentUserId)
                    .inFilter('story_id', nonAnonStoryIds);
                for (final item in bookmarksRes as List) {
                  final sId = item['story_id'] as String?;
                  if (sId != null) {
                    userBookmarkedStoryIds.add(sId);
                  }
                }
              } catch (_) {}
            }(),
        ]);
      }

      // Fetch author profile to get pen name
      String authorPenName = 'Author';
      try {
        final pRes = await client.from('profiles').select('pen_name').eq('id', authorId).maybeSingle();
        if (pRes != null && pRes['pen_name'] != null) {
          authorPenName = pRes['pen_name'] as String;
        }
      } catch (_) {}

      for (final item in storyList) {
        final map = item as Map<String, dynamic>;
        final isAnon = map['is_anonymous'] as bool? ?? false;

        // Honor pure anonymity
        if (isAnon) continue;

        final storyId = map['id'] as String;
        final isLiked = userLikedStoryIds.contains(storyId);
        final isBookmarked = userBookmarkedStoryIds.contains(storyId);
        final likesCount = likesCountMap[storyId] ?? (map['likes_count'] as num?)?.toInt() ?? 0;

        String catName = 'General';
        String catSlug = 'general';
        if (map['categories'] != null && map['categories'] is Map) {
          catName = map['categories']['name'] as String? ?? 'General';
          catSlug = map['categories']['slug'] as String? ?? 'general';
        }

        final dbCover = map['cover_url'] as String?;
        final resolvedCover = (dbCover != null && dbCover.trim().isNotEmpty)
            ? dbCover.trim()
            : CoverCache.get(storyId);

        stories.add(
          StoryModel(
            id: storyId,
            userId: authorId,
            categoryId: map['category_id'] as String,
            categoryName: catName,
            categorySlug: catSlug,
            title: map['title'] as String,
            content: map['content'] as String,
            isAnonymous: false,
            authorName: authorPenName,
            publishedAt: map['published_at'] != null ? DateTime.parse(map['published_at'] as String) : null,
            createdAt: DateTime.parse(map['created_at'] as String),
            viewsCount: (map['views_count'] as num?)?.toInt() ?? 0,
            likesCount: likesCount,
            isLiked: isLiked,
            isBookmarked: isBookmarked,
            coverUrl: resolvedCover,
          ),
        );
      }

      return stories;
    } catch (_) {
      return [];
    }
  }
}
