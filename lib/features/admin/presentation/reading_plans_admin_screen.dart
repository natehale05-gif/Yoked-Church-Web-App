import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../audit_log/application/audit_providers.dart';
import '../../reading_plans/application/reading_plan_providers.dart';
import '../../reading_plans/domain/reading_plan.dart';
import 'admin_header.dart';

class ReadingPlansAdminScreen extends ConsumerWidget {
  const ReadingPlansAdminScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Future<void> openForm({ReadingPlan? existing}) async {
      final result = await showDialog<ReadingPlan>(
        context: context,
        builder: (_) => _PlanForm(existing: existing),
      );
      if (result == null) return;
      final repo = ref.read(readingPlanRepositoryProvider);
      if (existing == null) {
        await repo.create(result);
      } else {
        await repo.update(result);
      }
      ref.invalidate(allReadingPlansProvider);
    }

    return AdminListScaffold<ReadingPlan>(
      title: 'Reading Plans',
      subtitle: 'Build a plan day by day. Members check days off as they read.',
      value: ref.watch(allReadingPlansProvider),
      errorContext: 'reading plans',
      emptyMessage: 'No reading plans yet. Build the first one.',
      newLabel: 'New Plan',
      maxWidth: 820,
      onNew: openForm,
      itemBuilder: (plan) => AdminListTile(
        title: plan.title,
        subtitle: '${plan.dayCount} days',
        deleteLabel: 'the plan "${plan.title}"',
        actions: [
          Tooltip(
            message: plan.published ? 'Published - visible to everyone' : 'Draft - hidden from members',
            child: TextButton.icon(
              onPressed: () async {
                await ref.read(readingPlanRepositoryProvider).update(
                      plan.copyWith(published: !plan.published),
                    );
                ref.invalidate(allReadingPlansProvider);
              },
              icon: Icon(plan.published ? Icons.visibility : Icons.visibility_off_outlined, size: 16),
              label: Text(plan.published ? 'Published' : 'Draft'),
            ),
          ),
        ],
        onEdit: () => openForm(existing: plan),
        onDelete: () async {
          await ref.read(readingPlanRepositoryProvider).delete(plan.id);
          await ref.read(auditLoggerProvider).record(
                action: 'deleted',
                entity: 'reading plan',
                details: plan.title,
              );
          ref.invalidate(allReadingPlansProvider);
        },
      ),
    );
  }
}

/// Editable row backing one [ReadingDay]. Holds its own controllers so
/// reordering the list doesn't shuffle text between fields.
class _DayDraft {
  final TextEditingController reference;
  final TextEditingController note;

  _DayDraft({String reference = '', String note = ''})
      : reference = TextEditingController(text: reference),
        note = TextEditingController(text: note);

  void dispose() {
    reference.dispose();
    note.dispose();
  }
}

class _PlanForm extends StatefulWidget {
  final ReadingPlan? existing;

  const _PlanForm({this.existing});

  @override
  State<_PlanForm> createState() => _PlanFormState();
}

class _PlanFormState extends State<_PlanForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _description;
  final _days = <_DayDraft>[];
  late bool _published;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _title = TextEditingController(text: e?.title ?? '');
    _description = TextEditingController(text: e?.description ?? '');
    _published = e?.published ?? true;
    for (final day in e?.days ?? const <ReadingDay>[]) {
      _days.add(_DayDraft(reference: day.reference, note: day.note));
    }
    if (_days.isEmpty) _days.add(_DayDraft());
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    for (final day in _days) {
      day.dispose();
    }
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    // Day numbers are assigned from position on save, so deleting day 3
    // renumbers the rest instead of leaving a hole.
    final days = <ReadingDay>[];
    for (var i = 0; i < _days.length; i++) {
      final reference = _days[i].reference.text.trim();
      if (reference.isEmpty) continue;
      days.add(ReadingDay(dayNumber: days.length + 1, reference: reference, note: _days[i].note.text.trim()));
    }

    Navigator.pop(
      context,
      ReadingPlan(
        id: widget.existing?.id ?? '',
        title: _title.text.trim(),
        description: _description.text.trim(),
        days: days,
        published: _published,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AdminFormDialog(
      title: widget.existing == null ? 'New Reading Plan' : 'Edit Reading Plan',
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
              controller: _description,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 3,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(child: Text('Days', style: Theme.of(context).textTheme.titleMedium)),
                Text('${_days.length}', style: const TextStyle(color: Colors.black54)),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'Days are numbered in order. An empty reading is skipped.',
              style: TextStyle(color: Colors.black54, fontSize: 12),
            ),
            const SizedBox(height: 8),
            for (var i = 0; i < _days.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: SizedBox(
                        width: 34,
                        child: Text('${i + 1}.', style: const TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _days[i].reference,
                            decoration: const InputDecoration(labelText: 'Reading', hintText: 'John 1:1-18'),
                          ),
                          TextFormField(
                            controller: _days[i].note,
                            decoration: const InputDecoration(labelText: 'Note (optional)'),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Remove day',
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: _days.length == 1
                          ? null
                          : () => setState(() => _days.removeAt(i).dispose()),
                    ),
                  ],
                ),
              ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => setState(() => _days.add(_DayDraft())),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add day'),
              ),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Published'),
              subtitle: const Text('Drafts stay hidden from members.'),
              value: _published,
              onChanged: (v) => setState(() => _published = v),
            ),
          ],
        ),
      ),
    );
  }
}
