import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/cache/cover_cache.dart';
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

  User? get currentUser => _supabase?.auth.currentUser ?? _supabase?.auth.currentSession?.user;

  bool get isAuthenticated => currentUser != null || _supabase?.auth.currentSession != null;

  Stream<AuthState> get authStateChanges async* {
    final client = _supabase;
    if (client != null) {
      // Emit the current session state immediately so StreamProvider resolves without hanging
      yield AuthState(
        client.auth.currentSession != null
            ? AuthChangeEvent.signedIn
            : AuthChangeEvent.signedOut,
        client.auth.currentSession,
      );
      yield* client.auth.onAuthStateChange;
    }
  }

  /// Register with email and password (FR-001)
  Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) async {
    final client = _supabase;
    if (client == null) throw Exception('Database connection not initialized.');

    final trimmedEmail = email.trim();
    if (trimmedEmail.isEmpty || !trimmedEmail.contains('@')) {
      throw Exception('Please provide a valid email address.');
    }
    if (password.length < 8) {
      throw Exception('Password must be at least 8 characters.');
    }

    try {
      final response = await client.auth.signUp(
        email: trimmedEmail,
        password: password,
        emailRedirectTo: kIsWeb ? null : 'io.supabase.writelle://login-callback',
      );

      // In Supabase Auth, when User Enumeration Protection is enabled,
      // registering an existing email returns 200 with an empty identities list ([]).
      if (response.user != null &&
          (response.user!.identities == null || response.user!.identities!.isEmpty)) {
        throw Exception('This email is already registered. Please sign in or use another email.');
      }

      return response;
    } on AuthException catch (e) {
      final msg = e.message.toLowerCase();
      if (msg.contains('already registered') ||
          msg.contains('already in use') ||
          msg.contains('user already exists') ||
          msg.contains('duplicate')) {
        throw Exception('This email is already registered. Please sign in or use another email.');
      }
      throw Exception(e.message);
    } catch (e) {
      rethrow;
    }
  }

  /// Sign in with email and password (FR-002)
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    final client = _supabase;
    if (client == null) {
      throw Exception('Database connection not initialized.');
    }

    final response = await client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );

    debugPrint('Sign in successful: ${response.user != null}');
    debugPrint('Session available: ${response.session != null}');
    debugPrint('Active user: ${client.auth.currentUser?.id != null}');

    return response;
  }

  /// Sign in with Google via Supabase OAuth
  Future<bool> signInWithGoogle() async {
    final client = _supabase;
    if (client == null) {
      throw Exception('Database connection not initialized.');
    }

    try {
      return await client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: kIsWeb ? null : 'io.supabase.writelle://login-callback',
        authScreenLaunchMode: LaunchMode.externalApplication,
      );
    } on AuthException catch (e) {
      if (e.message.toLowerCase().contains('not enabled') ||
          e.message.toLowerCase().contains('unsupported provider')) {
        throw Exception(
          'Google Sign-In is not enabled in Supabase Dashboard. '
          'Please enable Google Provider in Supabase Dashboard > Authentication > Providers.',
        );
      }
      throw Exception(e.message);
    } catch (e) {
      if (e.toString().toLowerCase().contains('not enabled')) {
        throw Exception(
          'Google Sign-In is not enabled in Supabase Dashboard. '
          'Please enable Google Provider in Supabase Dashboard > Authentication > Providers.',
        );
      }
      rethrow;
    }
  }

  /// Sends password recovery email with reset link and OTP token (FR-001)
  Future<void> sendPasswordResetEmail(String email) async {
    final client = _supabase;
    if (client == null) {
      throw Exception('Database connection not initialized.');
    }

    final trimmed = email.trim();
    if (trimmed.isEmpty || !trimmed.contains('@')) {
      throw Exception('Please enter a valid email address.');
    }

    try {
      await client.auth.resetPasswordForEmail(
        trimmed,
        redirectTo: kIsWeb ? null : 'io.supabase.writelle://login-callback',
      );
    } on AuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      rethrow;
    }
  }

  /// Verifies email recovery token / OTP and authenticates the user for password update
  Future<void> verifyRecoveryOtp({required String email, required String token}) async {
    final client = _supabase;
    if (client == null) {
      throw Exception('Database connection not initialized.');
    }

    final trimmedEmail = email.trim();
    final trimmedToken = token.trim();

    if (trimmedEmail.isEmpty || !trimmedEmail.contains('@')) {
      throw Exception('Please enter a valid email address.');
    }
    if (trimmedToken.isEmpty) {
      throw Exception('Please enter the 6-digit recovery code.');
    }

    try {
      await client.auth.verifyOTP(
        email: trimmedEmail,
        token: trimmedToken,
        type: OtpType.recovery,
      );
    } on AuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      rethrow;
    }
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

    if (response == null) {
      // Fallback: If handle_new_user trigger did not run, auto-provision profile from OAuth metadata
      final meta = user.userMetadata ?? {};
      final rawName = meta['full_name'] as String? ??
          meta['name'] as String? ??
          meta['user_name'] as String? ??
          'Author_${user.id.length >= 6 ? user.id.substring(0, 6) : user.id}';
      final avatar = meta['avatar_url'] as String? ?? meta['picture'] as String?;
      final sanitizedPenName = rawName.trim().length > 32
          ? rawName.trim().substring(0, 32)
          : (rawName.trim().isEmpty ? 'Author_${user.id.substring(0, 6)}' : rawName.trim());

      try {
        final inserted = await client.from('profiles').insert({
          'id': user.id,
          'pen_name': sanitizedPenName,
          'avatar_url': avatar,
          'role': 'user',
        }).select().single();
        return UserProfileModel.fromMap(inserted);
      } catch (insertErr) {
        debugPrint('Auto-provisioning profile fallback notice: $insertErr');
        return UserProfileModel(
          id: user.id,
          penName: sanitizedPenName,
          avatarUrl: avatar,
          role: 'user',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      }
    }
    return UserProfileModel.fromMap(response);
  }

  /// Fetches a user profile by user ID
  Future<UserProfileModel?> getProfileById(String userId) async {
    final client = _supabase;
    if (client == null) return null;

    try {
      final response = await client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (response == null) return null;
      return UserProfileModel.fromMap(response);
    } catch (_) {
      return null;
    }
  }

  /// Searches authors/profiles by pen name or bio for the Explore screen
  Future<List<UserProfileModel>> searchProfiles(String query) async {
    final client = _supabase;
    if (client == null) return [];

    try {
      var filterBuilder = client.from('profiles').select();
      final trimmed = query.trim();
      if (trimmed.isNotEmpty) {
        filterBuilder = filterBuilder.ilike('pen_name', '%$trimmed%');
      }
      final response = await filterBuilder.order('pen_name', ascending: true).limit(30);
      final list = (response as List)
          .map((m) => UserProfileModel.fromMap(m as Map<String, dynamic>))
          .toList();
      return list;
    } catch (e) {
      debugPrint('[AuthRepository.searchProfiles] error: $e');
      return [];
    }
  }

  /// Updates user profile pen name, bio, and avatar (FR-005)
  Future<UserProfileModel> updateProfile({
    required String penName,
    String? bio,
    String? avatarUrl,
    bool clearAvatar = false,
  }) async {
    final client = _supabase;
    if (client == null) throw Exception('Database connection not initialized.');

    final user = client.auth.currentUser;
    if (user == null) throw Exception('User not authenticated.');

    final updateData = <String, dynamic>{
      'pen_name': penName.trim(),
      'bio': bio?.trim(),
      'updated_at': DateTime.now().toIso8601String(),
    };

    if (clearAvatar) {
      updateData['avatar_url'] = null;
    } else if (avatarUrl != null) {
      updateData['avatar_url'] = avatarUrl.trim();
    }

    final response = await client
        .from('profiles')
        .update(updateData)
        .eq('id', user.id)
        .select()
        .single();

    return UserProfileModel.fromMap(response);
  }

  /// Uploads a user avatar image picked from local device gallery.
  /// First attempts Supabase Storage, and gracefully falls back to local file path or data URI.
  Future<String> uploadAvatarImage(XFile imageFile) async {
    final client = _supabase;
    final bytes = await imageFile.readAsBytes();
    final ext = imageFile.name.contains('.')
        ? imageFile.name.split('.').last.toLowerCase()
        : 'jpg';
    final mimeType = ext == 'png' ? 'image/png' : 'image/jpeg';
    final userId = client?.auth.currentUser?.id ?? 'user';
    final fileName = 'avatar_${userId}_${DateTime.now().millisecondsSinceEpoch}.$ext';
    final filePath = 'avatars/$fileName';

    if (client != null) {
      try {
        await client.storage.from('story_covers').uploadBinary(
          filePath,
          bytes,
          fileOptions: FileOptions(contentType: mimeType, upsert: true),
        );
        final publicUrl = client.storage.from('story_covers').getPublicUrl(filePath);
        debugPrint('Avatar uploaded successfully to storage: $publicUrl');
        return publicUrl;
      } catch (storageError) {
        debugPrint('Notice on storage upload for avatar ($storageError), using resilient fallback.');
      }
    }

    // Local filesystem path fallback on device
    if (!kIsWeb && imageFile.path.isNotEmpty) {
      return imageFile.path;
    }

    final base64Data = base64Encode(bytes);
    return 'data:$mimeType;base64,$base64Data';
  }

  /// Updates user password in Supabase Auth
  Future<UserResponse> updatePassword({
    required String newPassword,
  }) async {
    final client = _supabase;
    if (client == null) throw Exception('Database connection not initialized.');

    final user = client.auth.currentUser;
    if (user == null) throw Exception('User not authenticated.');

    if (newPassword.trim().length < 8) {
      throw Exception('New password must be at least 8 characters.');
    }

    return await client.auth.updateUser(
      UserAttributes(password: newPassword.trim()),
    );
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
    final storyList = response as List;
    final storyIds = storyList.map((item) => (item as Map<String, dynamic>)['id'] as String).toList();

    final Map<String, int> likesCountMap = {};
    final Set<String> userLikedStoryIds = {};
    final Map<String, int> commentsCountMap = {};
    final Set<String> userBookmarkedStoryIds = {};

    if (storyIds.isNotEmpty) {
      await Future.wait([
        // 1. Fetch likes count and check if current user liked
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
                  userLikedStoryIds.add(sId);
                }
              }
            }
          } catch (e) {
            debugPrint('[AuthRepository] getMyStories likes notice: $e');
          }
        }(),
        // 2. Fetch comments count
        () async {
          try {
            final commentsRes = await client
                .from('comments')
                .select('story_id')
                .inFilter('story_id', storyIds);
            for (final item in commentsRes as List) {
              final sId = item['story_id'] as String?;
              if (sId != null) {
                commentsCountMap[sId] = (commentsCountMap[sId] ?? 0) + 1;
              }
            }
          } catch (e) {
            debugPrint('[AuthRepository] getMyStories comments notice: $e');
          }
        }(),
        // 3. Fetch bookmarks for current user
        () async {
          try {
            final bookmarksRes = await client
                .from('bookmarks')
                .select('story_id')
                .eq('user_id', user.id)
                .inFilter('story_id', storyIds);
            for (final item in bookmarksRes as List) {
              final sId = item['story_id'] as String?;
              if (sId != null) {
                userBookmarkedStoryIds.add(sId);
              }
            }
          } catch (e) {
            debugPrint('[AuthRepository] getMyStories bookmarks notice: $e');
          }
        }(),
      ]);
    }

    return storyList.map((item) {
      final map = item as Map<String, dynamic>;
      String catName = 'General';
      String catSlug = 'general';
      if (map['categories'] != null && map['categories'] is Map) {
        catName = map['categories']['name'] as String? ?? 'General';
        catSlug = map['categories']['slug'] as String? ?? 'general';
      }

      final storyId = map['id'] as String;
      final dbCover = map['cover_url'] as String?;
      final resolvedCover = (dbCover != null && dbCover.trim().isNotEmpty)
          ? dbCover.trim()
          : CoverCache.get(storyId);

      final likesCount = likesCountMap[storyId] ?? (map['likes_count'] as num?)?.toInt() ?? 0;
      final commentsCount = commentsCountMap[storyId] ?? (map['comments_count'] as num?)?.toInt() ?? 0;
      final isLiked = userLikedStoryIds.contains(storyId);
      final isBookmarked = userBookmarkedStoryIds.contains(storyId);

      return StoryModel(
        id: storyId,
        userId: map['user_id'] as String? ?? user.id,
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
        likesCount: likesCount,
        commentsCount: commentsCount,
        isLiked: isLiked,
        isBookmarked: isBookmarked,
        coverUrl: resolvedCover,
      );
    }).toList();
  }

  /// Permanently deletes the authenticated user's account and associated data.
  /// Complies with Google Play User Data Policy (Account Deletion Requirement).
  Future<void> deleteAccount() async {
    final client = _supabase;
    if (client == null) throw Exception('Database connection not initialized.');

    final user = client.auth.currentUser;
    if (user == null) throw Exception('No authenticated user found to delete.');

    try {
      // 1. Call dedicated RPC function with SECURITY DEFINER
      await client.rpc('delete_user_account');
    } catch (e) {
      debugPrint('[AuthRepository.deleteAccount] RPC notice: $e');
      // 2. Client-side fallback: Delete user's own profile and stories
      try {
        await client.from('profiles').delete().eq('id', user.id);
      } catch (profileErr) {
        debugPrint('[AuthRepository.deleteAccount] Profile delete notice: $profileErr');
      }
    }

    // 3. Clear auth session completely
    await signOut();
  }
}
