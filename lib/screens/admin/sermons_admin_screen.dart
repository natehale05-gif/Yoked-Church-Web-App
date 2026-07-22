import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/sermon.dart';
import '../../services/sermon_service.dart';
import '../../widgets/admin_header.dart';
import '../../widgets/section_container.dart';

class SermonsAdminScreen extends StatefulWidget {
  const SermonsAdminScreen({super.key});

  @override
  State<SermonsAdminScreen> createState() => _SermonsAdminScreenState();
}

class _SermonsAdminScreenState extends State<SermonsAdminScreen> {
  final SermonService _service = const SermonService();
  late Future<List<Sermon>> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.fetchSermons();
  }

  void _refresh() => setState(() => _future = _service.fetchSermons());

  Future<void> _openForm({Sermon? existing}) async {
    final result = await showDialog<Sermon>(
      context: context,
      builder: (context) => _SermonFormDialog(existing: existing),
    );
    if (result == null) return;
    if (existing == null) {
      await _service.createSermon(result);
    } else {
      await _service.updateSermon(result);
    }
    _refresh();
  }

  Future<void> _delete(Sermon sermon) async {
    await _service.deleteSermon(sermon.id);
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const AdminHeader(title: 'Sermons', subtitle: 'Add, edit, or remove sermons from the library.'),
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
                  label: const Text('New Sermon'),
                ),
              ),
              const SizedBox(height: 16),
              FutureBuilder<List<Sermon>>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 60),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  final sermons = snapshot.data ?? [];
                  if (sermons.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 60),
                      child: Center(child: Text('No sermons yet.')),
                    );
                  }
                  return Column(
                    children: sermons.map((sermon) {
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          title: Text(sermon.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                          subtitle: Text(
                              '${sermon.series} · ${sermon.speaker} · ${DateFormat.yMMMd().format(sermon.date)}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined),
                                onPressed: () => _openForm(existing: sermon),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () => _delete(sermon),
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

class _SermonFormDialog extends StatefulWidget {
  final Sermon? existing;

  const _SermonFormDialog({this.existing});

  @override
  State<_SermonFormDialog> createState() => _SermonFormDialogState();
}

class _SermonFormDialogState extends State<_SermonFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _speaker;
  late final TextEditingController _series;
  late final TextEditingController _videoUrl;
  late final TextEditingController _thumbnailUrl;
  late final TextEditingController _description;
  late DateTime _date;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _title = TextEditingController(text: e?.title ?? '');
    _speaker = TextEditingController(text: e?.speaker ?? '');
    _series = TextEditingController(text: e?.series ?? '');
    _videoUrl = TextEditingController(text: e?.videoUrl ?? '');
    _thumbnailUrl = TextEditingController(text: e?.thumbnailUrl ?? '');
    _description = TextEditingController(text: e?.description ?? '');
    _date = e?.date ?? DateTime.now();
  }

  @override
  void dispose() {
    _title.dispose();
    _speaker.dispose();
    _series.dispose();
    _videoUrl.dispose();
    _thumbnailUrl.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2015),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _date = picked);
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(Sermon(
      id: widget.existing?.id ?? '',
      title: _title.text.trim(),
      speaker: _speaker.text.trim(),
      date: _date,
      series: _series.text.trim(),
      videoUrl: _videoUrl.text.trim(),
      thumbnailUrl: _thumbnailUrl.text.trim(),
      description: _description.text.trim(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existing == null ? 'New Sermon' : 'Edit Sermon'),
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
                TextFormField(controller: _speaker, decoration: const InputDecoration(labelText: 'Speaker')),
                TextFormField(controller: _series, decoration: const InputDecoration(labelText: 'Series')),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Date: ${DateFormat.yMMMd().format(_date)}'),
                  trailing: TextButton(onPressed: _pickDate, child: const Text('Change')),
                ),
                TextFormField(
                  controller: _videoUrl,
                  decoration: const InputDecoration(labelText: 'Video URL'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                TextFormField(controller: _thumbnailUrl, decoration: const InputDecoration(labelText: 'Thumbnail URL (optional)')),
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
