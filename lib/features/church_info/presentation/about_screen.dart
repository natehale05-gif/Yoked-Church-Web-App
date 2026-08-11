import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/config/settings_providers.dart';
import '../../../core/widgets/async_value_widget.dart';
import '../../../core/widgets/app_shell.dart';
import '../../../core/widgets/section_container.dart';
import '../application/church_info_providers.dart';
import '../domain/church_info.dart';

class AboutScreen extends ConsumerWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return PageBody(
      children: [
        PageBanner(
          title: settings.aboutHeadline.isEmpty ? 'About Us' : settings.aboutHeadline,
          subtitle: settings.tagline,
        ),
        if (settings.aboutBody.isNotEmpty)
          SectionContainer(
            maxWidth: 760,
            child: Text(settings.aboutBody, style: const TextStyle(fontSize: 17, height: 1.7)),
          ),
        if (settings.beliefs.isNotEmpty)
          SectionContainer(
            backgroundColor: Colors.white,
            maxWidth: 760,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('What We Believe', style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 16),
                Text(settings.beliefs, style: const TextStyle(fontSize: 16, height: 1.7)),
              ],
            ),
          ),
        SectionContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Our Team', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 24),
              AsyncListWidget<StaffMember>(
                value: ref.watch(staffProvider),
                errorContext: 'the staff directory',
                emptyMessage: 'Staff bios are coming soon.',
                data: (staff) => Wrap(
                  spacing: 24,
                  runSpacing: 24,
                  children: [for (final member in staff) _StaffCard(member: member)],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StaffCard extends ConsumerWidget {
  final StaffMember member;

  const _StaffCard({required this.member});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brand = ref.watch(settingsProvider).colors;

    return SizedBox(
      width: 320,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: brand.primary.withValues(alpha: 0.1),
                    backgroundImage: member.photoUrl.isEmpty ? null : NetworkImage(member.photoUrl),
                    child: member.photoUrl.isNotEmpty
                        ? null
                        : Text(
                            member.name.isEmpty ? '?' : member.name[0].toUpperCase(),
                            style: TextStyle(color: brand.primary, fontWeight: FontWeight.w700, fontSize: 20),
                          ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(member.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                        Text(member.role, style: TextStyle(color: brand.accentInk, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ],
              ),
              if (member.bio.isNotEmpty) ...[
                const SizedBox(height: 14),
                Text(member.bio, style: const TextStyle(color: Colors.black87, height: 1.5)),
              ],
              if (member.email.isNotEmpty) ...[
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: () => launchUrl(Uri.parse('mailto:${member.email}')),
                  icon: const Icon(Icons.mail_outline, size: 16),
                  label: Text(member.email),
                  style: TextButton.styleFrom(padding: EdgeInsets.zero),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
