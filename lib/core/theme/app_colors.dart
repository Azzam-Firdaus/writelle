import 'package:flutter/material.dart';

/// Design tokens for Writtle: Editorial Luxury Meets Organic Paper.
/// Palette:
/// - Warm ivory: #FAF7F0
/// - Soft parchment: #F0E8DB
/// - Warm sand: #E5D4BE
/// - Espresso: #261D17
/// - Muted cocoa: #857467
/// - Burnt sienna: #99572D
/// - Deep olive accent: #72745B
/// - White: #FFFFFF
abstract class AppColors {
  // ==========================================
  // CORE EDITORIAL PALETTE TOKENS
  // ==========================================

  /// Primary canvas background: warm ivory (#FAF7F0)
  static const Color warmIvory = Color(0xFFFAF7F0);

  /// Secondary paper surface: soft parchment (#F0E8DB)
  static const Color softParchment = Color(0xFFF0E8DB);

  /// Warm accent surface & ambient tone: warm sand (#E5D4BE)
  static const Color warmSand = Color(0xFFE5D4BE);

  /// Primary ink & dark feature sections: espresso (#261D17)
  static const Color espresso = Color(0xFF261D17);

  /// Muted literary secondary text: muted cocoa (#857467)
  static const Color mutedCocoa = Color(0xFF857467);

  /// Primary brand & interactive accent: burnt sienna (#99572D)
  static const Color burntSienna = Color(0xFF99572D);

  /// Secondary literary & botanical accent: deep olive (#72745B)
  static const Color deepOlive = Color(0xFF72745B);

  /// Pure crisp white reading surface: white (#FFFFFF)
  static const Color pureWhite = Color(0xFFFFFFFF);

  // ==========================================
  // LIGHT PALETTE (Editorial Luxury Sanctuary)
  // ==========================================

  static const Color backgroundLight = warmIvory;
  static const Color surfaceLight = pureWhite;
  static const Color surfaceWarmLight = softParchment;
  static const Color surfaceSandLight = warmSand;
  static const Color textPrimaryLight = espresso;
  static const Color textSecondaryLight = mutedCocoa;
  static const Color textTertiaryLight = Color(0xFFAFA397);
  static const Color borderLight = Color(0xFFE5DCD0);
  static const Color borderSubtleLight = Color(0xFFEFE8DE);
  static const Color accentPrimaryLight = burntSienna;
  static const Color accentSubtleLight = Color(0xFFC07A4A);
  static const Color accentOliveLight = deepOlive;

  // ==========================================
  // DARK PALETTE (Sanctuary Nocturnal Espresso)
  // ==========================================

  static const Color backgroundDark = Color(0xFF1B1410);
  static const Color surfaceDark = Color(0xFF261D17);
  static const Color surfaceWarmDark = Color(0xFF332720);
  static const Color textPrimaryDark = warmIvory;
  static const Color textSecondaryDark = warmSand;
  static const Color textTertiaryDark = Color(0xFF9B8C80);
  static const Color borderDark = Color(0xFF3D3027);
  static const Color accentPrimaryDark = Color(0xFFD48B57);
  static const Color accentSubtleDark = Color(0xFFE5A46E);

  // ==========================================
  // COMMON SEMANTIC COLORS
  // ==========================================

  static const Color error = Color(0xFFB3392F);
  static const Color errorDark = Color(0xFFEF5350);
  static const Color success = Color(0xFF3E694D);
  static const Color successDark = Color(0xFF66BB6A);

  // ==========================================
  // BACKWARD COMPATIBILITY STATIC ALIASES
  // ==========================================

  static const Color surfaceWarm = surfaceWarmLight;
  static const Color textPrimary = textPrimaryLight;
  static const Color textSecondary = textSecondaryLight;
  static const Color textTertiary = textTertiaryLight;
  static const Color accentPrimary = accentPrimaryLight;
  static const Color accentSubtle = accentSubtleLight;

  // ==========================================
  // DYNAMIC CONTEXT-AWARE THEME COLOR RESOLVERS
  // ==========================================

  static Color background(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? backgroundDark : backgroundLight;

  static Color surface(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? surfaceDark : surfaceLight;

  static Color surfaceWarmColor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? surfaceWarmDark : surfaceWarmLight;

  static const Color surfaceSandDark = Color(0xFF3D3027);
  static const Color oliveDark = Color(0xFF8B8D73);

  static Color surfaceSandColor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? surfaceSandDark : surfaceSandLight;

  static Color textPrimaryColor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? textPrimaryDark : textPrimaryLight;

  static Color textSecondaryColor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? textSecondaryDark : textSecondaryLight;

  static Color textTertiaryColor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? textTertiaryDark : textTertiaryLight;

  static Color borderColor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? borderDark : borderLight;

  static Color accent(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? accentPrimaryDark : accentPrimaryLight;

  static Color olive(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? oliveDark : deepOlive;
}
