import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/category_model.dart';
import '../models/comment_model.dart';
import '../models/story_model.dart';

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

    final response = await query
        .order('published_at', ascending: false)
        .range(from, to);

    final currentUserId = client.auth.currentUser?.id;
    final stories = <StoryModel>[];

    for (final item in response as List) {
      final map = item as Map<String, dynamic>;
      final storyId = map['id'] as String;

      bool isLiked = false;
      bool isBookmarked = false;

      if (currentUserId != null) {
        // Check like status
        final likeRes = await client
            .from('likes')
            .select('id')
            .eq('story_id', storyId)
            .eq('user_id', currentUserId)
            .maybeSingle();
        isLiked = likeRes != null;

        // Check bookmark status
        final bookmarkRes = await client
            .from('bookmarks')
            .select('id')
            .eq('story_id', storyId)
            .eq('user_id', currentUserId)
            .maybeSingle();
        isBookmarked = bookmarkRes != null;
      }

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
  }) async {
    final client = _supabase;
    if (client == null) throw Exception('Database connection not initialized.');

    final user = client.auth.currentUser;
    if (user == null) {
      throw Exception('User must be logged in to create stories.');
    }

    final now = DateTime.now().toIso8601String();
    final insertData = {
      'user_id': user.id,
      'category_id': categoryId,
      'title': title.trim(),
      'content': content.trim(),
      'is_anonymous': isAnonymous,
      'status': isDraft ? 'draft' : 'published',
      'published_at': isDraft ? null : now,
    };

    final response = await client
        .from('stories')
        .insert(insertData)
        .select()
        .single();

    return StoryModel(
      id: response['id'] as String,
      categoryId: categoryId,
      categoryName: '',
      categorySlug: '',
      title: title,
      content: content,
      isAnonymous: isAnonymous,
      authorName: isAnonymous ? 'Anonymous' : 'You',
      publishedAt: isDraft ? null : DateTime.parse(now),
      createdAt: DateTime.now(),
    );
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

    final response = await client
        .from('public_stories_view')
        .select()
        .filter('id', 'in', storyIds);

    return (response as List)
        .map((item) => StoryModel.fromMap(item as Map<String, dynamic>, isBookmarked: true))
        .toList();
  }

  /// Fetches comments for a story.
  Future<List<CommentModel>> getComments(String storyId) async {
    final client = _supabase;
    if (client == null) return [];

    final response = await client
        .from('comments')
        .select('*, profiles:user_id(pen_name)')
        .eq('story_id', storyId)
        .order('created_at', ascending: true);

    return (response as List)
        .map((item) => CommentModel.fromMap(item as Map<String, dynamic>))
        .toList();
  }

  /// Submits a comment.
  Future<void> addComment(String storyId, String content) async {
    final client = _supabase;
    if (client == null) throw Exception('Database connection not initialized.');

    final user = client.auth.currentUser;
    if (user == null) throw Exception('Please log in to comment.');

    await client.from('comments').insert({
      'story_id': storyId,
      'user_id': user.id,
      'content': content.trim(),
    });
  }

  /// Submits a report for a story.
  Future<void> reportStory(String storyId, String reason, String? details) async {
    final client = _supabase;
    if (client == null) throw Exception('Database connection not initialized.');

    final user = client.auth.currentUser;
    if (user == null) throw Exception('Please log in to report.');

    await client.from('reports').insert({
      'story_id': storyId,
      'reporter_id': user.id,
      'reason': reason,
      'details': details?.trim(),
    });
  }
}
