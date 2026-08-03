import 'package:flutter/foundation.dart';

/// One church as it appears in the picker, before you belong to it.
///
/// Deliberately thin. The picker may list every church on the platform,
/// and a member choosing one should not cause a full settings document
/// per row to be read - these are the only fields a person needs to
/// recognise their own church.
@immutable
class ChurchSummary {
  final String id;
  final String name;

  /// Where it meets, in the form a person would say it: "Hometown, ST".
  /// The single most useful disambiguator when three churches share a
  /// name, which they do.
  final String city;

  final String tagline;
  final String logoUrl;

  const ChurchSummary({
    required this.id,
    required this.name,
    this.city = '',
    this.tagline = '',
    this.logoUrl = '',
  });

  /// Reads a church document, which is also its settings document. Only
  /// the directory fields are picked out; the rest is ignored here.
  factory ChurchSummary.fromMap(String id, Map<String, dynamic> map) {
    final contact = map['contact'];
    return ChurchSummary(
      id: id,
      name: map['churchName'] as String? ?? 'Unnamed church',
      // Falls back to the postal address so a church that has filled in
      // nothing but its contact details still shows something useful.
      city: map['city'] as String? ??
          (contact is Map ? _cityFrom(contact['address'] as String? ?? '') : ''),
      tagline: map['tagline'] as String? ?? '',
      logoUrl: map['logoUrl'] as String? ?? '',
    );
  }

  /// "123 Faith Ave, Hometown, ST 00000" -> "Hometown, ST".
  ///
  /// Best-effort on purpose: an address that does not fit the pattern
  /// yields an empty string rather than a mangled one, and the picker
  /// simply shows the church without a location.
  static String _cityFrom(String address) {
    final parts = address.split(',').map((p) => p.trim()).where((p) => p.isNotEmpty).toList();
    if (parts.length < 2) return '';
    final town = parts[parts.length - 2];
    final region = parts.last.split(' ').first;
    return region.isEmpty ? town : '$town, $region';
  }

  /// Everything a person might type when looking for their church.
  bool matches(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return name.toLowerCase().contains(q) ||
        city.toLowerCase().contains(q) ||
        tagline.toLowerCase().contains(q);
  }
}
