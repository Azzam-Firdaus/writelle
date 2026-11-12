import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_typography.dart';

/// Central theme configuration for Writtle: Editorial Luxury Meets Organic Paper.
abstract class WrittleTheme {
  static ThemeData get lightTheme {
    final base = ThemeData.light();

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.warmIvory,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: AppColors.burntSienna,
        onPrimary: Colors.white,
        secondary: AppColors.deepOlive,
        onSecondary: Colors.white,
        error: AppColors.error,
        onError: Colors.white,
        surface: AppColors.pureWhite,
        onSurface: AppColors.espresso,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.warmIvory,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: AppTypography.pageHeader,
        iconTheme: const IconThemeData(color: AppColors.espresso),
      ),
      cardTheme: CardThemeData(
        color: AppColors.pureWhite,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.borderLight, width: 1),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.borderLight,
        thickness: 1,
        space: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.pureWhite,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: AppTypography.uiBody.copyWith(color: AppColors.mutedCocoa.withValues(alpha: 0.7)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.burntSienna, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.espresso,
          foregroundColor: AppColors.warmIvory,
          elevation: 0,
          textStyle: AppTypography.buttonText,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.espresso,
          side: const BorderSide(color: AppColors.borderLight, width: 1.5),
          textStyle: AppTypography.buttonText,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.warmIvory,
        selectedItemColor: AppColors.burntSienna,
        unselectedItemColor: AppColors.mutedCocoa,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
