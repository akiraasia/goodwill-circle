import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTypography {
  static TextTheme get textTheme {
    return TextTheme(
      displayLarge: GoogleFonts.dmSerifDisplay(
        color: AppColors.textDark,
        fontSize: 32,
      ),
      displayMedium: GoogleFonts.dmSerifDisplay(
        color: AppColors.textDark,
        fontSize: 28,
      ),
      displaySmall: GoogleFonts.dmSerifDisplay(
        color: AppColors.textDark,
        fontSize: 24,
      ),
      headlineLarge: GoogleFonts.dmSerifDisplay(
        color: AppColors.textDark,
        fontSize: 22,
      ),
      headlineMedium: GoogleFonts.dmSerifDisplay(
        color: AppColors.textDark,
        fontSize: 20,
      ),
      headlineSmall: GoogleFonts.dmSerifDisplay(
        color: AppColors.textDark,
        fontSize: 18,
      ),
      titleLarge: GoogleFonts.dmSans(
        color: AppColors.textDark,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      titleMedium: GoogleFonts.dmSans(
        color: AppColors.textDark,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      titleSmall: GoogleFonts.dmSans(
        color: AppColors.textDark,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: GoogleFonts.dmSans(color: AppColors.textMid, fontSize: 16),
      bodyMedium: GoogleFonts.dmSans(color: AppColors.textMid, fontSize: 14),
      bodySmall: GoogleFonts.dmSans(color: AppColors.textMid, fontSize: 12),
      labelLarge: GoogleFonts.dmSans(
        color: AppColors.textLight,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      labelMedium: GoogleFonts.dmSans(
        color: AppColors.textLight,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
      labelSmall: GoogleFonts.dmSans(
        color: AppColors.textLight,
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.2,
      ),
    );
  }
}
