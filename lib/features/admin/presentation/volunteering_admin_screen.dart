import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../audit_log/application/audit_providers.dart';
import '../../auth/application/auth_providers.dart';
import '../../auth/domain/app_user.dart';
import '../../volunteering/application/volunteering_providers.dart';
import '../../volunteering/domain/volunteering.dart';
import 'admin_header.dart';

class VolunteeringAdminScreen extends ConsumerWidget {
  const VolunteeringAdminScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final all = ref.watch(allAssignmentsProvider).valueOrNull ?? const <VolunteerAssignment>[];
    final openSlots = ref.watch(openSlotsProvider).valueOrNull ?? const <String, int>{};

    Future<void> openForm({VolunteerPosition? existing}) async {
      final result = await showDialog<VolunteerPosition>(
        context: context,
        builder: (_) => _PositionForm(existing: existing),
      );
      if (result == null) return;
      final repo = ref.read(volunteerPositionRepositoryProvider);
      if (existing == null) {
        await repo.create(result);
      } else {
        await repo.update(result);
      }
      ref.invalidate(volunteerPositionsProvider);
    }

    return AdminListScaffold<VolunteerPosition>(
      title: 'Volunteering',
      subtitle: 'Create positions, assign people, and approve those who sign themselves up.',
      value: ref.watch(volunteerPositionsProvider),
      errorContext: 'volunteer positions',
      emptyMessage: 'No volunteer positions yet.',
      newLabel: 'New Position',
      onNew: openForm,
      itemBuilder: (position) {
        final pending =
            all.where((a) => a.positionId == position.id && a.status == AssignmentStatus.pending).length;
        final remaining = openSlots[position.id] ?? position.slotsNeeded;

        return AdminListTile(
          title: position.title,
          subtitle: [
            DateFormat.yMMMd().format(position.date),
            if (position.location.isNotEmpty) position.location,
            '$remaining of ${position.slotsNeeded} still needed',
          ].join(' · '),
          deleteLabel: '"${position.title}"',
          actions: [
            Badge(
              isLabelVisible: pending > 0,
              label: Text('$pending'),
              child: TextButton(
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => _AssignmentsDialog(position: position),
                ),
                child: const Text('People'),
              ),
            ),
          ],
          onEdit: () => openForm(existing: position),
          onDelete: () async {
            await ref.read(volunteerPositionRepositoryProvider).delete(position.id);
            await ref.read(auditLoggerProvider).record(
                  action: 'deleted',
                  entity: 'volunteer position',
                  details: position.title,
                );
            ref.invalidate(volunteerPositionsProvider);
          },
        );
      },
    );
  }
}

class _AssignmentsDialog extends ConsumerWidget {
  final VolunteerPosition position;

  const _AssignmentsDialog({required this.position});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assignments = ref.watch(positionAssignmentsProvider(position.id));
    final controller = ref.read(volunteerControllerProvider);

    Future<void> assignSomeone() async {
      final members = ref.read(allMembersProvider).valueOrNull ?? const <AppUser>[];
      final picked = await showDialog<AppUser>(
        context: context,
        builder: (_) => SimpleDialog(
          title: const Text('Assign a member'),
          children: members.isEmpty
              ? [const Padding(padding: EdgeInsets.all(24), child: Text('No members to assign yet.'))]
              : [
                  for (final m in members)
                    SimpleDialogOption(
                      onPressed: () => Navigator.pop(context, m),
                      child: Text(m.displayName.isEmpty ? m.email : m.displayName),
                    ),
                ],
        ),
      );
      if (picked == null) return;
      // Direct assignment is confirmed immediately and notifies the member.
      await controller.assign(position: position, uid: picked.uid, memberName: picked.displayName);
    }

    return AlertDialog(
      title: Text('${position.title} - people'),
      content: SizedBox(
        width: 460,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: assignSomeone,
                icon: const Icon(Icons.person_add_alt, size: 18),
                label: const Text('Assign someone'),
              ),
            ),
            assignments.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Text('Could not load assignments: $e'),
              data: (list) {
                if (list.isEmpty) {
                  return const Padding(padding: EdgeInsets.all(24), child: Text('Nobody signed up yet.'));
                }
                return ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 340),
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      for (final a in list)
                        ListTile(
                          dense: true,
                          title: Text(a.memberName.isEmpty ? a.uid : a.memberName),
                          subtitle: Text(switch (a.status) {
                            AssignmentStatus.pending => 'Asked to serve - needs approval',
                            AssignmentStatus.approved =>
                              a.assignedBy == 'self' ? 'Confirmed (signed up)' : 'Confirmed (assigned)',
                            AssignmentStatus.declined => 'Declined',
                          }),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (a.status == AssignmentStatus.pending)
                                IconButton(
                                  tooltip: 'Approve',
                                  icon: const Icon(Icons.check_circle_outline),
                                  onPressed: () => controller.approve(a, position),
                                ),
                              IconButton(
                                tooltip: 'Remove',
                                icon: const Icon(Icons.remove_circle_outline),
                                onPressed: () => controller.remove(a.id),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
    );
  }
}

class _PositionForm extends StatefulWidget {
  final VolunteerPosition? existing;

  const _PositionForm({this.existing});

  @override
  State<_PositionForm> createState() => _PositionFormState();
}

class _PositionFormState extends State<_PositionForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _description;
  late final TextEditingController _location;
  late final TextEditingController _slots;
  late DateTime _date;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _title = TextEditingController(text: e?.title ?? '');
    _description = TextEditingController(text: e?.description ?? '');
    _location = TextEditingController(text: e?.location ?? '');
    _slots = TextEditingController(text: '${e?.slotsNeeded ?? 1}');
    _date = e?.date ?? DateTime.now();
  }

  @override
  void dispose() {
    for (final c in [_title, _description, _location, _slots]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AdminFormDialog(
      title: widget.existing == null ? 'New Position' : 'Edit Position',
      onSave: () {
        if (!_formKey.currentState!.validate()) return;
        Navigator.pop(
          context,
          VolunteerPosition(
            id: widget.existing?.id ?? '',
            title: _title.text.trim(),
            description: _description.text.trim(),
            location: _location.text.trim(),
            slotsNeeded: int.tryParse(_slots.text.trim()) ?? 1,
            date: _date,
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
              controller: _title,
              decoration: const InputDecoration(labelText: 'Title'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            TextFormField(controller: _location, decoration: const InputDecoration(labelText: 'Location')),
            TextFormField(
              controller: _slots,
              decoration: const InputDecoration(labelText: 'People needed'),
              keyboardType: TextInputType.number,
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('Date: ${DateFormat.yMMMd().format(_date)}'),
              trailing: TextButton(
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _date,
                    firstDate: DateTime(2015),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) setState(() => _date = picked);
                },
                child: const Text('Change'),
              ),
            ),
            TextFormField(
              controller: _description,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }
}
