import 'package:flutter/material.dart';

import '../models/church_config.dart';
import '../utils/icon_utils.dart';
import '../utils/launch_helper.dart';
import 'church_logo.dart';
import 'responsive.dart';

class SiteFooter extends StatelessWidget {
  final ChurchConfig config;

  const SiteFooter({super.key, required this.config});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      width: double.infinity,
      color: scheme.surfaceContainerHigh,
      child: ContentContainer(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              runSpacing: 24,
              spacing: 24,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                ChurchLogo(config: config, size: 44),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final link in config.socialLinks)
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: IconButton.filledTonal(
                          onPressed: () => openUrl(context, link.url),
                          icon: Icon(socialIcon(link.platform)),
                          tooltip: link.platform,
                        ),
                      ),
                  ],
                ),
              ],
            ),
            if (config.address.isNotEmpty ||
                config.phone.isNotEmpty ||
                config.email.isNotEmpty) ...[
              const SizedBox(height: 24),
              Wrap(
                spacing: 24,
                runSpacing: 8,
                children: [
                  if (config.address.isNotEmpty)
                    _footerItem(theme, Icons.place_outlined, config.address),
                  if (config.phone.isNotEmpty)
                    _footerItem(theme, Icons.call_outlined, config.phone),
                  if (config.email.isNotEmpty)
                    _footerItem(theme, Icons.mail_outline, config.email),
                ],
              ),
            ],
            const SizedBox(height: 24),
            Divider(color: scheme.outlineVariant),
            const SizedBox(height: 16),
            Text(
              config.footerNote.isNotEmpty
                  ? config.footerNote
                  : '© ${DateTime.now().year} ${config.churchName}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Powered by Yoked',
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _footerItem(ThemeData theme, IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 8),
        Text(text, style: theme.textTheme.bodyMedium),
      ],
    );
  }
}
