import 'package:shared_preferences/shared_preferences.dart';

/// Persistent cache for story cover image URLs/paths.
/// Ensures cover images persist seamlessly across app restarts and views,
/// even if the remote database column has not yet been migrated on Supabase.
class CoverCache {
  static final Map<String, String> _cache = {};
  static const String _prefix = 'writelle_cover_';
  static bool _initialized = false;

  /// Initializes cached covers from persistent storage
  static Future<void> init() async {
    if (_initialized) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((k) => k.startsWith(_prefix));
      for (final k in keys) {
        final storyId = k.replaceFirst(_prefix, '');
        final val = prefs.getString(k);
        if (val != null && val.isNotEmpty) {
          _cache[storyId] = val;
        }
      }
      _initialized = true;
    } catch (_) {}
  }

  /// Stores a cover URL or local path for a story ID
  static void set(String storyId, String coverUrl) {
    final cleanUrl = coverUrl.trim();
    if (cleanUrl.isNotEmpty) {
      _cache[storyId] = cleanUrl;
      SharedPreferences.getInstance().then((prefs) {
        prefs.setString('$_prefix$storyId', cleanUrl);
      }).catchError((_) {});
    }
  }

  /// Retrieves the cached cover URL/path for a story ID
  static String? get(String storyId) => _cache[storyId];

  /// Removes cached entry for a story ID
  static void remove(String storyId) {
    _cache.remove(storyId);
    SharedPreferences.getInstance().then((prefs) {
      prefs.remove('$_prefix$storyId');
    }).catchError((_) {});
  }

  /// Clears entire cover cache
  static void clear() {
    _cache.clear();
    SharedPreferences.getInstance().then((prefs) {
      final keys = prefs.getKeys().where((k) => k.startsWith(_prefix));
      for (final k in keys) {
        prefs.remove(k);
      }
    }).catchError((_) {});
  }
}
