import 'package:flutter/material.dart';

/// Reusable Writelle Logo widget that renders the official brand identity (`assets/images/logo_light.png`).
class WritelleLogo extends StatelessWidget {
  final double? height;
  final double? width;
  final BoxFit fit;
  final Alignment alignment;

  const WritelleLogo({
    super.key,
    this.height = 36,
    this.width,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.center,
  });

  /// Factory for Top AppBar branding
  const WritelleLogo.appBar({
    super.key,
    this.height = 34,
    this.width,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.centerLeft,
  });

  /// Factory for Hero display (Login, Splash, Profile)
  const WritelleLogo.hero({
    super.key,
    this.height = 140,
    this.width,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.center,
  });

  @override
  Widget build(BuildContext context) {
    const assetPath = 'assets/images/logo_light.png';

    return Image.asset(
      assetPath,
      key: const ValueKey('writelle_brand_logo'),
      height: height,
      width: width,
      fit: fit,
      alignment: alignment,
      errorBuilder: (context, error, stackTrace) {
        return Text(
          'Writelle',
          style: TextStyle(
            fontSize: height != null ? (height! * 0.55) : 22,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
            color: const Color(0xFF16211B),
          ),
        );
      },
    );
  }
}
