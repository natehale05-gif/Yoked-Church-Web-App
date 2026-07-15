import 'package:flutter/material.dart';

/// Curated set of icons an admin can assign to a ministry.
const Map<String, IconData> ministryIcons = {
  'groups': Icons.groups,
  'child_care': Icons.child_care,
  'school': Icons.school,
  'music_note': Icons.music_note,
  'volunteer_activism': Icons.volunteer_activism,
  'diversity_3': Icons.diversity_3,
  'favorite': Icons.favorite,
  'menu_book': Icons.menu_book,
  'coffee': Icons.coffee,
  'sports_basketball': Icons.sports_basketball,
  'church': Icons.church,
  'handshake': Icons.handshake,
  'campaign': Icons.campaign,
  'spa': Icons.spa,
};

IconData ministryIcon(String name) =>
    ministryIcons[name] ?? Icons.groups;

IconData socialIcon(String platform) {
  switch (platform.toLowerCase()) {
    case 'facebook':
      return Icons.facebook;
    case 'instagram':
      return Icons.camera_alt_outlined;
    case 'youtube':
      return Icons.smart_display_outlined;
    case 'x':
    case 'twitter':
      return Icons.alternate_email;
    case 'tiktok':
      return Icons.music_note_outlined;
    case 'spotify':
      return Icons.podcasts_outlined;
    default:
      return Icons.language;
  }
}

const List<String> socialPlatforms = [
  'facebook',
  'instagram',
  'youtube',
  'x',
  'tiktok',
  'spotify',
  'website',
];
