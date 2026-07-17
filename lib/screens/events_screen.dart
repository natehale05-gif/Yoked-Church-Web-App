import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/church_config.dart';
import '../models/church_event.dart';
import '../services/event_service.dart';
import '../theme/app_theme.dart';
import '../widgets/section_container.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  final EventService _service = const EventService();
  late final Future<List<ChurchEvent>> _eventsFuture;

  @override
  void initState() {
    super.initState();
    _eventsFuture = _service.fetchUpcomingEvents();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Breakpoints.isMobile(context);

    return Column(
      children: [
        Container(
          width: double.infinity,
          color: ChurchConfig.primaryColor,
          padding: EdgeInsets.symmetric(horizontal: isMobile ? 24 : 60, vertical: isMobile ? 48 : 72),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Events', style: Theme.of(context).textTheme.displayMedium?.copyWith(color: Colors.white)),
              const SizedBox(height: 12),
              const Text('Find out what\'s happening around the church.',
                  style: TextStyle(color: Colors.white70, fontSize: 16)),
            ],
          ),
        ),
        SectionContainer(
          maxWidth: 800,
          child: FutureBuilder<List<ChurchEvent>>(
            future: _eventsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 60),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (snapshot.hasError) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 60),
                  child: Center(child: Text('Could not load events: ${snapshot.error}')),
                );
              }
              final events = snapshot.data ?? [];
              if (events.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 60),
                  child: Center(child: Text('No upcoming events - check back soon.')),
                );
              }
              return Column(
                children: events.map((event) => _EventTile(event: event)).toList(),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _EventTile extends StatelessWidget {
  final ChurchEvent event;

  const _EventTile({required this.event});

  String get _googleCalendarUrl {
    final formatter = DateFormat("yyyyMMdd'T'HHmmss");
    final start = formatter.format(event.start);
    final end = formatter.format(event.end ?? event.start.add(const Duration(hours: 1)));
    final params = {
      'action': 'TEMPLATE',
      'text': event.title,
      'dates': '$start/$end',
      'details': event.description,
      'location': event.location,
    };
    final query = params.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&');
    return 'https://calendar.google.com/calendar/render?$query';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 64,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: ChurchConfig.primaryColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Text(DateFormat.MMM().format(event.start).toUpperCase(),
                      style: TextStyle(color: ChurchConfig.accentColor, fontWeight: FontWeight.w700, fontSize: 12)),
                  Text(DateFormat.d().format(event.start),
                      style: TextStyle(color: ChurchConfig.primaryColor, fontWeight: FontWeight.w700, fontSize: 22)),
                ],
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(event.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
                  const SizedBox(height: 4),
                  Text(
                    '${DateFormat.jm().format(event.start)} · ${event.location}',
                    style: const TextStyle(color: Colors.black54),
                  ),
                  const SizedBox(height: 8),
                  Text(event.description, style: const TextStyle(color: Colors.black87)),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: OutlinedButton.icon(
                      onPressed: () => launchUrl(Uri.parse(_googleCalendarUrl), webOnlyWindowName: '_blank'),
                      icon: const Icon(Icons.calendar_today, size: 16),
                      label: const Text('Add to Calendar'),
                    ),
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
