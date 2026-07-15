import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../state/site_content_controller.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/responsive.dart';
import '../utils/launch.dart';
import 'content_width.dart';
import 'nav_items.dart';

class SiteFooter extends StatelessWidget {
  const SiteFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final content = context.watch<SiteContentController>().content;
    return Container(
      width: double.infinity,
      color: AppColors.navyDeep,
      padding: EdgeInsets.symmetric(
        vertical: context.responsive(mobile: 48, desktop: 72),
      ),
      child: ContentWidth(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Flex(
              direction: context.isMobile ? Axis.vertical : Axis.horizontal,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: context.isMobile ? 0 : 5, child: const _Brand()),
                if (context.isMobile) const SizedBox(height: 40),
                Expanded(
                  flex: context.isMobile ? 0 : 3,
                  child: const _LinksColumn(),
                ),
                if (context.isMobile) const SizedBox(height: 40),
                Expanded(
                  flex: context.isMobile ? 0 : 4,
                  child: const _VisitColumn(),
                ),
              ],
            ),
            const SizedBox(height: 48),
            Divider(color: AppColors.onDark.withValues(alpha: 0.14)),
            const SizedBox(height: 24),
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              runSpacing: 12,
              children: [
                Text(
                  '© ${DateTime.now().year} ${content.churchName}. All rights reserved.',
                  style: GoogleFonts.inter(
                    color: AppColors.onDarkSoft,
                    fontSize: 13,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _SocialIcon(
                      icon: Icons.camera_alt_outlined,
                      url: content.instagramUrl,
                      tooltip: 'Instagram',
                    ),
                    _SocialIcon(
                      icon: Icons.facebook_outlined,
                      url: content.facebookUrl,
                      tooltip: 'Facebook',
                    ),
                    _SocialIcon(
                      icon: Icons.play_circle_outline,
                      url: content.youtubeUrl,
                      tooltip: 'YouTube',
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Brand extends StatelessWidget {
  const _Brand();

  @override
  Widget build(BuildContext context) {
    final content = context.watch<SiteContentController>().content;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          content.churchName,
          style: GoogleFonts.cormorantGaramond(
            fontSize: 30,
            fontWeight: FontWeight.w700,
            color: AppColors.onDark,
          ),
        ),
        const SizedBox(height: 16),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Text(
            content.tagline,
            style: GoogleFonts.inter(
              color: AppColors.onDarkSoft,
              fontSize: 16,
              height: 1.6,
            ),
          ),
        ),
      ],
    );
  }
}

class _LinksColumn extends StatelessWidget {
  const _LinksColumn();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('EXPLORE', style: AppTheme.eyebrow(color: AppColors.goldSoft)),
        const SizedBox(height: 20),
        for (final item in kNavItems) _FooterLink(item.label, item.path),
        _FooterLink('Give', '/give'),
        _FooterLink('Contact', '/contact'),
      ],
    );
  }
}

class _VisitColumn extends StatelessWidget {
  const _VisitColumn();

  @override
  Widget build(BuildContext context) {
    final content = context.watch<SiteContentController>().content;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('VISIT US', style: AppTheme.eyebrow(color: AppColors.goldSoft)),
        const SizedBox(height: 20),
        _ContactRow(
          icon: Icons.place_outlined,
          text: '${content.addressLine1}\n${content.addressLine2}',
          onTap: () => openUrl(content.mapUrl),
        ),
        _ContactRow(
          icon: Icons.mail_outline,
          text: content.email,
          onTap: () => openEmail(content.email),
        ),
        _ContactRow(
          icon: Icons.call_outlined,
          text: content.phone,
          onTap: () => openPhone(content.phone),
        ),
      ],
    );
  }
}

class _ContactRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback onTap;
  const _ContactRow({
    required this.icon,
    required this.text,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.goldSoft, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: GoogleFonts.inter(
                  color: AppColors.onDarkSoft,
                  fontSize: 15,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FooterLink extends StatelessWidget {
  final String label;
  final String path;
  const _FooterLink(this.label, this.path);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: InkWell(
        onTap: () => context.go(path),
        child: Text(
          label,
          style: GoogleFonts.inter(
            color: AppColors.onDarkSoft,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}

class _SocialIcon extends StatelessWidget {
  final IconData icon;
  final String url;
  final String tooltip;
  const _SocialIcon({
    required this.icon,
    required this.url,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) return const SizedBox.shrink();
    return IconButton(
      onPressed: () => openUrl(url),
      tooltip: tooltip,
      icon: Icon(icon, color: AppColors.onDarkSoft),
      hoverColor: AppColors.onDark.withValues(alpha: 0.08),
    );
  }
}
