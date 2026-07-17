import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/church_config.dart';
import '../theme/app_theme.dart';

class AppFooter extends StatelessWidget {
  const AppFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = Breakpoints.isMobile(context);

    return Container(
      width: double.infinity,
      color: ChurchConfig.primaryColor,
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 20 : 60, vertical: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            ChurchConfig.churchName,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            ChurchConfig.address,
            style: const TextStyle(color: Colors.white70),
          ),
          Text(
            '${ChurchConfig.phone} · ${ChurchConfig.email}',
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 20,
            children: [
              _SocialLink(icon: Icons.facebook, url: ChurchConfig.facebookUrl),
              _SocialLink(icon: Icons.camera_alt_outlined, url: ChurchConfig.instagramUrl),
              _SocialLink(icon: Icons.play_circle_outline, url: ChurchConfig.youtubeUrl),
            ],
          ),
          const SizedBox(height: 24),
          Divider(color: Colors.white24),
          const SizedBox(height: 12),
          Text(
            '© ${DateTime.now().year} ${ChurchConfig.churchName}. All rights reserved.',
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _SocialLink extends StatelessWidget {
  final IconData icon;
  final String url;

  const _SocialLink({required this.icon, required this.url});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, color: Colors.white),
      onPressed: () => launchUrl(Uri.parse(url), webOnlyWindowName: '_blank'),
    );
  }
}
