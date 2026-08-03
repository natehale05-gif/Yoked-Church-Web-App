import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../audit_log/application/audit_providers.dart';
import '../../devotionals/application/devotional_providers.dart';
import '../../devotionals/domain/devotional.dart';
import 'admin_header.dart';

class DevotionalsAdminScreen extends ConsumerWidget {
  const DevotionalsAdminScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Future<void> openForm({Devotional? existing}) async {
      final result = await showDialog<Devotional>(
        context: context,
        builder: (_) => _DevotionalForm(existing: existing),
      );
      if (result == null) return;
      final repo = ref.read(devotionalRepositoryProvider);
      if (existing == null) {
        await repo.create(result);
      } else {
        await repo.update(result);
      }
      ref.invalidate(allDevotionalsProvider);
    }

    final now = DateTime.now();

    return AdminListScaffold<Devotional>(
      title: 'Devotionals',
      subtitle: 'Write ahead of time - a future date stays hidden until that day.',
      value: ref.watch(allDevotionalsProvider),
      errorContext: 'devotionals',
      emptyMessage: 'No devotionals yet. Write the first one.',
      newLabel: 'New Devotional',
      maxWidth: 820,
      onNew: openForm,
      itemBuilder: (devotional) => AdminListTile(
        title: devotional.title,
        subtitle: [
          DateFormat.yMMMd().format(devotional.publishDate),
          if (devotional.scripture.isNotEmpty) devotional.scripture,
          if (devotional.author.isNotEmpty) devotional.author,
        ].join(' · '),
        deleteLabel: '"${devotional.title}"',
        actions: [_StatusChip(devotional: devotional, now: now)],
        onEdit: () => openForm(existing: devotional),
        onDelete: () async {
          await ref.read(devotionalRepositoryProvider).delete(devotional.id);
          await ref.read(auditLoggerProvider).record(
                action: 'deleted',
                entity: 'devotional',
                details: devotional.title,
              );
          ref.invalidate(allDevotionalsProvider);
        },
      ),
    );
  }
}

/// Three states, not two: a published devotional dated next Tuesday is
/// neither a draft nor live, and staff need to see that difference.
class _StatusChip extends ConsumerWidget {
  final Devotional devotional;
  final DateTime now;

  const _StatusChip({required this.devotional, required this.now});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheduled = devotional.published && devotional.publishDate.isAfter(now);
    final (label, icon, tooltip) = switch ((devotional.published, scheduled)) {
      (false, _) => ('Draft', Icons.visibility_off_outlined, 'Draft - hidden from visitors'),
      (true, true) => ('Scheduled', Icons.schedule, 'Goes live on ${DateFormat.yMMMd().format(devotional.publishDate)}'),
      (true, false) => ('Live', Icons.visibility, 'Live - visible to everyone'),
    };

    return Tooltip(
      message: tooltip,
      child: TextButton.icon(
        onPressed: () async {
          await ref.read(devotionalRepositoryProvider).update(
                devotional.copyWith(published: !devotional.published),
              );
          ref.invalidate(allDevotionalsProvider);
        },
        icon: Icon(icon, size: 16),
        label: Text(label),
      ),
    );
  }
}

class _DevotionalForm extends StatefulWidget {
  final Devotional? existing;

  const _DevotionalForm({this.existing});

  @override
  State<_DevotionalForm> createState() => _DevotionalFormState();
}

class _DevotionalFormState extends State<_DevotionalForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _body;
  late final TextEditingController _scripture;
  late final TextEditingController _author;
  late DateTime _publishDate;
  late bool _published;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _title = TextEditingController(text: e?.title ?? '');
    _body = TextEditingController(text: e?.body ?? '');
    _scripture = TextEditingController(text: e?.scripture ?? '');
    _author = TextEditingController(text: e?.author ?? '');
    _publishDate = e?.publishDate ?? DateTime.now();
    _published = e?.published ?? true;
  }

  @override
  void dispose() {
    for (final c in [_title, _body, _scripture, _author]) {
      c.dispose();
    }
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      Devotional(
        id: widget.existing?.id ?? '',
        title: _title.text.trim(),
        body: _body.text.trim(),
        scripture: _scripture.text.trim(),
        author: _author.text.trim(),
        publishDate: _publishDate,
        published: _published,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AdminFormDialog(
      title: widget.existing == null ? 'New Devotional' : 'Edit Devotional',
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
            TextFormField(
              controller: _scripture,
              decoration: const InputDecoration(labelText: 'Scripture', hintText: 'Psalm 23:1-3'),
            ),
            TextFormField(controller: _author, decoration: const InputDecoration(labelText: 'Author')),
            TextFormField(
              controller: _body,
              decoration: const InputDecoration(labelText: 'Devotional'),
              maxLines: 10,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('Publish date: ${DateFormat.yMMMd().format(_publishDate)}'),
              subtitle: const Text('A future date schedules it.'),
              trailing: TextButton(
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _publishDate,
                    firstDate: DateTime(2015),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) setState(() => _publishDate = picked);
                },
                child: const Text('Change'),
              ),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Published'),
              subtitle: const Text('Drafts stay hidden whatever their date.'),
              value: _published,
              onChanged: (v) => setState(() => _published = v),
            ),
          ],
        ),
      ),
    );
  }
}
