import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/ministry.dart';
import '../state/site_controller.dart';
import '../utils/icon_utils.dart';
import '../utils/launch_helper.dart';
import '../widgets/responsive.dart';
import '../widgets/section_header.dart';
import '../widgets/site_footer.dart';

class MinistriesScreen extends StatelessWidget {
  const MinistriesScreen({super.key});

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
                  eyebrow: 'Get Involved',
                  title: 'Find your place',
                  subtitle:
                      'From kids to community, there is a place for everyone '
                      'to belong and serve.',
                ),
                const SizedBox(height: 28),
                GridView.count(
                  crossAxisCount: Responsive.gridColumns(context),
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: Responsive.isMobile(context) ? 1.9 : 1.1,
                  children: [
                    for (final ministry in site.ministries)
                      _MinistryCard(ministry: ministry),
                  ],
                ),
              ],
            ),
          ),
          SiteFooter(config: config),
        ],
      ),
    );
  }
}

class _MinistryCard extends StatelessWidget {
  final Ministry ministry;

  const _MinistryCard({required this.ministry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: InkWell(
        onTap: ministry.contactUrl.trim().isNotEmpty
            ? () => openUrl(context, ministry.contactUrl)
            : null,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(ministryIcon(ministry.icon),
                    color: theme.colorScheme.onPrimaryContainer, size: 26),
              ),
              const SizedBox(height: 16),
              Text(ministry.name,
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w700)),
              if (ministry.leader.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text('Led by ${ministry.leader}',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.primary)),
              ],
              if (ministry.description.isNotEmpty) ...[
                const SizedBox(height: 10),
                Expanded(
                  child: Text(ministry.description,
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          height: 1.5)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
