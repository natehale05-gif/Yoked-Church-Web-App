import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/settings_providers.dart';
import '../../../core/config/tenant.dart';
import '../../../core/widgets/app_shell.dart';
import '../../../core/widgets/section_container.dart';
import '../../auth/application/auth_providers.dart';
import '../../connect/application/connect_providers.dart';
import '../../groups/application/group_providers.dart';
import '../../prayer_wall/application/prayer_providers.dart';
import '../../rooms/application/room_providers.dart';
import '../../groups/domain/group.dart';
import '../../volunteering/application/volunteering_providers.dart';
import '../../volunteering/domain/volunteering.dart';
import '../application/setup_checklist.dart';
import 'admin_header.dart';

/// What is still missing, and where to go and add it.
///
/// A church that has just signed up lands here on an empty dashboard.
/// Without this it is a grid of twenty tools and no indication which one
/// matters first - which is the moment most self-serve products lose
/// people.
///
/// Disappears entirely once everything is done, rather than sitting
/// there as a permanent "8 of 8". A checklist you cannot finish is
/// furniture.
class _SetupChecklist extends ConsumerWidget {
  const _SetupChecklist();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final steps = ref.watch(setupChecklistProvider);
    final remaining = steps.where((s) => !s.done).toList();
    if (remaining.isEmpty) return const SizedBox.shrink();

    final progress = ref.watch(setupProgressProvider);
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 36),
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text('Finish setting up', style: theme.textTheme.titleLarge),
                  ),
                  Text(
                    '${progress.done} of ${progress.total}',
                    style: const TextStyle(color: Colors.black54, fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress.total == 0 ? 0 : progress.done / progress.total,
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: 8),
              // Only what is left. The done ones are not an achievement
              // to display, they are just no longer the question.
              for (final step in remaining) _SetupRow(step: step),
            ],
          ),
        ),
      ),
    );
  }
}

class _SetupRow extends StatelessWidget {
  final SetupStep step;

  const _SetupRow({required this.step});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.go(step.path),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.radio_button_unchecked, size: 18, color: Colors.black38),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(step.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(
                    step.why,
                    style: const TextStyle(color: Colors.black54, fontSize: 12.5, height: 1.3),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, size: 18, color: Colors.black38),
          ],
        ),
      ),
    );
  }
}

/// The church's own address, with a way to copy it.
///
/// It was shown once, while the church was being named at signup, and
/// then nowhere at all - not here, not in settings. Handing that link
/// out is the entire point of having a site, and an admin should not have
/// to reconstruct it from the browser bar or remember what they typed
/// weeks ago.
///
/// Deliberately not a row in [_SetupChecklist]: that disappears the
/// moment a church finishes setting up, and this is the one thing they
/// will still want on the day they print the newsletter.
class _YourAddress extends ConsumerStatefulWidget {
  const _YourAddress();

  @override
  ConsumerState<_YourAddress> createState() => _YourAddressState();
}

class _YourAddressState extends ConsumerState<_YourAddress> {
  bool _copied = false;

  @override
  Widget build(BuildContext context) {
    final churchId = ref.watch(currentChurchIdProvider);
    final theme = Theme.of(context);

    // Empty off the web, where there is no origin to build an address
    // from. The path is still worth showing - it is the church's
    // identity, and the part that goes after whatever the site's domain
    // turns out to be.
    final url = churchUrl(churchId);
    final shown = url.isEmpty ? churchPath(churchId) : url;

    return Padding(
      padding: const EdgeInsets.only(bottom: 36),
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.link, size: 18, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  // Expanded because a Row gives its children unbounded
                  // width, so the title would run off the side of a phone
                  // rather than wrapping - which is what the identical
                  // header above this one already learned.
                  Expanded(
                    child: Text('Your church\'s address', style: theme.textTheme.titleMedium),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Send this to anyone - put it in the newsletter, on a card, '
                'in the bulletin. It opens your site, not anyone else\'s.',
                style: const TextStyle(color: Colors.black54, fontSize: 13, height: 1.35),
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                // No `fontFamily: 'monospace'`, however much an address
                // wants one. This app bundles Lora and Work Sans and
                // nothing else, and naming a family it does not ship
                // renders no glyphs at all on the web build - the box
                // came out empty, exactly as the landing page's buttons
                // once did. A font is not worth an invisible address.
                child: SelectableText(
                  shown,
                  style: const TextStyle(fontSize: 13, letterSpacing: 0.2),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  FilledButton.icon(
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: shown));
                      if (!mounted) return;
                      // Confirmed on the button itself rather than in a
                      // snackbar: a copy is one of those actions where
                      // nothing visible happens, and the doubt sends
                      // people clicking it again.
                      setState(() => _copied = true);
                    },
                    icon: Icon(_copied ? Icons.check : Icons.copy, size: 18),
                    label: Text(_copied ? 'Copied' : 'Copy link'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => context.go(churchPath(churchId)),
                    icon: const Icon(Icons.open_in_new, size: 18),
                    label: const Text('View your site'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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
              const _SetupChecklist(),
              const _YourAddress(),
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
                  // Skip Overview - it's the page you're already on.
                  for (final tab in visibleAdminTabs(ref.watch(featureFlagsProvider), isAdmin: isAdmin)
                      .where((t) => t.path != '/admin'))
                    _Tile(icon: tab.icon, label: tab.label, path: tab.path),
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

    final flags = ref.watch(featureFlagsProvider);

    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        if (flags.connect) _Stat(label: 'Open messages', value: openSubmissions, path: '/admin/connect'),
        if (flags.groups) _Stat(label: 'Group requests', value: pendingGroups, path: '/admin/groups'),
        if (flags.volunteering)
          _Stat(label: 'Volunteer requests', value: pendingVolunteers, path: '/admin/volunteering'),
        if (flags.prayerWall)
          _Stat(
            label: 'Prayer requests',
            value: ref.watch(pendingPrayerCountProvider),
            path: '/admin/prayer',
          ),
        if (flags.roomBooking)
          _Stat(
            label: 'Room requests',
            value: ref.watch(pendingBookingCountProvider),
            path: '/admin/rooms',
          ),
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
