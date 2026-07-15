import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../models/sermon.dart';
import '../../../state/site_controller.dart';
import '../admin_widgets.dart';

class SermonsAdminScreen extends StatelessWidget {
  const SermonsAdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final site = context.watch<SiteController>();
    final sermons = site.sermonsByNewest;

    return Scaffold(
      appBar: AppBar(title: const Text('Messages')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _edit(context, null),
        icon: const Icon(Icons.add),
        label: const Text('Add message'),
      ),
      body: sermons.isEmpty
          ? const _Empty(text: 'No messages yet. Add your first sermon.')
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: sermons.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final s = sermons[i];
                return Card(
                  child: ListTile(
                    title: Text(s.title),
                    subtitle: Text(
                        '${s.speaker} · ${DateFormat('MMM d, yyyy').format(s.date)}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined),
                          onPressed: () => _edit(context, s),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => site.deleteSermon(s.id),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Future<void> _edit(BuildContext context, Sermon? existing) async {
    final result = await Navigator.of(context).push<Sermon>(
      MaterialPageRoute(
        builder: (_) => _SermonForm(existing: existing),
        fullscreenDialog: true,
      ),
    );
    if (result != null && context.mounted) {
      context.read<SiteController>().upsertSermon(result);
    }
  }
}

class _SermonForm extends StatefulWidget {
  final Sermon? existing;

  const _SermonForm({this.existing});

  @override
  State<_SermonForm> createState() => _SermonFormState();
}

class _SermonFormState extends State<_SermonForm> {
  late Sermon _draft;

  @override
  void initState() {
    super.initState();
    _draft = widget.existing ??
        Sermon(
          id: 'sm-${DateTime.now().microsecondsSinceEpoch}',
          title: '',
          speaker: '',
          date: DateTime.now(),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existing == null ? 'Add message' : 'Edit message'),
        actions: [
          TextButton(
            onPressed: _draft.title.trim().isEmpty
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
            label: 'Title',
            value: _draft.title,
            onChanged: (v) => setState(() => _draft = _draft.copyWith(title: v)),
          ),
          AdminField(
            label: 'Speaker',
            value: _draft.speaker,
            onChanged: (v) =>
                setState(() => _draft = _draft.copyWith(speaker: v)),
          ),
          AdminField(
            label: 'Series',
            value: _draft.series,
            onChanged: (v) =>
                setState(() => _draft = _draft.copyWith(series: v)),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.calendar_today_outlined),
            title: const Text('Date'),
            subtitle: Text(DateFormat('EEEE, MMM d, yyyy').format(_draft.date)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _draft.date,
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
              if (picked != null) {
                setState(() => _draft = _draft.copyWith(date: picked));
              }
            },
          ),
          const SizedBox(height: 8),
          AdminField(
            label: 'Scripture',
            value: _draft.scripture,
            onChanged: (v) =>
                setState(() => _draft = _draft.copyWith(scripture: v)),
          ),
          AdminField(
            label: 'Description',
            value: _draft.description,
            maxLines: 4,
            onChanged: (v) =>
                setState(() => _draft = _draft.copyWith(description: v)),
          ),
          AdminField(
            label: 'Media URL (video/audio)',
            value: _draft.mediaUrl,
            hint: 'https://…',
            onChanged: (v) =>
                setState(() => _draft = _draft.copyWith(mediaUrl: v)),
          ),
          AdminField(
            label: 'Thumbnail image URL',
            value: _draft.imageUrl,
            hint: 'https://…',
            onChanged: (v) =>
                setState(() => _draft = _draft.copyWith(imageUrl: v)),
          ),
        ],
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  final String text;

  const _Empty({required this.text});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(text,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant)),
      ),
    );
  }
}
