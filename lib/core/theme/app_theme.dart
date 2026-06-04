import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_typography.dart';

class AppSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
}

class AppRadius {
  static const sm = 12.0;
  static const md = 20.0;
  static const lg = 28.0;
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.cream,
      colorScheme: const ColorScheme.light(
        primary: AppColors.red,
        onPrimary: AppColors.white,
        secondary: AppColors.yellow,
        onSecondary: AppColors.textDark,
        surface: AppColors.white,
        onSurface: AppColors.textDark,
        error: AppColors.redSoft,
      ),
      textTheme: AppTypography.textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.cream,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.textDark),
        titleTextStyle: AppTypography.textTheme.headlineMedium,
      ),
      cardTheme: CardThemeData(
        color: AppColors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          side: const BorderSide(color: AppColors.tan1, width: 1.5),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.red,
          foregroundColor: AppColors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(100),
          ),
          textStyle: AppTypography.textTheme.titleMedium?.copyWith(
            color: AppColors.white,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textDark,
          side: const BorderSide(color: AppColors.tan1, width: 1.5),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(100),
          ),
          textStyle: AppTypography.textTheme.titleMedium?.copyWith(
            color: AppColors.textDark,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.cream,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: const BorderSide(color: AppColors.tan1, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: const BorderSide(color: AppColors.tan1, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: const BorderSide(color: AppColors.redSoft, width: 1.5),
        ),
        hintStyle: AppTypography.textTheme.bodyMedium?.copyWith(
          color: AppColors.textLight,
        ),
      ),
    );
  }
}
