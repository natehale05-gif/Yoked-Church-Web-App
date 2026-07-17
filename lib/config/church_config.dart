import 'package:flutter/material.dart';

/// Central, single-source-of-truth configuration for this church's
/// instance of the app. This is the file a customer customizes when
/// this template is resold to a different church: name, branding,
/// service times, links, and which features are enabled.
class ChurchConfig {
  const ChurchConfig._();

  // --- Identity -------------------------------------------------------
  static const String churchName = 'Yoked Church';
  static const String tagline = 'Take my yoke upon you, and learn from me.';
  static const String logoAssetPath = 'assets/images/logo.png';

  // --- Brand colors -----------------------------------------------------
  static const Color primaryColor = Color(0xFF1B3A4B);
  static const Color accentColor = Color(0xFFC9A24B);
  static const Color backgroundColor = Color(0xFFF7F5F0);

  // --- Contact / location -------------------------------------------------
  static const String address = '123 Faith Ave, Hometown, ST 00000';
  static const String phone = '(555) 123-4567';
  static const String email = 'info@yokedchurch.org';
  static const String mapUrl = 'https://maps.google.com/?q=123+Faith+Ave';

  // --- Service times ----------------------------------------------------
  static const List<ServiceTime> serviceTimes = [
    ServiceTime(day: 'Sunday', time: '9:00 AM', label: 'Traditional Service'),
    ServiceTime(day: 'Sunday', time: '11:00 AM', label: 'Contemporary Service'),
    ServiceTime(day: 'Wednesday', time: '6:30 PM', label: 'Midweek Bible Study'),
  ];

  // --- Social / external links ------------------------------------------
  static const String liveStreamUrl = 'https://www.youtube.com/embed/live_stream?channel=UCxxxxxxx';
  static const String youtubeUrl = 'https://youtube.com/@yokedchurch';
  static const String facebookUrl = 'https://facebook.com/yokedchurch';
  static const String instagramUrl = 'https://instagram.com/yokedchurch';
  static const String givingUrl = 'https://tithe.ly/give?c=yokedchurch';

  // --- Feature flags ------------------------------------------------------
  // Toggle sections on/off per customer without touching screen code.
  static const bool showSermons = true;
  static const bool showEvents = true;
  static const bool showGiving = true;
  static const bool showConnect = true;

  // --- Data source ---------------------------------------------------------
  // When false, the app runs entirely on bundled mock/sample content
  // (assets/data/*.json) with no backend required. Flip to true once
  // Firebase is configured (see lib/firebase_options.dart) to pull
  // live sermons/events/prayer requests from Firestore.
  static const bool useFirebase = false;
}

class ServiceTime {
  final String day;
  final String time;
  final String label;

  const ServiceTime({required this.day, required this.time, required this.label});
}
