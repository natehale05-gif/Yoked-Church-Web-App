import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

/// Opens an external URL (maps, giving, social, email, phone). Fails silently
/// if the link cannot be opened so the UI never crashes on a bad link.
Future<void> openUrl(String url) async {
  if (url.trim().isEmpty) return;
  final uri = Uri.tryParse(url);
  if (uri == null) return;
  try {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (e) {
    if (kDebugMode) {
      debugPrint('Could not launch $url: $e');
    }
  }
}

Future<void> openEmail(String email) => openUrl('mailto:$email');

Future<void> openPhone(String phone) {
  final digits = phone.replaceAll(RegExp(r'[^0-9+]'), '');
  return openUrl('tel:$digits');
}
