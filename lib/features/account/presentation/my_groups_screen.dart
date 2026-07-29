import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/settings_providers.dart';
import '../../../core/widgets/app_shell.dart';
import '../../../core/widgets/async_value_widget.dart';
import '../../../core/widgets/section_container.dart';
import '../../attendance/application/attendance_providers.dart';
import '../../attendance/presentation/group_attendance_panel.dart';
import '../../groups/application/group_providers.dart';
import '../../groups/domain/group.dart';
import 'account_header.dart';

class MyGroupsScreen extends ConsumerWidget {
  const MyGroupsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memberships = ref.watch(myMembershipsProvider).valueOrNull ?? const [];
    final byGroupId = {for (final m in memberships) m.groupId: m};
    final led = ref.watch(featureFlagsProvider).attendance
        ? ref.watch(myLedGroupsProvider)
        : const <ChurchGroup>[];

    return PageBody(
      children: [
        const AccountHeader(title: 'Groups', subtitle: 'Find a small group or ministry team to join.'),
        SectionContainer(
          maxWidth: 820,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Only leaders ever see this, so it hides entirely rather
              // than showing an empty panel to the other ninety-nine
              // per cent.
              if (led.isNotEmpty) ...[
                Text('Groups you lead', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                for (final group in led) GroupAttendancePanel(group: group),
                const SizedBox(height: 24),
                Text('All groups', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
              ],
              AsyncListWidget<ChurchGroup>(
                value: ref.watch(groupsProvider),
                errorContext: 'groups',
                emptyMessage: 'No groups have been posted yet - check back soon.',
                data: (groups) => Column(
                  children: [
                    for (final group in groups)
                      _GroupTile(group: group, membership: byGroupId[group.id]),
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

class _GroupTile extends ConsumerWidget {
  final ChurchGroup group;
  final GroupMembership? membership;

  const _GroupTile({required this.group, required this.membership});

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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (group.category.isNotEmpty)
                    Text(
                      group.category.toUpperCase(),
                      style: TextStyle(color: brand.accent, fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                  const SizedBox(height: 4),
                  Text(group.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
                  if (group.whenAndWhere.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(group.whenAndWhere, style: const TextStyle(color: Colors.black54)),
                  ],
                  if (group.leaderName.isNotEmpty)
                    Text('Led by ${group.leaderName}', style: const TextStyle(color: Colors.black54, fontSize: 13)),
                  if (group.description.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(group.description),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 16),
            _JoinButton(group: group, membership: membership),
          ],
        ),
      ),
    );
  }
}

class _JoinButton extends ConsumerWidget {
  final ChurchGroup group;
  final GroupMembership? membership;

  const _JoinButton({required this.group, required this.membership});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (membership != null) {
      final approved = membership!.status == MembershipStatus.approved;
      return Chip(
        avatar: Icon(approved ? Icons.check_circle_outline : Icons.hourglass_empty, size: 16),
        label: Text(approved ? 'Member' : 'Pending'),
      );
    }
    if (!group.openToJoin) {
      return const Chip(label: Text('Closed'));
    }
    return ElevatedButton(
      onPressed: () => ref.read(groupControllerProvider).requestToJoin(group.id),
      child: const Text('Request to Join'),
    );
  }
}
