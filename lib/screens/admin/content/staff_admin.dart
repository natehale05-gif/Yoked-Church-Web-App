import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/staff_member.dart';
import '../../../state/site_controller.dart';
import '../admin_widgets.dart';

class StaffAdminScreen extends StatelessWidget {
  const StaffAdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final site = context.watch<SiteController>();

    return Scaffold(
      appBar: AppBar(title: const Text('Staff & Leaders')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _edit(context, null),
        icon: const Icon(Icons.add),
        label: const Text('Add person'),
      ),
      body: site.staff.isEmpty
          ? Center(
              child: Text('No staff added yet.',
                  style: Theme.of(context).textTheme.bodyLarge))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: site.staff.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final s = site.staff[i];
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundImage: s.photoUrl.trim().isNotEmpty
                          ? NetworkImage(s.photoUrl.trim())
                          : null,
                      child: s.photoUrl.trim().isEmpty
                          ? Text(s.name.isNotEmpty
                              ? s.name[0].toUpperCase()
                              : '?')
                          : null,
                    ),
                    title: Text(s.name),
                    subtitle: Text(s.role),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined),
                          onPressed: () => _edit(context, s),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => site.deleteStaff(s.id),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Future<void> _edit(BuildContext context, StaffMember? existing) async {
    final result = await Navigator.of(context).push<StaffMember>(
      MaterialPageRoute(
        builder: (_) => _StaffForm(existing: existing),
        fullscreenDialog: true,
      ),
    );
    if (result != null && context.mounted) {
      context.read<SiteController>().upsertStaff(result);
    }
  }
}

class _StaffForm extends StatefulWidget {
  final StaffMember? existing;

  const _StaffForm({this.existing});

  @override
  State<_StaffForm> createState() => _StaffFormState();
}

class _StaffFormState extends State<_StaffForm> {
  late StaffMember _draft;

  @override
  void initState() {
    super.initState();
    _draft = widget.existing ??
        StaffMember(
            id: 'st-${DateTime.now().microsecondsSinceEpoch}',
            name: '',
            role: '');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existing == null ? 'Add person' : 'Edit person'),
        actions: [
          TextButton(
            onPressed: _draft.name.trim().isEmpty
                ? null
                : () => Navigator.of(context).pop(_draft),
            child: const Text('Save'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AdminField(
            label: 'Name',
            value: _draft.name,
            onChanged: (v) => setState(() => _draft = _draft.copyWith(name: v)),
          ),
          AdminField(
            label: 'Role / title',
            value: _draft.role,
            onChanged: (v) => setState(() => _draft = _draft.copyWith(role: v)),
          ),
          AdminField(
            label: 'Bio',
            value: _draft.bio,
            maxLines: 4,
            onChanged: (v) => setState(() => _draft = _draft.copyWith(bio: v)),
          ),
          AdminField(
            label: 'Email',
            value: _draft.email,
            onChanged: (v) => setState(() => _draft = _draft.copyWith(email: v)),
          ),
          AdminField(
            label: 'Photo URL',
            value: _draft.photoUrl,
            hint: 'https://…',
            onChanged: (v) =>
                setState(() => _draft = _draft.copyWith(photoUrl: v)),
          ),
        ],
      ),
    );
  }
}
