import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Central theme. Uses an elegant serif for display headings and a clean,
/// highly legible sans-serif for everything else. Type sizes are intentionally
/// large and airy so the site is easy to read.
class AppTheme {
  const AppTheme._();

  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.ivory,
      colorScheme: const ColorScheme.light(
        primary: AppColors.navy,
        onPrimary: AppColors.onDark,
        secondary: AppColors.gold,
        onSecondary: AppColors.navyDeep,
        surface: AppColors.surface,
        onSurface: AppColors.ink,
      ),
    );

    final display = GoogleFonts.cormorantGaramond;
    final body = GoogleFonts.interTextTheme(base.textTheme);

    return base.copyWith(
      textTheme: body.copyWith(
        displayLarge: display(
          fontSize: 66,
          fontWeight: FontWeight.w600,
          height: 1.05,
          letterSpacing: -0.5,
          color: AppColors.navy,
        ),
        displayMedium: display(
          fontSize: 48,
          fontWeight: FontWeight.w600,
          height: 1.08,
          color: AppColors.navy,
        ),
        displaySmall: display(
          fontSize: 36,
          fontWeight: FontWeight.w600,
          height: 1.12,
          color: AppColors.navy,
        ),
        headlineMedium: display(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          height: 1.2,
          color: AppColors.navy,
        ),
        titleLarge: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          height: 1.3,
          color: AppColors.ink,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 18,
          height: 1.6,
          color: AppColors.inkSoft,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 16,
          height: 1.6,
          color: AppColors.inkSoft,
        ),
        labelLarge: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
          color: AppColors.ink,
        ),
      ),
      dividerColor: AppColors.line,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
    );
  }

  /// A small uppercase label used above section headings ("eyebrow" text).
  static TextStyle eyebrow({Color color = AppColors.gold}) => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        letterSpacing: 2.2,
        color: color,
      );
}
