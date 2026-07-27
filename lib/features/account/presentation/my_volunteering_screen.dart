import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/widgets/app_shell.dart';
import '../../../core/widgets/async_value_widget.dart';
import '../../../core/widgets/section_container.dart';
import '../../volunteering/application/volunteering_providers.dart';
import '../../volunteering/domain/volunteering.dart';
import 'account_header.dart';

class MyVolunteeringScreen extends ConsumerWidget {
  const MyVolunteeringScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final positions = ref.watch(volunteerPositionsProvider).valueOrNull ?? const [];
    final byId = {for (final p in positions) p.id: p};
    final mine = ref.watch(myAssignmentsProvider).valueOrNull ?? const [];
    final myPositionIds = mine.map((a) => a.positionId).toSet();
    final openSlots = ref.watch(openSlotsProvider).valueOrNull ?? const <String, int>{};

    final available = positions.where(
      (p) => !myPositionIds.contains(p.id) && (openSlots[p.id] ?? p.slotsNeeded) > 0,
    );

    return PageBody(
      children: [
        const AccountHeader(title: 'Volunteering', subtitle: "Where you're serving, and where help is needed."),
        SectionContainer(
          maxWidth: 820,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('My assignments', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              if (mine.isEmpty)
                const EmptyState(message: "You haven't signed up to serve anywhere yet.")
              else
                for (final assignment in mine)
                  _AssignmentTile(assignment: assignment, position: byId[assignment.positionId]),
            ],
          ),
        ),
        SectionContainer(
          backgroundColor: Colors.white,
          maxWidth: 820,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Open positions', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 4),
              const Text(
                'Signing up sends a request - a staff member confirms it before '
                "it's final.",
                style: TextStyle(color: Colors.black54, fontSize: 13),
              ),
              const SizedBox(height: 16),
              if (available.isEmpty)
                const EmptyState(message: 'No open positions right now - check back soon.')
              else
                for (final position in available)
                  Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      title: Text(position.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: Text(
                        [
                          DateFormat.yMMMd().format(position.date),
                          if (position.location.isNotEmpty) position.location,
                          '${openSlots[position.id] ?? position.slotsNeeded} spot(s) open',
                        ].join(' · '),
                      ),
                      trailing: ElevatedButton(
                        onPressed: () => ref.read(volunteerControllerProvider).signUp(position.id),
                        child: const Text('Sign Up'),
                      ),
                    ),
                  ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AssignmentTile extends ConsumerWidget {
  final VolunteerAssignment assignment;
  final VolunteerPosition? position;

  const _AssignmentTile({required this.assignment, required this.position});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final label = switch (assignment.status) {
      AssignmentStatus.pending => 'Pending approval',
      AssignmentStatus.approved => "You're confirmed",
      AssignmentStatus.declined => 'Declined',
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text(position?.title ?? 'Unknown position', style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(
          position == null ? label : '${DateFormat.yMMMd().format(position!.date)} · $label',
        ),
        trailing: assignment.status == AssignmentStatus.declined
            ? null
            : TextButton(
                onPressed: () => ref.read(volunteerControllerProvider).decline(assignment),
                child: const Text('Decline'),
              ),
      ),
    );
  }
}
