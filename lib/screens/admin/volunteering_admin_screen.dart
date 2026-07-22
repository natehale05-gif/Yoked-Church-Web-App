import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/app_user.dart';
import '../../models/volunteer_assignment.dart';
import '../../models/volunteer_position.dart';
import '../../providers/auth_provider.dart';
import '../../services/user_service.dart';
import '../../services/volunteer_service.dart';
import '../../widgets/admin_header.dart';
import '../../widgets/section_container.dart';

class VolunteeringAdminScreen extends StatefulWidget {
  const VolunteeringAdminScreen({super.key});

  @override
  State<VolunteeringAdminScreen> createState() => _VolunteeringAdminScreenState();
}

class _VolunteeringAdminScreenState extends State<VolunteeringAdminScreen> {
  final VolunteerService _service = VolunteerService();
  late Future<List<VolunteerPosition>> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.fetchPositions();
  }

  void _refresh() => setState(() => _future = _service.fetchPositions());

  Future<void> _openForm({VolunteerPosition? existing}) async {
    final result = await showDialog<VolunteerPosition>(
      context: context,
      builder: (context) => _PositionFormDialog(existing: existing),
    );
    if (result == null) return;
    if (existing == null) {
      await _service.createPosition(result);
    } else {
      await _service.updatePosition(result);
    }
    _refresh();
  }

  Future<void> _delete(VolunteerPosition position) async {
    await _service.deletePosition(position.id);
    _refresh();
  }

  Future<void> _manageAssignments(VolunteerPosition position) async {
    final adminUid = context.read<AuthProvider>().currentUser?.uid ?? '';
    await showDialog<void>(
      context: context,
      builder: (context) => _AssignmentsDialog(position: position, service: _service, adminUid: adminUid),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const AdminHeader(title: 'Volunteering', subtitle: 'Create positions and assign members to serve.'),
        SectionContainer(
          maxWidth: 900,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  onPressed: () => _openForm(),
                  icon: const Icon(Icons.add),
                  label: const Text('New Position'),
                ),
              ),
              const SizedBox(height: 16),
              FutureBuilder<List<VolunteerPosition>>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 60),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  final positions = snapshot.data ?? [];
                  if (positions.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 60),
                      child: Center(child: Text('No volunteer positions yet.')),
                    );
                  }
                  return Column(
                    children: positions.map((position) {
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          title: Text(position.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                          subtitle: Text(
                              '${DateFormat.yMMMd().format(position.date)} · ${position.location} · needs ${position.slotsNeeded}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TextButton(onPressed: () => _manageAssignments(position), child: const Text('Assignments')),
                              IconButton(
                                icon: const Icon(Icons.edit_outlined),
                                onPressed: () => _openForm(existing: position),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () => _delete(position),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PositionFormDialog extends StatefulWidget {
  final VolunteerPosition? existing;

  const _PositionFormDialog({this.existing});

  @override
  State<_PositionFormDialog> createState() => _PositionFormDialogState();
}

class _PositionFormDialogState extends State<_PositionFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _description;
  late final TextEditingController _location;
  late final TextEditingController _slotsNeeded;
  late DateTime _date;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _title = TextEditingController(text: e?.title ?? '');
    _description = TextEditingController(text: e?.description ?? '');
    _location = TextEditingController(text: e?.location ?? '');
    _slotsNeeded = TextEditingController(text: (e?.slotsNeeded ?? 1).toString());
    _date = e?.date ?? DateTime.now();
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _location.dispose();
    _slotsNeeded.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked =
        await showDatePicker(context: context, initialDate: _date, firstDate: DateTime(2015), lastDate: DateTime(2100));
    if (picked != null) setState(() => _date = picked);
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(VolunteerPosition(
      id: widget.existing?.id ?? '',
      title: _title.text.trim(),
      description: _description.text.trim(),
      date: _date,
      location: _location.text.trim(),
      slotsNeeded: int.tryParse(_slotsNeeded.text.trim()) ?? 1,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existing == null ? 'New Position' : 'Edit Position'),
      content: SizedBox(
        width: 480,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
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
                  controller: _slotsNeeded,
                  decoration: const InputDecoration(labelText: 'Slots needed'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Date: ${DateFormat.yMMMd().format(_date)}'),
                  trailing: TextButton(onPressed: _pickDate, child: const Text('Change')),
                ),
                TextFormField(
                  controller: _description,
                  decoration: const InputDecoration(labelText: 'Description'),
                  maxLines: 3,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        ElevatedButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}

class _AssignmentsDialog extends StatefulWidget {
  final VolunteerPosition position;
  final VolunteerService service;
  final String adminUid;

  const _AssignmentsDialog({required this.position, required this.service, required this.adminUid});

  @override
  State<_AssignmentsDialog> createState() => _AssignmentsDialogState();
}

class _AssignmentsDialogState extends State<_AssignmentsDialog> {
  final UserService _userService = UserService();
  late Future<List<(VolunteerAssignment, AppUser?)>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<(VolunteerAssignment, AppUser?)>> _load() async {
    final assignments = await widget.service.fetchAssignmentsForPosition(widget.position.id);
    final result = <(VolunteerAssignment, AppUser?)>[];
    for (final assignment in assignments) {
      final user = await _userService.fetchUser(assignment.uid);
      result.add((assignment, user));
    }
    return result;
  }

  Future<void> _approve(VolunteerAssignment assignment) async {
    await widget.service.approveAssignment(assignment: assignment, position: widget.position);
    setState(() => _future = _load());
  }

  Future<void> _remove(VolunteerAssignment assignment) async {
    await widget.service.deleteAssignment(assignment.id);
    setState(() => _future = _load());
  }

  Future<void> _assignMember() async {
    final members = await _userService.fetchAllUsers();
    if (!mounted) return;
    final picked = await showDialog<AppUser>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Assign a member'),
        children: members
            .map((m) => SimpleDialogOption(
                  onPressed: () => Navigator.of(context).pop(m),
                  child: Text(m.displayName.isEmpty ? m.email : m.displayName),
                ))
            .toList(),
      ),
    );
    if (picked == null) return;
    await widget.service.assignMember(position: widget.position, uid: picked.uid, adminUid: widget.adminUid);
    setState(() => _future = _load());
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('${widget.position.title} Assignments'),
      content: SizedBox(
        width: 480,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _assignMember,
                icon: const Icon(Icons.person_add_alt),
                label: const Text('Assign Member'),
              ),
            ),
            FutureBuilder<List<(VolunteerAssignment, AppUser?)>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                final rows = snapshot.data ?? [];
                if (rows.isEmpty) {
                  return const Padding(padding: EdgeInsets.all(24), child: Text('No one assigned yet.'));
                }
                return SizedBox(
                  height: 320,
                  child: ListView(
                    shrinkWrap: true,
                    children: rows.map((row) {
                      final (assignment, user) = row;
                      return ListTile(
                        title: Text(user?.displayName ?? assignment.uid),
                        subtitle: Text(_statusLabel(assignment.status)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (assignment.status == AssignmentStatus.pending)
                              IconButton(
                                icon: const Icon(Icons.check_circle_outline),
                                tooltip: 'Approve',
                                onPressed: () => _approve(assignment),
                              ),
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline),
                              tooltip: 'Remove',
                              onPressed: () => _remove(assignment),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close')),
      ],
    );
  }

  String _statusLabel(AssignmentStatus status) {
    switch (status) {
      case AssignmentStatus.pending:
        return 'Pending approval';
      case AssignmentStatus.approved:
        return 'Confirmed';
      case AssignmentStatus.declined:
        return 'Declined';
    }
  }
}
