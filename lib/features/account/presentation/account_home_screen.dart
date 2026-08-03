import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/config/settings_providers.dart';
import '../../../core/widgets/app_shell.dart';
import '../../../core/widgets/section_container.dart';
import '../../auth/application/auth_providers.dart';
import '../../events/application/rsvp_providers.dart';
import '../../groups/application/group_providers.dart';
import '../../notifications/application/notification_providers.dart';
import '../../volunteering/application/volunteering_providers.dart';
import '../../volunteering/domain/volunteering.dart';
import 'account_header.dart';

class AccountHomeScreen extends ConsumerWidget {
  const AccountHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final flags = ref.watch(featureFlagsProvider);
    final firstName = (user?.displayName ?? '').split(' ').first;

    return PageBody(
      children: [
        AccountHeader(
          title: firstName.isEmpty ? 'Hi there' : 'Hi, $firstName',
          subtitle: 'Everything you’re part of, in one place.',
        ),
        SectionContainer(
          maxWidth: 900,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _AtAGlance(),
              const SizedBox(height: 32),
              Text('Quick links', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              Wrap(
                spacing: 20,
                runSpacing: 20,
                children: [
                  const _Tile(icon: Icons.person_outline, label: 'Profile', path: '/account/profile'),
                  if (flags.groups)
                    const _Tile(icon: Icons.groups_outlined, label: 'Groups', path: '/account/groups'),
                  if (flags.events)
                    const _Tile(icon: Icons.event_available_outlined, label: 'My Events', path: '/account/events'),
                  if (flags.volunteering)
                    const _Tile(
                      icon: Icons.volunteer_activism_outlined,
                      label: 'Volunteering',
                      path: '/account/volunteering',
                    ),
                  const _Tile(icon: Icons.people_alt_outlined, label: 'Directory', path: '/account/directory'),
                  if (flags.giving)
                    const _Tile(icon: Icons.favorite_outline, label: 'Giving', path: '/account/giving'),
                ],
              ),
              const SizedBox(height: 32),
              const Divider(),
              const SizedBox(height: 16),
              Row(
                children: [
                  if (user?.isStaff ?? false)
                    Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: ElevatedButton.icon(
                        onPressed: () => context.go('/admin'),
                        icon: const Icon(Icons.admin_panel_settings_outlined),
                        label: const Text('Staff Dashboard'),
                      ),
                    ),
                  OutlinedButton.icon(
                    onPressed: () async {
                      await ref.read(authControllerProvider.notifier).signOut();
                      if (context.mounted) context.go('/');
                    },
                    icon: const Icon(Icons.logout),
                    label: const Text('Sign Out'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// A compact summary so the overview isn't just a menu.
class _AtAGlance extends ConsumerWidget {
  const _AtAGlance();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final upcoming = ref.watch(myUpcomingEventsProvider).valueOrNull ?? const [];
    final assignments = (ref.watch(myAssignmentsProvider).valueOrNull ?? const [])
        .where((a) => a.status == AssignmentStatus.approved)
        .toList();
    final groups = ref.watch(myMembershipsProvider).valueOrNull ?? const [];
    final unread = ref.watch(unreadNotificationCountProvider);

    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        _Stat(label: 'Upcoming events', value: '${upcoming.length}', path: '/account/events'),
        _Stat(label: 'Serving', value: '${assignments.length}', path: '/account/volunteering'),
        _Stat(label: 'Groups', value: '${groups.length}', path: '/account/groups'),
        _Stat(label: 'Unread', value: '$unread', path: '/account/notifications'),
        if (upcoming.isNotEmpty)
          _NextUp(title: upcoming.first.title, when: DateFormat.MMMd().add_jm().format(upcoming.first.start)),
      ],
    );
  }
}

class _Stat extends ConsumerWidget {
  final String label;
  final String value;
  final String path;

  const _Stat({required this.label, required this.value, required this.path});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brand = ref.watch(settingsProvider).colors;
    return InkWell(
      onTap: () => context.go(path),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 150,
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: TextStyle(color: brand.primary, fontSize: 28, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(color: Colors.black54, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

class _NextUp extends ConsumerWidget {
  final String title;
  final String when;

  const _NextUp({required this.title, required this.when});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brand = ref.watch(settingsProvider).colors;
    return Container(
      width: 260,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: brand.accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('NEXT UP', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1)),
          const SizedBox(height: 6),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          Text(when, style: const TextStyle(color: Colors.black54, fontSize: 13)),
        ],
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
        width: 165,
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Icon(icon, size: 30, color: ref.watch(settingsProvider).colors.primary),
            const SizedBox(height: 10),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
