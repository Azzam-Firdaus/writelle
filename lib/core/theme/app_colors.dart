import 'package:flutter/material.dart';

/// Design tokens for the Writtle Editorial Warm Neutral color palette.
/// Ref: docs/UI_UX_DESIGN.md
abstract class AppColors {
  /// Primary background: warm parchment / cream white
  static const Color backgroundLight = Color(0xFFFBF9F5);

  /// Elevated surfaces (cards, sheets, modals)
  static const Color surfaceLight = Color(0xFFFFFFFF);

  /// Warm secondary surface for category chips, quote blocks, and subtle containers
  static const Color surfaceWarm = Color(0xFFF3EFE6);

  /// Deep charcoal / ink for primary readable text
  static const Color textPrimary = Color(0xFF1A1816);

  /// Muted charcoal for captions, reading time, and secondary metadata
  static const Color textSecondary = Color(0xFF635F59);

  /// Subtle gray for placeholders, inactive icons, and faint borders
  static const Color textTertiary = Color(0xFF9C978F);

  /// Deep Ochre / Terracotta for primary actions and active state accents
  static const Color accentPrimary = Color(0xFF8B4513);

  /// Warm amber highlight for badges and subtle alerts
  static const Color accentSubtle = Color(0xFFD97736);

  /// Ultra-subtle hairline border for structural separation
  static const Color borderLight = Color(0xFFE8E3DA);

  /// Muted crimson for errors and destructive actions
  static const Color error = Color(0xFFB9382F);

  /// Deep forest green for success indicators and toasts
  static const Color success = Color(0xFF2D6A4F);
}
