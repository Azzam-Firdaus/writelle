import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/cache/cover_cache.dart';
import 'core/constants/supabase_constants.dart';
import 'core/theme/app_theme.dart';
import 'screens/splash/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Concurrently initialize Persistent Cover Cache and Supabase Client
  // to minimize startup latency before mounting root UI
  await Future.wait([
    CoverCache.init(),
    Supabase.initialize(
      url: SupabaseConstants.supabaseUrl,
      publishableKey: SupabaseConstants.supabasePublishableKey,
    ),
  ]);

  // Mount UI immediately to prevent black screen on app startup
  runApp(const WritelleApp());

  // Database ping test to verify Supabase connection on startup (asynchronous non-blocking)
  if (kDebugMode) {
    Supabase.instance.client
        .from('categories')
        .select('name')
        .limit(3)
        .then((res) {
      debugPrint('✅ [Supabase Connected] Initialization successful! Categories detected: $res');
    }).catchError((e) {
      debugPrint('❌ [Supabase Connection Error]: $e');
    });
  }
}

class WritelleApp extends StatelessWidget {
  const WritelleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: MaterialApp(
        title: 'Writelle',
        debugShowCheckedModeBanner: false,
        theme: WrittleTheme.lightTheme,
        home: const SplashScreen(),
      ),
    );
  }
}

// Backward-compatibility alias
typedef WrittleApp = WritelleApp;
