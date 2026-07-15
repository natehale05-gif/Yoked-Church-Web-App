import 'package:flutter/material.dart';

/// A fixed registry of icons the site editor can choose from.
///
/// Icons are referenced by a stable string key so they can be stored as JSON,
/// while the actual [IconData] values stay `const`. That keeps Flutter web's
/// icon tree-shaking working (dynamic IconData would break release builds).
const Map<String, IconData> kAppIcons = {
  'people': Icons.emoji_people_outlined,
  'music': Icons.music_note_outlined,
  'kids': Icons.child_care_outlined,
  'heart': Icons.favorite_border,
  'book': Icons.menu_book_outlined,
  'community': Icons.diversity_3_outlined,
  'give': Icons.volunteer_activism_outlined,
  'toys': Icons.toys_outlined,
  'games': Icons.sports_esports_outlined,
  'coffee': Icons.coffee_outlined,
  'groups': Icons.groups_outlined,
  'piano': Icons.piano_outlined,
  'handshake': Icons.handshake_outlined,
  'church': Icons.church_outlined,
  'star': Icons.star_outline,
  'globe': Icons.public,
  'sun': Icons.wb_sunny_outlined,
  'shield': Icons.shield_outlined,
};

IconData iconForKey(String? key) {
  return kAppIcons[key] ?? Icons.circle_outlined;
}

/// Fallback ordering used when rendering an icon picker.
const List<String> kAppIconKeys = [
  'people', 'music', 'kids', 'heart', 'book', 'community', 'give', 'toys',
  'games', 'coffee', 'groups', 'piano', 'handshake', 'church', 'star',
  'globe', 'sun', 'shield',
];
