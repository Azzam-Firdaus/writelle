import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile_model.dart';
import '../providers/auth_provider.dart';

/// In-memory and Supabase-synced repository for managing follows.
/// Supports real-time local cache with graceful remote Supabase persistence.
class FollowRepository {
  final SupabaseClient? _supabase;

  // In-memory cache for fast, reactive, offline-friendly follow relationships
  // Key: followerId -> Set of followingIds
  static final Map<String, Set<String>> _followingMap = {};
  // Key: followingId -> Set of followerIds
  static final Map<String, Set<String>> _followersMap = {};

  FollowRepository({SupabaseClient? supabase})
      : _supabase = supabase ??
            (() {
              try {
                return Supabase.instance.client;
              } catch (_) {
                return null;
              }
            })();

  /// Checks if a user is following another user
  Future<bool> isFollowing({
    required String followerId,
    required String followingId,
  }) async {
    // 1. Try Supabase query first for accurate status
    if (_supabase != null) {
      try {
        final res = await _supabase
            .from('follows')
            .select('id')
            .eq('follower_id', followerId)
            .eq('following_id', followingId)
            .maybeSingle();

        final isF = res != null;
        _updateLocalCache(followerId, followingId, isF);
        return isF;
      } catch (e) {
        debugPrint('[FollowRepository] Supabase isFollowing notice: $e');
      }
    }

    // 2. Fallback to local cache
    final cached = _followingMap[followerId]?.contains(followingId);
    if (cached != null) return cached;
    return false;
  }

  /// Follow a user
  Future<void> follow({
    required String followerId,
    required String followingId,
  }) async {
    if (followerId == followingId) return;

    // Update local cache immediately
    _updateLocalCache(followerId, followingId, true);

    // Try remote persistence if table exists
    if (_supabase != null) {
      try {
        await _supabase.from('follows').insert({
          'follower_id': followerId,
          'following_id': followingId,
        });
      } catch (e) {
        debugPrint('[FollowRepository] Remote follow insert fallback: $e');
      }
    }
  }

  /// Unfollow a user
  Future<void> unfollow({
    required String followerId,
    required String followingId,
  }) async {
    // Update local cache immediately
    _updateLocalCache(followerId, followingId, false);

    // Try remote persistence if table exists
    if (_supabase != null) {
      try {
        await _supabase
            .from('follows')
            .delete()
            .eq('follower_id', followerId)
            .eq('following_id', followingId);
      } catch (e) {
        debugPrint('[FollowRepository] Remote follow delete fallback: $e');
      }
    }
  }

  /// Gets total followers count for a user (Readers)
  Future<int> getFollowersCount(String userId) async {
    if (_supabase != null) {
      try {
        final res = await _supabase
            .from('follows')
            .select('id')
            .eq('following_id', userId);
        return (res as List).length;
      } catch (e) {
        debugPrint('[FollowRepository.getFollowersCount] notice: $e');
      }
    }
    return _followersMap[userId]?.length ?? 0;
  }

  /// Gets total following count for a user (Following)
  Future<int> getFollowingCount(String userId) async {
    if (_supabase != null) {
      try {
        final res = await _supabase
            .from('follows')
            .select('id')
            .eq('follower_id', userId);
        return (res as List).length;
      } catch (e) {
        debugPrint('[FollowRepository.getFollowingCount] notice: $e');
      }
    }
    return _followingMap[userId]?.length ?? 0;
  }

  /// Gets list of user profiles who are following [userId] (Readers)
  Future<List<UserProfileModel>> getFollowers(String userId) async {
    final List<String> followerIds = [];

    // Query remote Supabase database if available
    if (_supabase != null) {
      try {
        final res = await _supabase
            .from('follows')
            .select('follower_id')
            .eq('following_id', userId);
        final remoteIds = <String>{};
        for (final row in (res as List)) {
          final id = row['follower_id']?.toString();
          if (id != null && id.isNotEmpty) {
            remoteIds.add(id);
          }
        }
        _followersMap[userId] = remoteIds;
        followerIds.addAll(remoteIds);
      } catch (e) {
        debugPrint('[FollowRepository] Supabase getFollowers query notice: $e');
        if (_followersMap.containsKey(userId)) {
          followerIds.addAll(_followersMap[userId]!);
        }
      }
    } else {
      if (_followersMap.containsKey(userId)) {
        followerIds.addAll(_followersMap[userId]!);
      }
    }

    if (followerIds.isEmpty) return [];

    return await _fetchProfilesByIds(followerIds);
  }

  /// Gets list of user profiles whom [userId] is following (Following)
  Future<List<UserProfileModel>> getFollowing(String userId) async {
    final List<String> followingIds = [];

    // Query remote Supabase database if available
    if (_supabase != null) {
      try {
        final res = await _supabase
            .from('follows')
            .select('following_id')
            .eq('follower_id', userId);
        final remoteIds = <String>{};
        for (final row in (res as List)) {
          final id = row['following_id']?.toString();
          if (id != null && id.isNotEmpty) {
            remoteIds.add(id);
          }
        }
        _followingMap[userId] = remoteIds;
        followingIds.addAll(remoteIds);
      } catch (e) {
        debugPrint('[FollowRepository] Supabase getFollowing query notice: $e');
        if (_followingMap.containsKey(userId)) {
          followingIds.addAll(_followingMap[userId]!);
        }
      }
    } else {
      if (_followingMap.containsKey(userId)) {
        followingIds.addAll(_followingMap[userId]!);
      }
    }

    if (followingIds.isEmpty) return [];

    return await _fetchProfilesByIds(followingIds);
  }

  Future<List<UserProfileModel>> _fetchProfilesByIds(List<String> ids) async {
    if (ids.isEmpty) return [];

    final Map<String, UserProfileModel> foundProfiles = {};

    if (_supabase != null) {
      try {
        final res = await _supabase
            .from('profiles')
            .select()
            .inFilter('id', ids);
        for (final row in (res as List)) {
          try {
            final model = UserProfileModel.fromMap(Map<String, dynamic>.from(row as Map));
            foundProfiles[model.id] = model;
          } catch (e) {
            debugPrint('[FollowRepository] Profile parse error: $e');
          }
        }
      } catch (e) {
        debugPrint('[FollowRepository] Fetch profiles inFilter notice: $e');
      }

      // If inFilter missed any profile (e.g. filter query issues), query individually
      for (final id in ids) {
        if (!foundProfiles.containsKey(id)) {
          try {
            final singleRes = await _supabase
                .from('profiles')
                .select()
                .eq('id', id)
                .maybeSingle();
            if (singleRes != null) {
              final model = UserProfileModel.fromMap(Map<String, dynamic>.from(singleRes as Map));
              foundProfiles[model.id] = model;
            }
          } catch (e) {
            debugPrint('[FollowRepository] Single profile fetch error for $id: $e');
          }
        }
      }
    }

    // Preserve the original ordering of incoming IDs with graceful fallback
    final List<UserProfileModel> result = [];
    for (final id in ids) {
      if (foundProfiles.containsKey(id)) {
        result.add(foundProfiles[id]!);
      } else {
        result.add(UserProfileModel(
          id: id,
          penName: 'Author_${id.length > 6 ? id.substring(0, 6) : id}',
          bio: 'A fellow writer wandering the sanctuary.',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ));
      }
    }

    return result;
  }

  void _updateLocalCache(String followerId, String followingId, bool isFollowing) {
    _followingMap.putIfAbsent(followerId, () => <String>{});
    _followersMap.putIfAbsent(followingId, () => <String>{});

    if (isFollowing) {
      _followingMap[followerId]!.add(followingId);
      _followersMap[followingId]!.add(followerId);
    } else {
      _followingMap[followerId]!.remove(followingId);
      _followersMap[followingId]!.remove(followerId);
    }
  }
}

final followRepositoryProvider = Provider<FollowRepository>((ref) {
  return FollowRepository();
});

class FollowStats {
  final int followers;
  final int following;

  const FollowStats({required this.followers, required this.following});
}

/// Provider for user's followers and following counts
final userFollowStatsProvider =
    FutureProvider.family<FollowStats, String>((ref, userId) async {
  final repo = ref.watch(followRepositoryProvider);
  final followers = await repo.getFollowersCount(userId);
  final following = await repo.getFollowingCount(userId);
  return FollowStats(followers: followers, following: following);
});

/// Provider to check if current user follows target author
final isFollowingTargetProvider =
    FutureProvider.family<bool, String>((ref, targetUserId) async {
  final authRepo = ref.watch(authRepositoryProvider);
  final currentUserId = authRepo.currentUser?.id;
  if (currentUserId == null) return false;

  final repo = ref.watch(followRepositoryProvider);
  return await repo.isFollowing(
    followerId: currentUserId,
    followingId: targetUserId,
  );
});

/// Provider for list of user's readers / followers
final userFollowersProvider =
    FutureProvider.family<List<UserProfileModel>, String>((ref, userId) async {
  final repo = ref.watch(followRepositoryProvider);
  return await repo.getFollowers(userId);
});

/// Provider for list of accounts user is following
final userFollowingProvider =
    FutureProvider.family<List<UserProfileModel>, String>((ref, userId) async {
  final repo = ref.watch(followRepositoryProvider);
  return await repo.getFollowing(userId);
});
