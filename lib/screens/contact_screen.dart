import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/church_config.dart';
import '../state/site_controller.dart';
import '../utils/icon_utils.dart';
import '../utils/launch_helper.dart';
import '../widgets/responsive.dart';
import '../widgets/section_header.dart';
import '../widgets/site_footer.dart';

class ContactScreen extends StatelessWidget {
  const ContactScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final site = context.watch<SiteController>();
    final config = site.config;

    return SingleChildScrollView(
      child: Column(
        children: [
          ContentContainer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeader(
                  eyebrow: 'Contact',
                  title: 'Get in touch',
                  subtitle:
                      "We'd love to hear from you. Reach out any time — or just "
                      'come say hi this weekend.',
                ),
                const SizedBox(height: 28),
                _ContactActions(config: config),
                if (config.serviceTimes.isNotEmpty) ...[
                  const SizedBox(height: 40),
                  Text('Service times',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 16),
                  for (final s in config.serviceTimes)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.schedule),
                      title: Text('${s.name} — ${s.day} ${s.time}'),
                      subtitle:
                          s.location.isNotEmpty ? Text(s.location) : null,
                    ),
                ],
              ],
            ),
          ),
          SiteFooter(config: config),
        ],
      ),
    );
  }
}

class _ContactActions extends StatelessWidget {
  final ChurchConfig config;

  const _ContactActions({required this.config});

  @override
  Widget build(BuildContext context) {
    final items = <Widget>[
      if (config.address.isNotEmpty)
        _ContactCard(
          icon: Icons.place_outlined,
          title: 'Visit us',
          value: config.address,
          onTap: config.mapUrl.isNotEmpty
              ? () => openUrl(context, config.mapUrl)
              : null,
        ),
      if (config.phone.isNotEmpty)
        _ContactCard(
          icon: Icons.call_outlined,
          title: 'Call us',
          value: config.phone,
          onTap: () => openUrl(context, 'tel:${config.phone}'),
        ),
      if (config.email.isNotEmpty)
        _ContactCard(
          icon: Icons.mail_outline,
          title: 'Email us',
          value: config.email,
          onTap: () => openUrl(context, 'mailto:${config.email}'),
        ),
    ];

    return Column(
      children: [
        GridView.count(
          crossAxisCount: Responsive.gridColumns(context),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: Responsive.isMobile(context) ? 3 : 1.5,
          children: items,
        ),
        if (config.socialLinks.isNotEmpty) ...[
          const SizedBox(height: 24),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final link in config.socialLinks)
                OutlinedButton.icon(
                  onPressed: () => openUrl(context, link.url),
                  icon: Icon(socialIcon(link.platform)),
                  label: Text(link.platform[0].toUpperCase() +
                      link.platform.substring(1)),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _ContactCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final VoidCallback? onTap;

  const _ContactCard({
    required this.icon,
    required this.title,
    required this.value,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Icon(icon, color: theme.colorScheme.primary, size: 28),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(title,
                        style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant)),
                    const SizedBox(height: 2),
                    Text(value,
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
