import 'package:flutter/material.dart';

/// Premium, warm, high-contrast palette designed for readability.
/// Deep navy ink on a soft ivory background with a refined gold accent.
class AppColors {
  const AppColors._();

  // Brand
  static const Color navy = Color(0xFF16233F); // primary / headings
  static const Color navyDeep = Color(0xFF0E1830); // hero overlays
  static const Color gold = Color(0xFFC6A15B); // accent
  static const Color goldSoft = Color(0xFFE7D3A8);

  // Neutrals
  static const Color ivory = Color(0xFFFBF9F6); // page background
  static const Color cream = Color(0xFFF4EFE7); // alt section background
  static const Color surface = Color(0xFFFFFFFF); // cards
  static const Color ink = Color(0xFF1A1C22); // body text
  static const Color inkSoft = Color(0xFF5B6270); // secondary text
  static const Color line = Color(0xFFE7E1D8); // hairlines / borders

  // On-dark text
  static const Color onDark = Color(0xFFF6F3EE);
  static const Color onDarkSoft = Color(0xFFC7CBD4);

  // Gentle gradient used behind people-photo placeholders.
  static const List<Color> photoPlaceholder = [
    Color(0xFF243456),
    Color(0xFF16233F),
  ];
}
