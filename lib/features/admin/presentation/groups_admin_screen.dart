import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../audit_log/application/audit_providers.dart';
import '../../groups/application/group_providers.dart';
import '../../groups/domain/group.dart';
import 'admin_header.dart';

class GroupsAdminScreen extends ConsumerWidget {
  const GroupsAdminScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allMemberships = ref.watch(allMembershipsProvider).valueOrNull ?? const <GroupMembership>[];

    Future<void> openForm({ChurchGroup? existing}) async {
      final result = await showDialog<ChurchGroup>(
        context: context,
        builder: (_) => _GroupForm(existing: existing),
      );
      if (result == null) return;
      final repo = ref.read(groupRepositoryProvider);
      if (existing == null) {
        await repo.create(result);
      } else {
        await repo.update(result);
      }
      ref.invalidate(groupsProvider);
    }

    return AdminListScaffold<ChurchGroup>(
      title: 'Groups',
      subtitle: 'Manage small groups and approve people who ask to join.',
      value: ref.watch(groupsProvider),
      errorContext: 'groups',
      emptyMessage: 'No groups yet. Add the first one.',
      newLabel: 'New Group',
      onNew: openForm,
      itemBuilder: (group) {
        final pending = allMemberships
            .where((m) => m.groupId == group.id && m.status == MembershipStatus.pending)
            .length;

        return AdminListTile(
          title: group.name,
          subtitle: [
            if (group.category.isNotEmpty) group.category,
            if (group.whenAndWhere.isNotEmpty) group.whenAndWhere,
            if (!group.openToJoin) 'closed to new members',
          ].join(' · '),
          deleteLabel: 'the group "${group.name}"',
          actions: [
            Badge(
              isLabelVisible: pending > 0,
              label: Text('$pending'),
              child: TextButton(
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => _RosterDialog(group: group),
                ),
                child: const Text('Roster'),
              ),
            ),
          ],
          onEdit: () => openForm(existing: group),
          onDelete: () async {
            await ref.read(groupRepositoryProvider).delete(group.id);
            await ref.read(auditLoggerProvider).record(
                  action: 'deleted',
                  entity: 'group',
                  details: group.name,
                );
            ref.invalidate(groupsProvider);
          },
        );
      },
    );
  }
}

class _RosterDialog extends ConsumerWidget {
  final ChurchGroup group;

  const _RosterDialog({required this.group});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memberships = ref.watch(groupMembershipsProvider(group.id));
    final controller = ref.read(groupControllerProvider);

    return AlertDialog(
      title: Text('${group.name} roster'),
      content: SizedBox(
        width: 460,
        child: memberships.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => Text('Could not load the roster: $e'),
          data: (list) {
            if (list.isEmpty) {
              return const Padding(padding: EdgeInsets.all(24), child: Text('No one has joined yet.'));
            }
            final pending = list.where((m) => m.status == MembershipStatus.pending).toList();
            final approved = list.where((m) => m.status == MembershipStatus.approved).toList();

            return ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 380),
              child: ListView(
                shrinkWrap: true,
                children: [
                  if (pending.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text('Waiting for approval', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                    for (final m in pending)
                      ListTile(
                        dense: true,
                        title: Text(m.memberName.isEmpty ? m.uid : m.memberName),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: 'Approve',
                              icon: const Icon(Icons.check_circle_outline),
                              onPressed: () => controller.approve(m),
                            ),
                            IconButton(
                              tooltip: 'Remove',
                              icon: const Icon(Icons.remove_circle_outline),
                              onPressed: () => controller.remove(m.id),
                            ),
                          ],
                        ),
                      ),
                  ],
                  if (approved.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text('Members', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                    for (final m in approved)
                      ListTile(
                        dense: true,
                        title: Text(m.memberName.isEmpty ? m.uid : m.memberName),
                        trailing: IconButton(
                          tooltip: 'Remove',
                          icon: const Icon(Icons.remove_circle_outline),
                          onPressed: () => controller.remove(m.id),
                        ),
                      ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
    );
  }
}

class _GroupForm extends StatefulWidget {
  final ChurchGroup? existing;

  const _GroupForm({this.existing});

  @override
  State<_GroupForm> createState() => _GroupFormState();
}

class _GroupFormState extends State<_GroupForm> {
  final _formKey = GlobalKey<FormState>();
  late final Map<String, TextEditingController> _c;
  late bool _openToJoin;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _c = {
      'name': TextEditingController(text: e?.name ?? ''),
      'category': TextEditingController(text: e?.category ?? ''),
      'leaderName': TextEditingController(text: e?.leaderName ?? ''),
      'meetingDay': TextEditingController(text: e?.meetingDay ?? ''),
      'meetingTime': TextEditingController(text: e?.meetingTime ?? ''),
      'location': TextEditingController(text: e?.location ?? ''),
      'description': TextEditingController(text: e?.description ?? ''),
    };
    _openToJoin = e?.openToJoin ?? true;
  }

  @override
  void dispose() {
    for (final c in _c.values) {
      c.dispose();
    }
    super.dispose();
  }

  String _t(String k) => _c[k]!.text.trim();

  @override
  Widget build(BuildContext context) {
    return AdminFormDialog(
      title: widget.existing == null ? 'New Group' : 'Edit Group',
      onSave: () {
        if (!_formKey.currentState!.validate()) return;
        Navigator.pop(
          context,
          ChurchGroup(
            id: widget.existing?.id ?? '',
            name: _t('name'),
            category: _t('category'),
            leaderName: _t('leaderName'),
            meetingDay: _t('meetingDay'),
            meetingTime: _t('meetingTime'),
            location: _t('location'),
            description: _t('description'),
            openToJoin: _openToJoin,
          ),
        );
      },
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _c['name'],
              decoration: const InputDecoration(labelText: 'Name'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            TextFormField(controller: _c['category'], decoration: const InputDecoration(labelText: 'Category')),
            TextFormField(controller: _c['leaderName'], decoration: const InputDecoration(labelText: 'Leader')),
            TextFormField(
              controller: _c['meetingDay'],
              decoration: const InputDecoration(labelText: 'Meeting day'),
            ),
            TextFormField(
              controller: _c['meetingTime'],
              decoration: const InputDecoration(labelText: 'Meeting time'),
            ),
            TextFormField(controller: _c['location'], decoration: const InputDecoration(labelText: 'Location')),
            TextFormField(
              controller: _c['description'],
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 3,
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Open to new members'),
              subtitle: const Text('Turn off for groups that are full or invite-only.'),
              value: _openToJoin,
              onChanged: (v) => setState(() => _openToJoin = v),
            ),
          ],
        ),
      ),
    );
  }
}
