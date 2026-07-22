import 'package:flutter/material.dart';

import '../../models/app_user.dart';
import '../../models/church_group.dart';
import '../../models/group_membership.dart';
import '../../services/group_service.dart';
import '../../services/user_service.dart';
import '../../widgets/admin_header.dart';
import '../../widgets/section_container.dart';

class GroupsAdminScreen extends StatefulWidget {
  const GroupsAdminScreen({super.key});

  @override
  State<GroupsAdminScreen> createState() => _GroupsAdminScreenState();
}

class _GroupsAdminScreenState extends State<GroupsAdminScreen> {
  final GroupService _service = GroupService();
  late Future<List<ChurchGroup>> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.fetchGroups();
  }

  void _refresh() => setState(() => _future = _service.fetchGroups());

  Future<void> _openForm({ChurchGroup? existing}) async {
    final result = await showDialog<ChurchGroup>(
      context: context,
      builder: (context) => _GroupFormDialog(existing: existing),
    );
    if (result == null) return;
    if (existing == null) {
      await _service.createGroup(result);
    } else {
      await _service.updateGroup(result);
    }
    _refresh();
  }

  Future<void> _delete(ChurchGroup group) async {
    await _service.deleteGroup(group.id);
    _refresh();
  }

  Future<void> _manageRoster(ChurchGroup group) async {
    await showDialog<void>(
      context: context,
      builder: (context) => _RosterDialog(group: group, service: _service),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const AdminHeader(title: 'Groups', subtitle: 'Manage small groups and approve join requests.'),
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
                  label: const Text('New Group'),
                ),
              ),
              const SizedBox(height: 16),
              FutureBuilder<List<ChurchGroup>>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 60),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  final groups = snapshot.data ?? [];
                  if (groups.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 60),
                      child: Center(child: Text('No groups yet.')),
                    );
                  }
                  return Column(
                    children: groups.map((group) {
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          title: Text(group.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                          subtitle: Text('${group.category} · ${group.meetingDay} ${group.meetingTime}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TextButton(onPressed: () => _manageRoster(group), child: const Text('Roster')),
                              IconButton(
                                icon: const Icon(Icons.edit_outlined),
                                onPressed: () => _openForm(existing: group),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () => _delete(group),
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

class _GroupFormDialog extends StatefulWidget {
  final ChurchGroup? existing;

  const _GroupFormDialog({this.existing});

  @override
  State<_GroupFormDialog> createState() => _GroupFormDialogState();
}

class _GroupFormDialogState extends State<_GroupFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _category;
  late final TextEditingController _description;
  late final TextEditingController _meetingDay;
  late final TextEditingController _meetingTime;
  late final TextEditingController _location;
  late final TextEditingController _leaderName;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _name = TextEditingController(text: e?.name ?? '');
    _category = TextEditingController(text: e?.category ?? '');
    _description = TextEditingController(text: e?.description ?? '');
    _meetingDay = TextEditingController(text: e?.meetingDay ?? '');
    _meetingTime = TextEditingController(text: e?.meetingTime ?? '');
    _location = TextEditingController(text: e?.location ?? '');
    _leaderName = TextEditingController(text: e?.leaderName ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _category.dispose();
    _description.dispose();
    _meetingDay.dispose();
    _meetingTime.dispose();
    _location.dispose();
    _leaderName.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(ChurchGroup(
      id: widget.existing?.id ?? '',
      name: _name.text.trim(),
      description: _description.text.trim(),
      category: _category.text.trim(),
      meetingDay: _meetingDay.text.trim(),
      meetingTime: _meetingTime.text.trim(),
      location: _location.text.trim(),
      leaderName: _leaderName.text.trim(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existing == null ? 'New Group' : 'Edit Group'),
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
                  controller: _name,
                  decoration: const InputDecoration(labelText: 'Name'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                TextFormField(controller: _category, decoration: const InputDecoration(labelText: 'Category')),
                TextFormField(controller: _leaderName, decoration: const InputDecoration(labelText: 'Leader name')),
                TextFormField(controller: _meetingDay, decoration: const InputDecoration(labelText: 'Meeting day')),
                TextFormField(controller: _meetingTime, decoration: const InputDecoration(labelText: 'Meeting time')),
                TextFormField(controller: _location, decoration: const InputDecoration(labelText: 'Location')),
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

class _RosterDialog extends StatefulWidget {
  final ChurchGroup group;
  final GroupService service;

  const _RosterDialog({required this.group, required this.service});

  @override
  State<_RosterDialog> createState() => _RosterDialogState();
}

class _RosterDialogState extends State<_RosterDialog> {
  final UserService _userService = UserService();
  late Future<List<(GroupMembership, AppUser?)>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<(GroupMembership, AppUser?)>> _load() async {
    final memberships = await widget.service.fetchMembershipsForGroup(widget.group.id);
    final result = <(GroupMembership, AppUser?)>[];
    for (final membership in memberships) {
      final user = await _userService.fetchUser(membership.uid);
      result.add((membership, user));
    }
    return result;
  }

  Future<void> _approve(GroupMembership membership) async {
    await widget.service.approveMembership(membership.id);
    setState(() => _future = _load());
  }

  Future<void> _remove(GroupMembership membership) async {
    await widget.service.removeMembership(membership.id);
    setState(() => _future = _load());
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('${widget.group.name} Roster'),
      content: SizedBox(
        width: 480,
        child: FutureBuilder<List<(GroupMembership, AppUser?)>>(
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
              return const Padding(padding: EdgeInsets.all(24), child: Text('No one has joined yet.'));
            }
            return SizedBox(
              height: 320,
              child: ListView(
                shrinkWrap: true,
                children: rows.map((row) {
                  final (membership, user) = row;
                  final approved = membership.status == MembershipStatus.approved;
                  return ListTile(
                    title: Text(user?.displayName ?? membership.uid),
                    subtitle: Text(approved ? 'Member' : 'Pending approval'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!approved)
                          IconButton(
                            icon: const Icon(Icons.check_circle_outline),
                            tooltip: 'Approve',
                            onPressed: () => _approve(membership),
                          ),
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline),
                          tooltip: 'Remove',
                          onPressed: () => _remove(membership),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close')),
      ],
    );
  }
}
