import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/church_config.dart';
import '../utils/color_utils.dart';

/// Fonts we surface in the admin picker. Any Google Font name will work, but
/// these are curated to look good for a church brand.
const List<String> kFontChoices = [
  'Poppins',
  'Inter',
  'Montserrat',
  'Lato',
  'Nunito',
  'Playfair Display',
  'Merriweather',
  'Raleway',
  'Work Sans',
  'DM Sans',
];

class AppTheme {
  const AppTheme._();

  static ThemeData fromConfig(ChurchConfig config) {
    final primary = ColorUtils.fromHex(config.primaryColorHex);
    final secondary = ColorUtils.fromHex(config.secondaryColorHex);
    final accent = ColorUtils.fromHex(config.accentColorHex);
    final brightness = config.darkMode ? Brightness.dark : Brightness.light;
    final radius = config.cornerRadius;

    final scheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: brightness,
    ).copyWith(
      primary: primary,
      secondary: secondary,
      tertiary: accent,
    );

    TextTheme textTheme;
    final base = ThemeData(brightness: brightness).textTheme;
    try {
      textTheme = GoogleFonts.getTextTheme(config.fontFamily, base);
    } catch (_) {
      textTheme = GoogleFonts.getTextTheme('Poppins', base);
    }

    final pill = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0.5,
      ),
      cardTheme: CardTheme(
        elevation: 0,
        color: scheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
        ),
        clipBehavior: Clip.antiAlias,
      ),
      chipTheme: ChipThemeData(
        shape: StadiumBorder(
          side: BorderSide(color: scheme.outlineVariant),
        ),
        backgroundColor: scheme.surfaceContainerHighest,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          shape: StadiumBorder(),
          elevation: 0,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius * 0.6),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius * 0.6),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius * 0.6),
          borderSide: BorderSide(color: primary, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      ),
      dialogTheme: DialogTheme(shape: pill),
      bottomSheetTheme: BottomSheetThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(radius)),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surface,
        indicatorColor: primary.withOpacity(0.15),
        elevation: 3,
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        space: 1,
        thickness: 1,
      ),
    );
  }
}
