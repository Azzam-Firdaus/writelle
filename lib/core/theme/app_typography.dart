import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Typography pairing for Writtle Editorial Minimalism:
/// - Serif (Lora) for literary headlines and reading body text.
/// - Sans (Inter) for crisp interface labels, navigation, and metadata.
/// Ref: docs/UI_UX_DESIGN.md
abstract class AppTypography {
  // --- Editorial Serif (Reading & Headlines) ---

  static TextStyle displayTitle = GoogleFonts.lora(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    height: 1.25,
    color: AppColors.textPrimary,
  );

  static TextStyle storyHeading = GoogleFonts.lora(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    height: 1.30,
    color: AppColors.textPrimary,
  );

  static TextStyle storyBody = GoogleFonts.lora(
    fontSize: 17,
    fontWeight: FontWeight.w400,
    height: 1.65,
    color: AppColors.textPrimary,
  );

  // --- Clean Sans (Interface & Metadata) ---

  static TextStyle uiHeadline = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 1.40,
    color: AppColors.textPrimary,
  );

  static TextStyle uiBody = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.45,
    color: AppColors.textPrimary,
  );

  static TextStyle uiBodyMedium = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.45,
    color: AppColors.textPrimary,
  );

  static TextStyle captionMeta = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.35,
    color: AppColors.textSecondary,
  );

  static TextStyle buttonText = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.2,
  );
}
