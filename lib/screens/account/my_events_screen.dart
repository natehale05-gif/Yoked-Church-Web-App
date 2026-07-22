import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/church_event.dart';
import '../../providers/auth_provider.dart';
import '../../services/event_service.dart';
import '../../services/rsvp_service.dart';
import '../../widgets/account_header.dart';
import '../../widgets/section_container.dart';

class MyEventsScreen extends StatefulWidget {
  const MyEventsScreen({super.key});

  @override
  State<MyEventsScreen> createState() => _MyEventsScreenState();
}

class _MyEventsScreenState extends State<MyEventsScreen> {
  final EventService _eventService = const EventService();
  final RsvpService _rsvpService = RsvpService();
  late Future<List<ChurchEvent>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<ChurchEvent>> _load() async {
    final uid = context.read<AuthProvider>().currentUser?.uid ?? '';
    final allEvents = await _eventService.fetchUpcomingEvents();
    final myRsvps = uid.isEmpty ? [] : await _rsvpService.fetchMyRsvps(uid);
    final rsvpEventIds = myRsvps.map((r) => r.eventId).toSet();
    return allEvents.where((e) => rsvpEventIds.contains(e.id)).toList();
  }

  Future<void> _cancel(ChurchEvent event) async {
    final uid = context.read<AuthProvider>().currentUser?.uid;
    if (uid == null) return;
    await _rsvpService.cancelRsvp(eventId: event.id, uid: uid);
    setState(() => _future = _load());
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const AccountHeader(title: 'My Events', subtitle: "Events you've RSVP'd to."),
        SectionContainer(
          maxWidth: 700,
          child: FutureBuilder<List<ChurchEvent>>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 60),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final events = snapshot.data ?? [];
              if (events.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 60),
                  child: Center(child: Text("You haven't RSVP'd to any upcoming events yet.")),
                );
              }
              return Column(
                children: events.map((event) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      title: Text(event.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: Text('${DateFormat.yMMMd().add_jm().format(event.start)} · ${event.location}'),
                      trailing: TextButton(onPressed: () => _cancel(event), child: const Text('Cancel RSVP')),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ),
      ],
    );
  }
}
