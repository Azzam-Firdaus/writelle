import 'dart:async';
import 'package:flutter/material.dart';
import '../main_shell_screen.dart';

/// Serene Editorial Splash Screen displaying official Writelle identity & poetic tagline.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  Timer? _navigationTimer;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );

    _fadeController.forward();

    // Transition smoothly after 2.3 seconds
    _navigationTimer = Timer(const Duration(milliseconds: 2300), () {
      _navigateToMain();
    });
  }

  void _navigateToMain() {
    if (_hasNavigated || !mounted) return;
    _hasNavigated = true;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 600),
        pageBuilder: (context, animation, secondaryAnimation) =>
            const MainShellScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _navigateToMain,
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F4EF), // Warm Parchment Sanctuary
        body: SafeArea(
          child: Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 36.0),
                child: Image.asset(
                  'assets/images/splash_screen.png',
                  fit: BoxFit.contain,
                  width: double.infinity,
                  alignment: Alignment.center,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
