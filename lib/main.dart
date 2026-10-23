import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/constants/supabase_constants.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/editorial_button.dart';
import 'core/widgets/writtle_app_bar.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase Client
  await Supabase.initialize(
    url: SupabaseConstants.supabaseUrl,
    publishableKey: SupabaseConstants.supabasePublishableKey,
  );

  runApp(
    const ProviderScope(
      child: WrittleApp(),
    ),
  );
}

class WrittleApp extends StatelessWidget {
  const WrittleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Writtle',
      debugShowCheckedModeBanner: false,
      theme: WrittleTheme.lightTheme,
      home: const WelcomeScreen(),
    );
  }
}

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const WrittleAppBar(
        title: 'Writtle',
        isBrandTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '“Your story matters, even when your name doesn’t.”',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontStyle: FontStyle.italic,
                    ),
              ),
              const SizedBox(height: 32),
              EditorialButton(
                label: 'Explore Stories',
                onPressed: () {},
                variant: EditorialButtonVariant.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
