import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/app_shell.dart';
import '../../../core/widgets/async_value_widget.dart';
import '../../../core/widgets/section_container.dart';
import '../../events/application/event_providers.dart';
import '../../events/application/rsvp_providers.dart';
import '../../events/domain/church_event.dart';
import '../../events/presentation/events_screen.dart';
import 'account_header.dart';

class MyEventsScreen extends ConsumerWidget {
  const MyEventsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rsvpIds = ref.watch(myRsvpEventIdsProvider);

    return PageBody(
      children: [
        const AccountHeader(title: 'My Events', subtitle: "Events you've said you're coming to."),
        SectionContainer(
          maxWidth: 820,
          child: AsyncValueWidget<List<ChurchEvent>>(
            value: ref.watch(myUpcomingEventsProvider),
            errorContext: 'your events',
            data: (mine) => mine.isEmpty
                ? Column(
                    children: [
                      const EmptyState(message: "You haven't RSVP'd to any upcoming events yet."),
                      OutlinedButton(
                        onPressed: () => context.go('/events'),
                        child: const Text('Browse events'),
                      ),
                    ],
                  )
                : Column(
                    children: [
                      for (final event in mine)
                        EventTile(
                          event: event,
                          trailing: OutlinedButton.icon(
                            onPressed: () => ref.read(rsvpControllerProvider).toggle(event.id),
                            icon: Icon(
                              rsvpIds.contains(event.id) ? Icons.check_circle : Icons.check_circle_outline,
                              size: 16,
                            ),
                            label: const Text('Cancel RSVP'),
                          ),
                        ),
                    ],
                  ),
          ),
        ),
        SectionContainer(
          backgroundColor: Colors.white,
          maxWidth: 820,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('All upcoming events', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              AsyncListWidget<ChurchEvent>(
                value: ref.watch(upcomingEventsProvider),
                errorContext: 'events',
                emptyMessage: 'No upcoming events - check back soon.',
                data: (events) => Column(
                  children: [
                    for (final event in events.where((e) => !rsvpIds.contains(e.id) && e.rsvpEnabled))
                      EventTile(
                        event: event,
                        trailing: ElevatedButton(
                          onPressed: () => ref.read(rsvpControllerProvider).toggle(event.id),
                          child: const Text('RSVP'),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
