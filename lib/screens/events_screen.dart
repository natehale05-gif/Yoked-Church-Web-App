import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/church_event.dart';
import '../state/site_controller.dart';
import '../utils/launch_helper.dart';
import '../widgets/responsive.dart';
import '../widgets/section_header.dart';
import '../widgets/site_footer.dart';

class EventsScreen extends StatelessWidget {
  const EventsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final site = context.watch<SiteController>();
    final config = site.config;
    final events = site.upcomingEvents;

    return SingleChildScrollView(
      child: Column(
        children: [
          ContentContainer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeader(
                  eyebrow: 'Events',
                  title: "What's coming up",
                  subtitle:
                      'There is always something happening. Come be part of it.',
                ),
                const SizedBox(height: 28),
                if (events.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.event_busy,
                              size: 48,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant),
                          const SizedBox(height: 12),
                          Text('No upcoming events right now',
                              style: Theme.of(context).textTheme.titleMedium),
                        ],
                      ),
                    ),
                  )
                else
                  for (final event in events)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _EventCard(event: event),
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

class _EventCard extends StatelessWidget {
  final ChurchEvent event;

  const _EventCard({required this.event});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMobile = Responsive.isMobile(context);
    final accent = theme.colorScheme.secondary;

    final dateBadge = Container(
      width: 84,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(DateFormat('MMM').format(event.start).toUpperCase(),
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSecondaryContainer,
                fontWeight: FontWeight.w700,
              )),
          Text(DateFormat('d').format(event.start),
              style: theme.textTheme.headlineMedium?.copyWith(
                color: theme.colorScheme.onSecondaryContainer,
                fontWeight: FontWeight.w800,
              )),
          Text(DateFormat('EEE').format(event.start),
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSecondaryContainer,
              )),
        ],
      ),
    );

    final details = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: accent.withOpacity(0.15),
                borderRadius: BorderRadius.circular(100),
              ),
              child: Text(event.category,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: accent,
                    fontWeight: FontWeight.w700,
                  )),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(event.title,
            style: theme.textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        _meta(theme, Icons.schedule, _timeText(event)),
        if (event.location.isNotEmpty)
          _meta(theme, Icons.place_outlined, event.location),
        if (event.description.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(event.description,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant,
                      height: 1.5)),
        ],
        if (event.registrationUrl.trim().isNotEmpty) ...[
          const SizedBox(height: 16),
          FilledButton.tonal(
            onPressed: () => openUrl(context, event.registrationUrl),
            child: const Text('Register / RSVP'),
          ),
        ],
      ],
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: isMobile
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [dateBadge],
                  ),
                  const SizedBox(height: 16),
                  details,
                ],
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  dateBadge,
                  const SizedBox(width: 20),
                  Expanded(child: details),
                ],
              ),
      ),
    );
  }

  Widget _meta(ThemeData theme, IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Flexible(
            child: Text(text,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ),
        ],
      ),
    );
  }

  String _timeText(ChurchEvent e) {
    final start = DateFormat('EEEE, MMM d · h:mm a').format(e.start);
    if (e.end != null) {
      return '$start – ${DateFormat('h:mm a').format(e.end!)}';
    }
    return start;
  }
}
