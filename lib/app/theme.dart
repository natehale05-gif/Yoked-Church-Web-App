import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/config/church_settings.dart';
import '../core/config/contrast.dart';
import '../core/config/settings_providers.dart';

/// Theme is *derived from* [ChurchSettings], so changing a brand color in
/// the admin settings screen re-themes the entire app live.
ThemeData buildTheme(ChurchSettings settings) {
  final brand = settings.colors;

  final colorScheme = ColorScheme.fromSeed(
    seedColor: brand.primary,
    primary: brand.primary,
    secondary: brand.accent,
    surface: Colors.white,
  );

  // Lora (serif) for headings, Work Sans for everything else - both
  // bundled as local assets so text always renders, even for a visitor
  // on a slow or restrictive network.
  final base = Typography.material2021(platform: TargetPlatform.android).black.apply(fontFamily: 'WorkSans');
  final textTheme = base.copyWith(
    displayLarge: base.displayLarge?.copyWith(fontFamily: 'Lora', fontSize: 56, fontWeight: FontWeight.w700),
    displayMedium: base.displayMedium?.copyWith(fontFamily: 'Lora', fontSize: 40, fontWeight: FontWeight.w700),
    headlineMedium: base.headlineMedium?.copyWith(fontFamily: 'Lora', fontSize: 28, fontWeight: FontWeight.w600),
    titleLarge: base.titleLarge?.copyWith(fontSize: 20, fontWeight: FontWeight.w600),
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: brand.background,
    fontFamily: 'WorkSans',
    textTheme: textTheme,
    appBarTheme: AppBarTheme(
      backgroundColor: brand.background,
      foregroundColor: brand.primary,
      elevation: 0,
      centerTitle: false,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: brand.accent,
        // Not white. Every one of the six bundled palettes has a
        // mid-tone accent, and white on those measures 2.4 to 3.9
        // against the 4.5 that normal text needs - on Give, on Plan a
        // Visit, on Sign In, on every primary action in the app, read
        // on a phone and often outdoors. See core/config/contrast.dart.
        foregroundColor: readableOn(brand.accent),
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        textStyle: const TextStyle(fontFamily: 'WorkSans', fontWeight: FontWeight.w600, letterSpacing: 0.5),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: brand.primary,
        side: BorderSide(color: brand.primary),
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Colors.black.withValues(alpha: 0.06)),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: brand.primary.withValues(alpha: 0.08),
      side: BorderSide.none,
    ),
    dividerTheme: DividerThemeData(color: Colors.black.withValues(alpha: 0.08)),
    inputDecorationTheme: const InputDecorationTheme(border: OutlineInputBorder()),
  );
}

final themeProvider = Provider<ThemeData>((ref) => buildTheme(ref.watch(settingsProvider)));

/// Breakpoints shared across the app for responsive (web-first) layout.
class Breakpoints {
  const Breakpoints._();

  static const double mobile = 640;
  static const double desktop = 1024;

  static bool isMobile(BuildContext context) => MediaQuery.sizeOf(context).width < mobile;
  static bool isDesktop(BuildContext context) => MediaQuery.sizeOf(context).width >= desktop;
}
