import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/config/settings_providers.dart';
import '../../../core/widgets/app_shell.dart';
import '../../../core/widgets/async_value_widget.dart';
import '../../../core/widgets/section_container.dart';
import '../../kids/application/check_in_providers.dart';
import '../../kids/domain/check_in.dart';
import 'account_header.dart';

/// Where a parent finds the pickup code without needing a paper slip.
class MyKidsScreen extends ConsumerWidget {
  const MyKidsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PageBody(
      children: [
        const AccountHeader(
          title: 'Kids Check-In',
          subtitle: 'Your pickup codes, and where each child is today.',
        ),
        SectionContainer(
          maxWidth: 720,
          child: AsyncValueWidget<List<CheckInSession>>(
            value: ref.watch(myCheckInsProvider),
            errorContext: 'your check-ins',
            data: (sessions) {
              final active = sessions.where((s) => s.isActive).toList();
              final past = sessions.where((s) => !s.isActive).toList();

              if (sessions.isEmpty) {
                return const EmptyState(
                  message: 'No check-ins yet. A volunteer will check your children in at the desk.',
                  icon: Icons.child_care_outlined,
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (active.isEmpty)
                    const EmptyState(
                      message: 'Nobody checked in right now.',
                      icon: Icons.child_care_outlined,
                    )
                  else
                    for (final session in active) _ActiveCard(session: session),
                  if (past.isNotEmpty) ...[
                    const SizedBox(height: 28),
                    Text('Earlier', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    for (final session in past.take(10))
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        leading: const Icon(Icons.check_circle_outline, size: 20, color: Colors.black38),
                        title: Text(session.childName),
                        subtitle: Text(
                          '${session.roomName} · '
                          '${DateFormat.yMMMd().format(session.checkedInAt)}'
                          '${session.releasedTo.isEmpty ? '' : ' · collected by ${session.releasedTo}'}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                  ],
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ActiveCard extends ConsumerWidget {
  final CheckInSession session;

  const _ActiveCard({required this.session});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brand = ref.watch(settingsProvider).colors;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(session.childName, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 4),
            Text(
              '${session.roomName} · checked in at ${DateFormat.jm().format(session.checkedInAt)}',
              style: const TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
              decoration: BoxDecoration(
                color: brand.accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: brand.accent),
              ),
              child: Column(
                children: [
                  const Text(
                    'PICKUP CODE',
                    style: TextStyle(fontSize: 11, letterSpacing: 2, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    session.pickupCode,
                    style: TextStyle(
                      fontSize: 48,
                      letterSpacing: 10,
                      fontWeight: FontWeight.w700,
                      color: brand.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Show this at the door. It works once - after your child is '
              'collected, the code stops working.',
              style: TextStyle(color: Colors.black54, fontSize: 13, height: 1.5),
            ),
            if (session.hasAllergyNote) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.warning_amber_rounded, size: 18, color: Colors.orange.shade800),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'On file: ${session.allergyNote}',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
