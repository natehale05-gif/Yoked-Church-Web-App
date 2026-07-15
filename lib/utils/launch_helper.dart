import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> openUrl(BuildContext context, String url) async {
  final trimmed = url.trim();
  if (trimmed.isEmpty) return;
  final uri = Uri.tryParse(trimmed);
  if (uri == null) return;
  final messenger = ScaffoldMessenger.maybeOf(context);
  try {
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && messenger != null) {
      messenger.showSnackBar(
        SnackBar(content: Text('Could not open $trimmed')),
      );
    }
  } catch (_) {
    messenger?.showSnackBar(
      SnackBar(content: Text('Could not open $trimmed')),
    );
  }
}
