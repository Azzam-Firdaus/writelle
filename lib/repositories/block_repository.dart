import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Repository managing blocked authors locally to comply with
/// Google Play Store User-Generated Content (UGC) policy.
class BlockRepository {
  static const String _prefKey = 'writtle_blocked_authors_set';

  Future<Set<String>> getBlockedAuthorIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_prefKey) ?? [];
      return list.toSet();
    } catch (e) {
      debugPrint('[BlockRepository] Load error: $e');
      return {};
    }
  }

  Future<bool> isAuthorBlocked(String authorId) async {
    final blocked = await getBlockedAuthorIds();
    return blocked.contains(authorId);
  }

  Future<void> blockAuthor(String authorId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = (prefs.getStringList(_prefKey) ?? []).toSet();
      list.add(authorId);
      await prefs.setStringList(_prefKey, list.toList());
    } catch (e) {
      debugPrint('[BlockRepository] Block error: $e');
    }
  }

  Future<void> unblockAuthor(String authorId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = (prefs.getStringList(_prefKey) ?? []).toSet();
      list.remove(authorId);
      await prefs.setStringList(_prefKey, list.toList());
    } catch (e) {
      debugPrint('[BlockRepository] Unblock error: $e');
    }
  }
}

final blockRepositoryProvider = Provider<BlockRepository>((ref) {
  return BlockRepository();
});

final blockedAuthorsProvider = FutureProvider<Set<String>>((ref) async {
  final repo = ref.watch(blockRepositoryProvider);
  return await repo.getBlockedAuthorIds();
});

final isAuthorBlockedProvider = FutureProvider.family<bool, String>((ref, authorId) async {
  final repo = ref.watch(blockRepositoryProvider);
  return await repo.isAuthorBlocked(authorId);
});
