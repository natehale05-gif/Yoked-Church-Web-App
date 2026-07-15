import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/church_config.dart';
import '../models/staff_member.dart';
import '../state/site_controller.dart';
import '../widgets/responsive.dart';
import '../widgets/section_header.dart';
import '../widgets/site_footer.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final site = context.watch<SiteController>();
    final config = site.config;
    final theme = Theme.of(context);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ContentContainer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionHeader(
                  eyebrow: 'About Us',
                  title: config.aboutTitle.isNotEmpty
                      ? config.aboutTitle
                      : 'About ${config.churchName}',
                ),
                if (config.missionStatement.isNotEmpty) ...[
                  const SizedBox(height: 28),
                  Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(config.cornerRadius),
                    ),
                    child: Text(
                      '“${config.missionStatement}”',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
                if (config.aboutBody.isNotEmpty) ...[
                  const SizedBox(height: 28),
                  Text(
                    config.aboutBody,
                    style: theme.textTheme.bodyLarge?.copyWith(height: 1.7),
                  ),
                ],
                if (config.beliefs.isNotEmpty) ...[
                  const SizedBox(height: 40),
                  Text('What we believe',
                      style: theme.textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 16),
                  for (final belief in config.beliefs)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.check_circle,
                              color: theme.colorScheme.secondary, size: 22),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(belief,
                                style: theme.textTheme.bodyLarge
                                    ?.copyWith(height: 1.5)),
                          ),
                        ],
                      ),
                    ),
                ],
              ],
            ),
          ),
          if (site.staff.isNotEmpty) _StaffSection(config: config, site: site),
          SiteFooter(config: config),
        ],
      ),
    );
  }
}

class _StaffSection extends StatelessWidget {
  final ChurchConfig config;
  final SiteController site;

  const _StaffSection({required this.config, required this.site});

  @override
  Widget build(BuildContext context) {
    final columns = Responsive.gridColumns(context);
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      child: ContentContainer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(eyebrow: 'Our Team', title: 'Meet the staff'),
            const SizedBox(height: 28),
            GridView.count(
              crossAxisCount: columns,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: Responsive.isMobile(context) ? 2.4 : 0.95,
              children: [
                for (final member in site.staff)
                  _StaffCard(member: member),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StaffCard extends StatelessWidget {
  final StaffMember member;

  const _StaffCard({required this.member});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMobile = Responsive.isMobile(context);
    final avatar = CircleAvatar(
      radius: isMobile ? 32 : 44,
      backgroundColor: theme.colorScheme.primaryContainer,
      backgroundImage: member.photoUrl.trim().isNotEmpty
          ? NetworkImage(member.photoUrl.trim())
          : null,
      child: member.photoUrl.trim().isEmpty
          ? Text(
              _initials(member.name),
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w700,
              ),
            )
          : null,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: isMobile
            ? Row(
                children: [
                  avatar,
                  const SizedBox(width: 16),
                  Expanded(child: _text(theme)),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  avatar,
                  const SizedBox(height: 16),
                  _text(theme, center: true),
                ],
              ),
      ),
    );
  }

  Widget _text(ThemeData theme, {bool center = false}) {
    return Column(
      crossAxisAlignment:
          center ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        Text(member.name,
            textAlign: center ? TextAlign.center : TextAlign.start,
            style:
                theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 2),
        Text(member.role,
            textAlign: center ? TextAlign.center : TextAlign.start,
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.primary)),
        if (member.bio.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(member.bio,
              textAlign: center ? TextAlign.center : TextAlign.start,
              maxLines: center ? 4 : 3,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant, height: 1.4)),
        ],
      ],
    );
  }

  static String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts[1].substring(0, 1))
        .toUpperCase();
  }
}
