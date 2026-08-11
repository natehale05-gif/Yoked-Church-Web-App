import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../audit_log/application/audit_providers.dart';
import '../../sermons/application/sermon_providers.dart';
import '../../sermons/domain/sermon.dart';
import '../../sermons/domain/sermon_series.dart';
import 'admin_header.dart';

class SermonsAdminScreen extends ConsumerWidget {
  const SermonsAdminScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final seriesList = ref.watch(sermonSeriesProvider).valueOrNull ?? const <SermonSeries>[];

    Future<void> openForm({Sermon? existing}) async {
      final result = await showDialog<Sermon>(
        context: context,
        builder: (_) => _SermonForm(existing: existing, allSeries: seriesList),
      );
      if (result == null) return;
      final repo = ref.read(sermonRepositoryProvider);
      if (existing == null) {
        await repo.create(result);
      } else {
        await repo.update(result);
      }
      ref.invalidate(allSermonsProvider);
    }

    return AdminListScaffold<Sermon>(
      title: 'Sermons',
      subtitle: 'Add, edit, publish, or remove messages.',
      value: ref.watch(allSermonsProvider),
      errorContext: 'sermons',
      emptyMessage: 'No sermons yet. Add the first one.',
      newLabel: 'New Sermon',
      onNew: openForm,
      aboveList: const _SeriesManager(),
      itemBuilder: (sermon) => AdminListTile(
        title: sermon.title,
        subtitle: [
          if (sermon.seriesName.isNotEmpty) sermon.seriesName,
          sermon.speaker,
          DateFormat.yMMMd().format(sermon.date),
        ].where((s) => s.isNotEmpty).join(' · '),
        deleteLabel: '"${sermon.title}"',
        actions: [
          // Draft/published is what keeps an unfinished sermon - or a
          // future auto-imported livestream - off the public site.
          Tooltip(
            message: sermon.published ? 'Published - visible to everyone' : 'Draft - hidden from visitors',
            child: TextButton.icon(
              onPressed: () async {
                await ref.read(sermonRepositoryProvider).update(
                      sermon.copyWith(published: !sermon.published),
                    );
                ref.invalidate(allSermonsProvider);
              },
              icon: Icon(
                sermon.published ? Icons.visibility : Icons.visibility_off_outlined,
                size: 16,
              ),
              label: Text(sermon.published ? 'Published' : 'Draft'),
            ),
          ),
        ],
        onEdit: () => openForm(existing: sermon),
        onDelete: () async {
          await ref.read(sermonRepositoryProvider).delete(sermon.id);
          await ref.read(auditLoggerProvider).record(
                action: 'deleted',
                entity: 'sermon',
                details: sermon.title,
              );
          ref.invalidate(allSermonsProvider);
        },
      ),
    );
  }
}

/// Series live above the sermon list rather than on their own page - a
/// church has a handful of them and always manages them alongside sermons.
class _SeriesManager extends ConsumerWidget {
  const _SeriesManager();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final series = ref.watch(sermonSeriesProvider).valueOrNull ?? const <SermonSeries>[];

    Future<void> openForm({SermonSeries? existing}) async {
      final result = await showDialog<SermonSeries>(
        context: context,
        builder: (_) => _SeriesForm(existing: existing),
      );
      if (result == null) return;
      final repo = ref.read(sermonSeriesRepositoryProvider);
      if (existing == null) {
        await repo.create(result);
      } else {
        await repo.update(result);
      }
      ref.invalidate(sermonSeriesProvider);
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text('Series', style: Theme.of(context).textTheme.titleMedium)),
                TextButton.icon(
                  onPressed: openForm,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('New series'),
                ),
              ],
            ),
            if (series.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('No series yet.', style: TextStyle(color: Colors.black54)),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final s in series)
                    InputChip(
                      label: Text(s.name),
                      onPressed: () => openForm(existing: s),
                      onDeleted: () async {
                        if (!await confirmDelete(context, 'the series "${s.name}"')) return;
                        await ref.read(sermonSeriesRepositoryProvider).delete(s.id);
                        ref.invalidate(sermonSeriesProvider);
                      },
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _SermonForm extends StatefulWidget {
  final Sermon? existing;
  final List<SermonSeries> allSeries;

  const _SermonForm({this.existing, required this.allSeries});

  @override
  State<_SermonForm> createState() => _SermonFormState();
}

class _SermonFormState extends State<_SermonForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _speaker;
  late final TextEditingController _scripture;
  late final TextEditingController _videoUrl;
  late final TextEditingController _audioUrl;
  late final TextEditingController _thumbnailUrl;
  late final TextEditingController _description;
  late final TextEditingController _notes;
  late DateTime _date;
  String? _seriesId;
  late bool _published;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _title = TextEditingController(text: e?.title ?? '');
    _speaker = TextEditingController(text: e?.speaker ?? '');
    _scripture = TextEditingController(text: e?.scripture ?? '');
    _videoUrl = TextEditingController(text: e?.videoUrl ?? '');
    _audioUrl = TextEditingController(text: e?.audioUrl ?? '');
    _thumbnailUrl = TextEditingController(text: e?.thumbnailUrl ?? '');
    _description = TextEditingController(text: e?.description ?? '');
    _notes = TextEditingController(text: e?.notes ?? '');
    _date = e?.date ?? DateTime.now();
    _seriesId = (e?.seriesId.isNotEmpty ?? false) ? e!.seriesId : null;
    _published = e?.published ?? true;
  }

  @override
  void dispose() {
    for (final c in [_title, _speaker, _scripture, _videoUrl, _audioUrl, _thumbnailUrl, _description, _notes]) {
      c.dispose();
    }
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final series = widget.allSeries.where((s) => s.id == _seriesId);
    Navigator.pop(
      context,
      Sermon(
        id: widget.existing?.id ?? '',
        title: _title.text.trim(),
        speaker: _speaker.text.trim(),
        date: _date,
        seriesId: _seriesId ?? '',
        seriesName: series.isEmpty ? '' : series.first.name,
        scripture: _scripture.text.trim(),
        videoUrl: _videoUrl.text.trim(),
        audioUrl: _audioUrl.text.trim(),
        thumbnailUrl: _thumbnailUrl.text.trim(),
        description: _description.text.trim(),
        notes: _notes.text.trim(),
        source: widget.existing?.source ?? SermonSource.manual,
        published: _published,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AdminFormDialog(
      title: widget.existing == null ? 'New Sermon' : 'Edit Sermon',
      onSave: _save,
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
            TextFormField(controller: _speaker, decoration: const InputDecoration(labelText: 'Speaker')),
            TextFormField(
              controller: _scripture,
              decoration: const InputDecoration(labelText: 'Scripture', hintText: 'Matthew 11:28-30'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String?>(
              isExpanded: true,
              initialValue: _seriesId,
              decoration: const InputDecoration(labelText: 'Series'),
              items: [
                const DropdownMenuItem<String?>(value: null, child: Text('No series')),
                for (final s in widget.allSeries) DropdownMenuItem(value: s.id, child: Text(s.name)),
              ],
              onChanged: (value) => setState(() => _seriesId = value),
            ),
            const SizedBox(height: 8),
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
            TextFormField(controller: _videoUrl, decoration: const InputDecoration(labelText: 'Video URL')),
            TextFormField(controller: _audioUrl, decoration: const InputDecoration(labelText: 'Audio URL')),
            TextFormField(
              controller: _thumbnailUrl,
              decoration: const InputDecoration(labelText: 'Thumbnail URL'),
            ),
            TextFormField(
              controller: _description,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 3,
            ),
            TextFormField(
              controller: _notes,
              decoration: const InputDecoration(labelText: 'Sermon notes'),
              maxLines: 4,
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Published'),
              subtitle: const Text('Drafts stay hidden from the public sermon list.'),
              value: _published,
              onChanged: (v) => setState(() => _published = v),
            ),
          ],
        ),
      ),
    );
  }
}

class _SeriesForm extends StatefulWidget {
  final SermonSeries? existing;

  const _SeriesForm({this.existing});

  @override
  State<_SeriesForm> createState() => _SeriesFormState();
}

class _SeriesFormState extends State<_SeriesForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _description;
  late final TextEditingController _imageUrl;
  late DateTime _startDate;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.existing?.name ?? '');
    _description = TextEditingController(text: widget.existing?.description ?? '');
    _imageUrl = TextEditingController(text: widget.existing?.imageUrl ?? '');
    _startDate = widget.existing?.startDate ?? DateTime.now();
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _imageUrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AdminFormDialog(
      title: widget.existing == null ? 'New Series' : 'Edit Series',
      onSave: () {
        if (!_formKey.currentState!.validate()) return;
        Navigator.pop(
          context,
          SermonSeries(
            id: widget.existing?.id ?? '',
            name: _name.text.trim(),
            description: _description.text.trim(),
            imageUrl: _imageUrl.text.trim(),
            startDate: _startDate,
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
              controller: _name,
              decoration: const InputDecoration(labelText: 'Name'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            TextFormField(
              controller: _description,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 3,
            ),
            TextFormField(controller: _imageUrl, decoration: const InputDecoration(labelText: 'Image URL')),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('Starts: ${DateFormat.yMMMd().format(_startDate)}'),
              trailing: TextButton(
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _startDate,
                    firstDate: DateTime(2015),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) setState(() => _startDate = picked);
                },
                child: const Text('Change'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
