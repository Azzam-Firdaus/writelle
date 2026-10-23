import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/story_model.dart';
import '../models/user_profile_model.dart';

/// Repository for handling authentication and user profile management.
/// Ref: docs/DATABASE_AND_API.md
class AuthRepository {
  final SupabaseClient? _customClient;

  AuthRepository({SupabaseClient? supabase}) : _customClient = supabase;

  SupabaseClient? get _supabase {
    if (_customClient != null) return _customClient;
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  User? get currentUser => _supabase?.auth.currentUser;

  bool get isAuthenticated => currentUser != null;

  Stream<AuthState> get authStateChanges =>
      _supabase?.auth.onAuthStateChange ?? const Stream.empty();

  /// Register with email and password (FR-001)
  Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) async {
    final client = _supabase;
    if (client == null) throw Exception('Database connection not initialized.');

    return await client.auth.signUp(
      email: email.trim(),
      password: password,
    );
  }

  /// Sign in with email and password (FR-002)
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    final client = _supabase;
    if (client == null) {
      throw Exception('Supabase belum diinisialisasi.');
    }

    final response = await client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );

    debugPrint('Login berhasil: ${response.user != null}');
    debugPrint('Sesi tersedia: ${response.session != null}');
    debugPrint('User aktif: ${client.auth.currentUser?.id != null}');

    return response;
  }

  /// Sign out (FR-003)
  Future<void> signOut() async {
    final client = _supabase;
    if (client == null) return;
    await client.auth.signOut();
  }

  /// Fetches current user profile from profiles table
  Future<UserProfileModel?> getCurrentProfile() async {
    final client = _supabase;
    if (client == null) return null;

    final user = client.auth.currentUser;
    if (user == null) return null;

    final response = await client
        .from('profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();

    if (response == null) return null;
    return UserProfileModel.fromMap(response);
  }

  /// Updates user profile pen name and bio (FR-005)
  Future<UserProfileModel> updateProfile({
    required String penName,
    String? bio,
  }) async {
    final client = _supabase;
    if (client == null) throw Exception('Database connection not initialized.');

    final user = client.auth.currentUser;
    if (user == null) throw Exception('User not authenticated.');

    final response = await client
        .from('profiles')
        .update({
          'pen_name': penName.trim(),
          'bio': bio?.trim(),
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', user.id)
        .select()
        .single();

    return UserProfileModel.fromMap(response);
  }

  /// Fetches author's own stories (both published and drafts, FR-007, FR-009)
  Future<List<StoryModel>> getMyStories({bool draftsOnly = false}) async {
    final client = _supabase;
    if (client == null) return [];

    final user = client.auth.currentUser;
    if (user == null) return [];

    var query = client
        .from('stories')
        .select('*, categories:category_id(name, slug)')
        .eq('user_id', user.id)
        .isFilter('deleted_at', null);

    if (draftsOnly) {
      query = query.eq('status', 'draft');
    } else {
      query = query.eq('status', 'published');
    }

    final response = await query.order('created_at', ascending: false);

    return (response as List).map((item) {
      final map = item as Map<String, dynamic>;
      String catName = 'General';
      String catSlug = 'general';
      if (map['categories'] != null && map['categories'] is Map) {
        catName = map['categories']['name'] as String? ?? 'General';
        catSlug = map['categories']['slug'] as String? ?? 'general';
      }

      return StoryModel(
        id: map['id'] as String,
        categoryId: map['category_id'] as String,
        categoryName: catName,
        categorySlug: catSlug,
        title: map['title'] as String,
        content: map['content'] as String,
        isAnonymous: map['is_anonymous'] as bool? ?? true,
        authorName: (map['is_anonymous'] as bool? ?? true) ? 'Anonymous' : 'You',
        publishedAt: map['published_at'] != null ? DateTime.parse(map['published_at'] as String) : null,
        createdAt: DateTime.parse(map['created_at'] as String),
        viewsCount: (map['views_count'] as num?)?.toInt() ?? 0,
      );
    }).toList();
  }
}
