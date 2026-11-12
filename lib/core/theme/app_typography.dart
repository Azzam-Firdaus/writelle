import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Typography pairing for Writtle: Editorial Luxury Meets Organic Paper:
/// - Editorial Serif (Lora) for literary headlines, display titles, pull quotes, and reading text.
/// - Crisp Sans (Inter) for interface elements, metadata, kickers, and buttons.
abstract class AppTypography {
  // --- Editorial Serif (Literary & Reading) ---

  /// Hero Display for Editorial Features and Welcome Headers (32sp Bold)
  static TextStyle heroDisplay = GoogleFonts.lora(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    height: 1.20,
    letterSpacing: -0.6,
    color: AppColors.espresso,
  );

  /// Display Title for Cover Stories and Major Sections (28sp Bold)
  static TextStyle displayTitle = GoogleFonts.lora(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    height: 1.25,
    letterSpacing: -0.4,
    color: AppColors.espresso,
  );

  /// Unified App Bar & Screen Header (22sp Bold)
  static TextStyle pageHeader = GoogleFonts.lora(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    height: 1.25,
    letterSpacing: -0.3,
    color: AppColors.espresso,
  );

  /// Editorial Story Heading for Cards and Detail Titles (20sp SemiBold)
  static TextStyle storyHeading = GoogleFonts.lora(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.30,
    color: AppColors.espresso,
  );

  /// Story Body for Literary Reading with comfortable line height (17sp)
  static TextStyle storyBody = GoogleFonts.lora(
    fontSize: 17,
    fontWeight: FontWeight.w400,
    height: 1.70,
    color: AppColors.espresso,
  );

  /// Pull quote for atmospheric quotes and highlights (18sp Italic)
  static TextStyle pullQuote = GoogleFonts.lora(
    fontSize: 18,
    fontStyle: FontStyle.italic,
    fontWeight: FontWeight.w500,
    height: 1.55,
    color: AppColors.espresso,
  );

  // --- Clean Sans (Interface & Metadata) ---

  /// Editorial Kicker for category tags and section eyebrows (10.5sp Bold Uppercase)
  static TextStyle kicker = GoogleFonts.inter(
    fontSize: 10.5,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.4,
    color: AppColors.burntSienna,
  );

  /// Interface Headline for cards and section labels (15sp Medium)
  static TextStyle uiHeadline = GoogleFonts.inter(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    height: 1.40,
    color: AppColors.espresso,
  );

  /// Interface Body for general UI text (14sp)
  static TextStyle uiBody = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.45,
    color: AppColors.espresso,
  );

  /// Interface Body Medium for labels and form field titles (14sp Medium)
  static TextStyle uiBodyMedium = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.45,
    color: AppColors.espresso,
  );

  /// Caption Metadata for timestamps, author handles, reading time (12sp)
  static TextStyle captionMeta = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.35,
    color: AppColors.mutedCocoa,
  );

  /// Button Text for tactile interactive elements (14sp SemiBold)
  static TextStyle buttonText = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.3,
  );
}
