import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/settings_providers.dart';
import '../../../core/widgets/app_shell.dart';
import '../../../core/widgets/section_container.dart';
import '../../auth/application/auth_providers.dart';
import '../../connect/application/connect_providers.dart';
import '../../groups/application/group_providers.dart';
import '../../groups/domain/group.dart';
import '../../volunteering/application/volunteering_providers.dart';
import '../../volunteering/domain/volunteering.dart';
import 'admin_header.dart';

class AdminHomeScreen extends ConsumerWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final isAdmin = ref.watch(isAdminProvider);
    final firstName = (user?.displayName ?? '').split(' ').first;

    return PageBody(
      children: [
        AdminHeader(
          title: firstName.isEmpty ? 'Staff Dashboard' : 'Welcome, $firstName',
          subtitle: "Everything waiting on you, and the tools to manage the church's content.",
        ),
        SectionContainer(
          maxWidth: 900,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Needs attention', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              const _NeedsAttention(),
              const SizedBox(height: 36),
              Text('Manage', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              Wrap(
                spacing: 20,
                runSpacing: 20,
                children: [
                  const _Tile(icon: Icons.play_circle_outline, label: 'Sermons', path: '/admin/sermons'),
                  const _Tile(icon: Icons.event_outlined, label: 'Events', path: '/admin/events'),
                  const _Tile(icon: Icons.groups_outlined, label: 'Groups', path: '/admin/groups'),
                  const _Tile(
                    icon: Icons.volunteer_activism_outlined,
                    label: 'Volunteering',
                    path: '/admin/volunteering',
                  ),
                  const _Tile(icon: Icons.inbox_outlined, label: 'Connect Inbox', path: '/admin/connect'),
                  const _Tile(icon: Icons.campaign_outlined, label: 'Announcements', path: '/admin/announcements'),
                  if (isAdmin) ...[
                    const _Tile(icon: Icons.people_alt_outlined, label: 'Members', path: '/admin/members'),
                    const _Tile(icon: Icons.tune, label: 'Church Settings', path: '/admin/settings'),
                    const _Tile(icon: Icons.history, label: 'Audit Log', path: '/admin/audit'),
                  ],
                ],
              ),
              const SizedBox(height: 32),
              const Divider(),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () => context.go('/account'),
                icon: const Icon(Icons.person_outline),
                label: const Text('Back to my account'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Live counts of the things a staff member actually has to act on -
/// more useful than a menu that says nothing about workload.
class _NeedsAttention extends ConsumerWidget {
  const _NeedsAttention();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final openSubmissions = ref.watch(openSubmissionsCountProvider);

    final pendingGroups = (ref.watch(allMembershipsProvider).valueOrNull ?? const <GroupMembership>[])
        .where((m) => m.status == MembershipStatus.pending)
        .length;

    final pendingVolunteers = (ref.watch(allAssignmentsProvider).valueOrNull ?? const <VolunteerAssignment>[])
        .where((a) => a.status == AssignmentStatus.pending)
        .length;

    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        _Stat(label: 'Open messages', value: openSubmissions, path: '/admin/connect'),
        _Stat(label: 'Group requests', value: pendingGroups, path: '/admin/groups'),
        _Stat(label: 'Volunteer requests', value: pendingVolunteers, path: '/admin/volunteering'),
      ],
    );
  }
}

class _Stat extends ConsumerWidget {
  final String label;
  final int value;
  final String path;

  const _Stat({required this.label, required this.value, required this.path});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brand = ref.watch(settingsProvider).colors;
    final needsAction = value > 0;

    return InkWell(
      onTap: () => context.go(path),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 190,
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: needsAction ? brand.accent.withValues(alpha: 0.12) : null,
          border: Border.all(color: needsAction ? brand.accent : Colors.black12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$value',
              style: TextStyle(color: brand.primary, fontSize: 28, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(color: Colors.black54, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

class _Tile extends ConsumerWidget {
  final IconData icon;
  final String label;
  final String path;

  const _Tile({required this.icon, required this.label, required this.path});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      onTap: () => context.go(path),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 175,
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Icon(icon, size: 30, color: ref.watch(settingsProvider).colors.primary),
            const SizedBox(height: 10),
            Text(label, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
