import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/ministry.dart';
import '../../../state/site_controller.dart';
import '../../../utils/icon_utils.dart';
import '../admin_widgets.dart';

class MinistriesAdminScreen extends StatelessWidget {
  const MinistriesAdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final site = context.watch<SiteController>();

    return Scaffold(
      appBar: AppBar(title: const Text('Ministries')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _edit(context, null),
        icon: const Icon(Icons.add),
        label: const Text('Add ministry'),
      ),
      body: site.ministries.isEmpty
          ? Center(
              child: Text('No ministries yet.',
                  style: Theme.of(context).textTheme.bodyLarge))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: site.ministries.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final m = site.ministries[i];
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                          Theme.of(context).colorScheme.primaryContainer,
                      child: Icon(ministryIcon(m.icon),
                          color: Theme.of(context)
                              .colorScheme
                              .onPrimaryContainer),
                    ),
                    title: Text(m.name),
                    subtitle:
                        m.leader.isNotEmpty ? Text('Led by ${m.leader}') : null,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined),
                          onPressed: () => _edit(context, m),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => site.deleteMinistry(m.id),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Future<void> _edit(BuildContext context, Ministry? existing) async {
    final result = await Navigator.of(context).push<Ministry>(
      MaterialPageRoute(
        builder: (_) => _MinistryForm(existing: existing),
        fullscreenDialog: true,
      ),
    );
    if (result != null && context.mounted) {
      context.read<SiteController>().upsertMinistry(result);
    }
  }
}

class _MinistryForm extends StatefulWidget {
  final Ministry? existing;

  const _MinistryForm({this.existing});

  @override
  State<_MinistryForm> createState() => _MinistryFormState();
}

class _MinistryFormState extends State<_MinistryForm> {
  late Ministry _draft;

  @override
  void initState() {
    super.initState();
    _draft = widget.existing ??
        Ministry(id: 'min-${DateTime.now().microsecondsSinceEpoch}', name: '');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            widget.existing == null ? 'Add ministry' : 'Edit ministry'),
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
            label: 'Leader',
            value: _draft.leader,
            onChanged: (v) =>
                setState(() => _draft = _draft.copyWith(leader: v)),
          ),
          AdminField(
            label: 'Description',
            value: _draft.description,
            maxLines: 4,
            onChanged: (v) =>
                setState(() => _draft = _draft.copyWith(description: v)),
          ),
          AdminField(
            label: 'Contact / info URL',
            value: _draft.contactUrl,
            hint: 'https://…',
            onChanged: (v) =>
                setState(() => _draft = _draft.copyWith(contactUrl: v)),
          ),
          const SizedBox(height: 8),
          Text('Icon', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final entry in ministryIcons.entries)
                InkWell(
                  onTap: () =>
                      setState(() => _draft = _draft.copyWith(icon: entry.key)),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _draft.icon == entry.key
                          ? Theme.of(context).colorScheme.primaryContainer
                          : Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(entry.value),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
