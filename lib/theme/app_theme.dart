import 'package:flutter/material.dart';

import '../config/church_config.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData get light {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: ChurchConfig.primaryColor,
      primary: ChurchConfig.primaryColor,
      secondary: ChurchConfig.accentColor,
      surface: Colors.white,
    );

    // Lora (serif) for headings, Work Sans for everything else - both
    // bundled as local assets (see pubspec.yaml) so text always renders,
    // even for a visitor on a slow or restrictive network.
    final baseTextTheme = Typography.material2021(platform: TargetPlatform.android).black.apply(fontFamily: 'WorkSans');
    final textTheme = baseTextTheme.copyWith(
      displayLarge: baseTextTheme.displayLarge?.copyWith(fontFamily: 'Lora', fontSize: 56, fontWeight: FontWeight.w700),
      displayMedium: baseTextTheme.displayMedium?.copyWith(fontFamily: 'Lora', fontSize: 40, fontWeight: FontWeight.w700),
      headlineMedium: baseTextTheme.headlineMedium?.copyWith(fontFamily: 'Lora', fontSize: 28, fontWeight: FontWeight.w600),
      titleLarge: baseTextTheme.titleLarge?.copyWith(fontSize: 20, fontWeight: FontWeight.w600),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: ChurchConfig.backgroundColor,
      fontFamily: 'WorkSans',
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: ChurchConfig.backgroundColor,
        foregroundColor: ChurchConfig.primaryColor,
        elevation: 0,
        centerTitle: false,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: ChurchConfig.accentColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          textStyle: const TextStyle(fontFamily: 'WorkSans', fontWeight: FontWeight.w600, letterSpacing: 0.5),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ChurchConfig.primaryColor,
          side: BorderSide(color: ChurchConfig.primaryColor),
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
      dividerTheme: DividerThemeData(color: Colors.black.withValues(alpha: 0.08)),
    );
  }
}

/// Breakpoints shared across screens for responsive (web-first) layout.
class Breakpoints {
  const Breakpoints._();

  static const double mobile = 640;
  static const double tablet = 1024;

  static bool isMobile(BuildContext context) => MediaQuery.of(context).size.width < mobile;
  static bool isDesktop(BuildContext context) => MediaQuery.of(context).size.width >= tablet;
}
