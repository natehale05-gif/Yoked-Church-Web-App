import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/config/church_settings.dart';
import '../../../core/config/settings_providers.dart';
import '../../../core/widgets/async_value_widget.dart';
import '../../../core/widgets/app_shell.dart';
import '../../../core/widgets/section_container.dart';
import '../application/event_providers.dart';
import '../domain/church_event.dart';

class EventsScreen extends ConsumerWidget {
  const EventsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PageBody(
      children: [
        const PageBanner(
          title: 'Events',
          subtitle: "Find out what's happening around the church.",
        ),
        SectionContainer(
          maxWidth: 820,
          child: AsyncListWidget<ChurchEvent>(
            value: ref.watch(upcomingEventsProvider),
            errorContext: 'events',
            emptyMessage: 'No upcoming events - check back soon.',
            data: (events) => Column(
              children: [for (final event in events) EventTile(event: event)],
            ),
          ),
        ),
      ],
    );
  }
}

/// A single event row. [trailing] lets signed-in contexts inject an RSVP
/// control without this widget needing to know anything about auth.
class EventTile extends ConsumerWidget {
  final ChurchEvent event;
  final Widget? trailing;

  const EventTile({super.key, required this.event, this.trailing});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brand = ref.watch(settingsProvider).colors;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DateChip(date: event.start, brand: brand),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(event.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
                  const SizedBox(height: 4),
                  Text(
                    [
                      DateFormat.jm().format(event.start),
                      if (event.location.isNotEmpty) event.location,
                    ].join(' · '),
                    style: const TextStyle(color: Colors.black54),
                  ),
                  if (event.description.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(event.description, style: const TextStyle(color: Colors.black87)),
                  ],
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () =>
                            launchUrl(Uri.parse(event.googleCalendarUrl), webOnlyWindowName: '_blank'),
                        icon: const Icon(Icons.calendar_today, size: 16),
                        label: const Text('Add to Calendar'),
                      ),
                      ?trailing,
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DateChip extends StatelessWidget {
  final DateTime date;
  final BrandColors brand;

  const _DateChip({required this.date, required this.brand});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: brand.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            DateFormat.MMM().format(date).toUpperCase(),
            style: TextStyle(color: brand.accent, fontWeight: FontWeight.w700, fontSize: 12),
          ),
          Text(
            DateFormat.d().format(date),
            style: TextStyle(color: brand.primary, fontWeight: FontWeight.w700, fontSize: 22),
          ),
        ],
      ),
    );
  }
}
