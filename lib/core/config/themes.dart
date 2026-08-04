import 'package:flutter/material.dart';

import 'church_settings.dart';

/// Ready-made looks, so branding is a choice rather than homework.
///
/// The settings screen asks for three hex codes. A church that has a
/// brand guide can paste them; a church that has a logo somebody's
/// nephew made in 2011 cannot, and was left staring at
/// `#RRGGBB`. Picking a theme fills those same three fields - it is a
/// shortcut into the form, not a second place branding is stored, so
/// there is nothing new to save and nothing that can disagree.
///
/// Deliberately few, and deliberately not "modern / classic / bold".
/// Nine near-identical blues is a harder choice than four obviously
/// different ones.
@immutable
class ChurchTheme {
  final String name;

  /// What kind of church tends to want it. Read out under the swatch,
  /// because "Slate" tells nobody anything.
  final String description;

  final BrandColors colors;

  const ChurchTheme({
    required this.name,
    required this.description,
    required this.colors,
  });

  /// True when the church's current colours already are this theme, so
  /// the gallery can show which one is in use.
  bool matches(BrandColors other) =>
      colors.primary.toARGB32() == other.primary.toARGB32() &&
      colors.accent.toARGB32() == other.accent.toARGB32() &&
      colors.background.toARGB32() == other.background.toARGB32();
}

BrandColors _colors(String primary, String accent, String background) =>
    BrandColors.fromMap({'primary': primary, 'accent': accent, 'background': background});

/// The gallery.
///
/// The first is what a new church starts as, so it is the one that has
/// to look like nobody chose it wrong.
final List<ChurchTheme> churchThemes = [
  // Exactly [BrandColors.fallback], and exactly what `createChurch`
  // writes - so the first thing the settings screen tells a brand-new
  // church is not that its colours are none of the options.
  const ChurchTheme(
    name: 'Harbour',
    description: 'Deep navy and brass. Steady, traditional, hard to get wrong.',
    colors: BrandColors.fallback,
  ),
  ChurchTheme(
    name: 'Chapel',
    description: 'Warm stone and oxblood. Suits an older building.',
    colors: _colors('#4A2B2B', '#B4703A', '#FAF6F0'),
  ),
  ChurchTheme(
    name: 'Meadow',
    description: 'Forest green and wheat. Quiet, rural, unhurried.',
    colors: _colors('#2F4B3F', '#C9A227', '#F6F5F0'),
  ),
  ChurchTheme(
    name: 'Vigil',
    description: 'Plum and gold, for a liturgical calendar.',
    colors: _colors('#3B2E52', '#C9A227', '#F7F4F2'),
  ),
  ChurchTheme(
    name: 'Riverbed',
    description: 'Slate and teal. Plainer, and reads as newer.',
    colors: _colors('#26343B', '#3F8E8C', '#F4F6F6'),
  ),
  ChurchTheme(
    name: 'Sunrise',
    description: 'Ink and coral. Brighter, for a younger congregation.',
    colors: _colors('#1F2933', '#E2725B', '#FBF7F4'),
  ),
];
