import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/config/settings_providers.dart';
import '../../../core/widgets/async_value_widget.dart';
import '../../../core/widgets/app_shell.dart';
import '../../../core/widgets/section_container.dart';
import '../../../core/widgets/service_times.dart';
import '../application/church_info_providers.dart';
import '../domain/church_info.dart';

/// First-time visitor page: what to expect, when to come, where to go.
class VisitScreen extends ConsumerWidget {
  const VisitScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return PageBody(
      children: [
        PageBanner(
          eyebrow: 'First time?',
          title: 'Plan a Visit',
          subtitle: "We'd love to meet you. Here's what to expect.",
          action: settings.features.connect
              ? ElevatedButton(onPressed: () => context.go('/connect'), child: const Text("Let us know you're coming"))
              : null,
        ),
        if (settings.visitInfo.isNotEmpty)
          SectionContainer(
            maxWidth: 760,
            child: Text(settings.visitInfo, style: const TextStyle(fontSize: 17, height: 1.7)),
          ),
        SectionContainer(
          backgroundColor: Colors.white,
          child: ServiceTimes(settings: settings, heading: 'Service Times'),
        ),
        SectionContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Where to Find Us', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 24),
              AsyncListWidget<ChurchLocation>(
                value: ref.watch(locationsProvider),
                errorContext: 'our locations',
                emptyMessage: 'Location details are coming soon.',
                data: (locations) => Wrap(
                  spacing: 24,
                  runSpacing: 24,
                  children: [for (final location in locations) _LocationCard(location: location)],
                ),
              ),
            ],
          ),
        ),
        const _FaqSection(),
      ],
    );
  }
}

class _LocationCard extends ConsumerWidget {
  final ChurchLocation location;

  const _LocationCard({required this.location});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brand = ref.watch(settingsProvider).colors;

    return SizedBox(
      width: 340,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.location_on_outlined, color: brand.accent),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(location.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(location.address, style: const TextStyle(color: Colors.black54)),
              if (location.serviceTimes.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(location.serviceTimes.join(' · '), style: const TextStyle(color: Colors.black87)),
              ],
              if (location.description.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(location.description, style: const TextStyle(color: Colors.black87, height: 1.5)),
              ],
              if (location.mapUrl.isNotEmpty) ...[
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => launchUrl(Uri.parse(location.mapUrl), webOnlyWindowName: '_blank'),
                  icon: const Icon(Icons.map_outlined, size: 16),
                  label: const Text('Directions'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _FaqSection extends ConsumerWidget {
  const _FaqSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final faqsAsync = ref.watch(faqsProvider);

    // A church with no FAQs entered shouldn't render an empty heading.
    if (faqsAsync.valueOrNull?.isEmpty ?? false) return const SizedBox.shrink();

    return SectionContainer(
      backgroundColor: Colors.white,
      maxWidth: 820,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Common Questions', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 16),
          AsyncListWidget<Faq>(
            value: faqsAsync,
            errorContext: 'our FAQ',
            emptyMessage: 'No questions posted yet.',
            data: (faqs) => Column(
              children: [
                for (final faq in faqs)
                  ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    title: Text(faq.question, style: const TextStyle(fontWeight: FontWeight.w600)),
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Text(faq.answer, style: const TextStyle(color: Colors.black87, height: 1.6)),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
