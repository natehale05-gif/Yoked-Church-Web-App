import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/theme.dart';
import '../../../core/widgets/responsive.dart';
import '../../audit_log/application/audit_providers.dart';
import '../../auth/application/auth_providers.dart';
import '../../auth/domain/app_user.dart';
import '../../forms/application/form_providers.dart';
import '../../forms/domain/church_form.dart';
import '../../forms/domain/form_submission.dart';
import 'admin_header.dart';

class FormsAdminScreen extends ConsumerWidget {
  const FormsAdminScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final submissions = ref.watch(allSubmissionsProvider).valueOrNull ?? const <FormSubmission>[];

    Future<void> createForm() async {
      final controller = ref.read(formControllerProvider);
      final slug = await controller.uniqueSlug('New form');
      await controller.save(FormDefinition(title: 'New form', slug: slug));
      // Straight into the builder: a form with no questions is not
      // something anyone wants to look at in a list.
      final created = await ref.read(formRepositoryProvider).bySlug(slug);
      if (created != null && context.mounted) context.go('/admin/forms/${created.id}');
    }

    return AdminListScaffold<FormDefinition>(
      title: 'Forms',
      subtitle: 'Build a sign-up, publish it, and collect the answers.',
      value: ref.watch(formsProvider),
      errorContext: 'forms',
      emptyMessage: 'No forms yet. Build the first one.',
      newLabel: 'New Form',
      onNew: createForm,
      itemBuilder: (form) {
        final count = submissions.where((s) => s.formId == form.id).length;

        return AdminListTile(
          title: form.title,
          subtitle: [
            if (!form.published) 'draft' else '/forms/${form.slug}',
            if (form.membersOnly) 'members only',
            if (form.closesAt != null)
              form.hasClosed
                  ? 'closed ${DateFormat.yMMMd().format(form.closesAt!)}'
                  : 'closes ${DateFormat.yMMMd().format(form.closesAt!)}',
            '${form.fields.length} question${form.fields.length == 1 ? '' : 's'}',
            '$count response${count == 1 ? '' : 's'}',
          ].join(' · '),
          deleteLabel: 'the form "${form.title}"',
          actions: [
            Badge(
              isLabelVisible: count > 0,
              label: Text('$count'),
              child: TextButton(
                onPressed: () => context.go('/admin/forms/${form.id}/responses'),
                child: const Text('Responses'),
              ),
            ),
            if (form.published)
              TextButton(
                onPressed: () => context.go('/forms/${form.slug}'),
                child: const Text('View'),
              ),
          ],
          onEdit: () => context.go('/admin/forms/${form.id}'),
          onDelete: () async {
            await ref.read(formControllerProvider).deleteForm(form.id);
            await ref.read(auditLoggerProvider).record(
                  action: 'deleted',
                  entity: 'form',
                  details: form.title,
                );
          },
        );
      },
    );
  }
}

/// The builder. A route rather than a dialog: a real registration form
/// has fifteen questions, pages, and branches, and none of that fits in a
/// modal without becoming a scroll box inside a scroll box.
class FormBuilderScreen extends ConsumerStatefulWidget {
  final String formId;

  const FormBuilderScreen({super.key, required this.formId});

  @override
  ConsumerState<FormBuilderScreen> createState() => _FormBuilderScreenState();
}

class _FormBuilderScreenState extends ConsumerState<FormBuilderScreen> {
  FormDefinition? _draft;
  String? _loadedId;
  bool _dirty = false;
  bool _saving = false;

  final _title = TextEditingController();
  final _description = TextEditingController();
  final _confirmation = TextEditingController();

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  void _adopt(FormDefinition form) {
    _loadedId = form.id;
    _draft = form;
    _title.text = form.title;
    _description.text = form.description;
    _confirmation.text = form.confirmationMessage;
  }

  void _edit(FormDefinition Function(FormDefinition) change) {
    setState(() {
      _draft = change(_draft!);
      _dirty = true;
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final controller = ref.read(formControllerProvider);
    final draft = _draft!.copyWith(
      title: _title.text.trim().isEmpty ? 'Untitled form' : _title.text.trim(),
      description: _description.text.trim(),
      confirmationMessage: _confirmation.text.trim(),
    );
    // The slug is the public URL, so it is re-derived from the title only
    // while the form is still a draft. Renaming a published form must not
    // break links already printed in a bulletin.
    final slug = draft.published
        ? draft.slug
        : await controller.uniqueSlug(draft.title, exceptId: draft.id);
    await controller.save(draft.copyWith(slug: slug));
    if (!mounted) return;
    setState(() {
      _draft = draft.copyWith(slug: slug);
      _dirty = false;
      _saving = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final forms = ref.watch(formsProvider).valueOrNull ?? const <FormDefinition>[];
    final stored = forms.where((f) => f.id == widget.formId).firstOrNull;

    if (stored == null) {
      return AdminListScaffold<FormDefinition>(
        title: 'Form',
        value: const AsyncValue.data([]),
        emptyMessage: 'That form no longer exists.',
        itemBuilder: (_) => const SizedBox.shrink(),
      );
    }
    if (_loadedId != stored.id) _adopt(stored);
    final draft = _draft!;

    return AdminListScaffold<FormFieldDef>(
      title: draft.title.isEmpty ? 'Untitled form' : draft.title,
      subtitle: draft.published ? 'Live at /forms/${draft.slug}' : 'Draft - not visible to anyone yet',
      value: AsyncValue.data(draft.fields),
      errorContext: 'this form',
      emptyMessage: 'No questions yet. Add the first one.',
      newLabel: 'Add question',
      onNew: () => _openFieldForm(),
      maxWidth: 860,
      aboveList: _Settings(
        draft: draft,
        title: _title,
        description: _description,
        confirmation: _confirmation,
        dirty: _dirty,
        saving: _saving,
        onChanged: _edit,
        onTouched: () => setState(() => _dirty = true),
        onSave: _save,
      ),
      itemBuilder: (field) => _FieldRow(
        field: field,
        form: draft,
        onEdit: () => _openFieldForm(existing: field),
        onDelete: () => _removeField(field),
        onMove: (delta) => _moveField(field, delta),
      ),
    );
  }

  void _removeField(FormFieldDef field) {
    _edit((d) {
      final fields = [...d.fields]..removeWhere((f) => f.id == field.id);
      // Any branch hanging off the deleted question loses its condition
      // rather than being orphaned into permanent invisibility.
      return d.copyWith(
        fields: [
          for (final f in fields)
            f.showIf?.fieldId == field.id ? f.copyWith(clearCondition: true) : f,
        ],
      );
    });
  }

  void _moveField(FormFieldDef field, int delta) {
    _edit((d) {
      final fields = [...d.fields];
      final index = fields.indexWhere((f) => f.id == field.id);
      final target = index + delta;
      if (index < 0 || target < 0 || target >= fields.length) return d;
      fields.insert(target, fields.removeAt(index));
      return d.copyWith(fields: fields);
    });
  }

  Future<void> _openFieldForm({FormFieldDef? existing}) async {
    final draft = _draft!;
    final result = await showDialog<FormFieldDef>(
      context: context,
      builder: (_) => _FieldForm(existing: existing, form: draft),
    );
    if (result == null) return;

    _edit((d) {
      final fields = [...d.fields];
      final index = fields.indexWhere((f) => f.id == result.id);
      if (index >= 0) {
        fields[index] = result;
      } else {
        fields.add(result);
      }
      return d.copyWith(fields: fields);
    });
  }
}

class _Settings extends ConsumerWidget {
  final FormDefinition draft;
  final TextEditingController title;
  final TextEditingController description;
  final TextEditingController confirmation;
  final bool dirty;
  final bool saving;
  final void Function(FormDefinition Function(FormDefinition)) onChanged;
  final VoidCallback onTouched;
  final VoidCallback onSave;

  const _Settings({
    required this.draft,
    required this.title,
    required this.description,
    required this.confirmation,
    required this.dirty,
    required this.saving,
    required this.onChanged,
    required this.onTouched,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: title,
              decoration: const InputDecoration(labelText: 'Form title'),
              onChanged: (_) => onTouched(),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: description,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Description'),
              onChanged: (_) => onTouched(),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: confirmation,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Thank-you message',
                hintText: "We'll email you the week before camp.",
              ),
              onChanged: (_) => onTouched(),
            ),
            const SizedBox(height: 8),
            // Two switches with subtitles need more width than half a
            // phone: side by side, the labels wrap to four lines each.
            ResponsiveRow(
              spacing: 8,
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  title: const Text('Published'),
                  subtitle: Text(
                    draft.published ? '/forms/${draft.slug}' : 'Nobody can open it yet',
                    style: const TextStyle(fontSize: 12),
                  ),
                  value: draft.published,
                  onChanged: (v) => onChanged((d) => d.copyWith(published: v)),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  title: const Text('Members only'),
                  subtitle: const Text('Requires a sign-in', style: TextStyle(fontSize: 12)),
                  value: draft.membersOnly,
                  onChanged: (v) => onChanged((d) => d.copyWith(membersOnly: v)),
                ),
              ],
            ),
            // The deadline picker and the save button get a line each on
            // a phone; the clear button stays beside the date it clears.
            ResponsiveRow(
              crossAxisAlignment: CrossAxisAlignment.center,
              flex: const [3, 2],
              children: [
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: draft.closesAt ?? DateTime.now().add(const Duration(days: 14)),
                            firstDate: DateTime(DateTime.now().year - 1),
                            lastDate: DateTime(DateTime.now().year + 5),
                          );
                          if (picked != null) {
                            // End of the chosen day: a form that "closes
                            // on the 14th" is open all of the 14th, which
                            // is what anyone reading that sentence expects.
                            onChanged((d) => d.copyWith(
                                  closesAt:
                                      DateTime(picked.year, picked.month, picked.day, 23, 59, 59),
                                ));
                          }
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(labelText: 'Closes'),
                          child: Text(
                            draft.closesAt == null
                                ? 'No deadline'
                                : DateFormat.yMMMd().format(draft.closesAt!),
                          ),
                        ),
                      ),
                    ),
                    if (draft.closesAt != null)
                      IconButton(
                        tooltip: 'Remove the deadline',
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () => onChanged((d) => d.copyWith(clearClosesAt: true)),
                      ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: saving ? null : onSave,
                  icon: const Icon(Icons.save_outlined, size: 18),
                  label: Text(dirty ? 'Save changes' : 'Saved'),
                ),
              ],
            ),
            if (draft.published)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'The link stays fixed once a form is published, so renaming '
                  'it will not break anything already printed.',
                  style: TextStyle(color: Colors.black54, fontSize: 12),
                ),
              ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            const Text('Tell someone when a response arrives',
                style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            _NotifyPicker(draft: draft, onChanged: onChanged),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: () => context.go('/admin/forms/${draft.id}/responses'),
                icon: const Icon(Icons.inbox_outlined, size: 16),
                label: const Text('See responses'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FieldRow extends StatelessWidget {
  final FormFieldDef field;
  final FormDefinition form;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final void Function(int delta) onMove;

  const _FieldRow({
    required this.field,
    required this.form,
    required this.onEdit,
    required this.onDelete,
    required this.onMove,
  });

  @override
  Widget build(BuildContext context) {
    final condition = field.showIf;
    final controller = condition == null
        ? null
        : form.fields.where((f) => f.id == condition.fieldId).firstOrNull;

    // Four controls in a `ListTile.trailing` do not fit a phone, so below
    // the breakpoint they move under the question text - same shape as
    // `AdminListTile`.
    final controls = <Widget>[
      IconButton(
        icon: const Icon(Icons.arrow_upward, size: 18),
        tooltip: 'Move up',
        onPressed: () => onMove(-1),
      ),
      IconButton(
        icon: const Icon(Icons.arrow_downward, size: 18),
        tooltip: 'Move down',
        onPressed: () => onMove(1),
      ),
      IconButton(icon: const Icon(Icons.edit_outlined), tooltip: 'Edit', onPressed: onEdit),
      IconButton(
        icon: const Icon(Icons.delete_outline),
        tooltip: 'Delete',
        onPressed: () async {
          if (await confirmDelete(context, 'the question "${field.label}"')) onDelete();
        },
      ),
    ];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        isThreeLine: Breakpoints.isMobile(context),
        title: Text(
          field.label.isEmpty ? '(untitled question)' : field.label,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        trailing: Breakpoints.isMobile(context)
            ? null
            : Row(mainAxisSize: MainAxisSize.min, children: controls),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text([
              field.type.label,
              if (field.required) 'required',
              if (form.pageCount > 1) 'page ${field.page + 1}',
              if (field.options.isNotEmpty) '${field.options.length} options',
            ].join(' · ')),
            if (condition != null)
              Text(
                controller == null
                    ? 'Condition points at a question that no longer exists - always shown.'
                    : 'Only if "${controller.label}" is "${condition.equals}"',
                style: TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: controller == null ? Theme.of(context).colorScheme.error : Colors.black54,
                ),
              ),
            if (Breakpoints.isMobile(context))
              Align(
                alignment: Alignment.centerRight,
                child: Wrap(alignment: WrapAlignment.end, children: controls),
              ),
          ],
        ),
      ),
    );
  }
}

class _FieldForm extends StatefulWidget {
  final FormFieldDef? existing;
  final FormDefinition form;

  const _FieldForm({this.existing, required this.form});

  @override
  State<_FieldForm> createState() => _FieldFormState();
}

class _FieldFormState extends State<_FieldForm> {
  late final TextEditingController _label;
  late final TextEditingController _help;
  late final TextEditingController _options;
  late FormFieldType _type;
  late bool _required;
  late int _page;
  String _conditionField = '';
  String _conditionValue = '';

  /// Only questions *above* this one can drive it. Evaluation runs in
  /// field order, so a condition pointing forward could never be
  /// satisfied - better to make that impossible than to explain it.
  List<FormFieldDef> get _candidates {
    final fields = widget.form.fields;
    final index = widget.existing == null
        ? fields.length
        : fields.indexWhere((f) => f.id == widget.existing!.id);
    return fields.take(index < 0 ? fields.length : index).where((f) => f.options.isNotEmpty).toList();
  }

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _label = TextEditingController(text: e?.label ?? '');
    _help = TextEditingController(text: e?.helpText ?? '');
    _options = TextEditingController(text: (e?.options ?? const []).join('\n'));
    _type = e?.type ?? FormFieldType.shortText;
    _required = e?.required ?? false;
    _page = e?.page ?? 0;
    _conditionField = e?.showIf?.fieldId ?? '';
    _conditionValue = e?.showIf?.equals ?? '';
  }

  @override
  void dispose() {
    _label.dispose();
    _help.dispose();
    _options.dispose();
    super.dispose();
  }

  List<String> get _optionList =>
      _options.text.split('\n').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();

  @override
  Widget build(BuildContext context) {
    final candidates = _candidates;
    final controller = candidates.where((f) => f.id == _conditionField).firstOrNull;

    return AdminFormDialog(
      title: widget.existing == null ? 'New question' : 'Edit question',
      onSave: () {
        final id = widget.existing?.id ?? newFieldId(widget.form.fields.map((f) => f.id));
        Navigator.pop(
          context,
          FormFieldDef(
            id: id,
            label: _label.text.trim(),
            type: _type,
            required: _required,
            options: _type.hasOptions ? _optionList : const [],
            helpText: _help.text.trim(),
            page: _page,
            showIf: _conditionField.isEmpty || _conditionValue.isEmpty
                ? null
                : FieldCondition(fieldId: _conditionField, equals: _conditionValue),
          ),
        );
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(controller: _label, decoration: const InputDecoration(labelText: 'Question')),
          const SizedBox(height: 12),
          DropdownButtonFormField<FormFieldType>(
            isExpanded: true,
            initialValue: _type,
            decoration: const InputDecoration(labelText: 'Answer type'),
            items: [
              for (final t in FormFieldType.values) DropdownMenuItem(value: t, child: Text(t.label)),
            ],
            onChanged: (v) => setState(() => _type = v ?? FormFieldType.shortText),
          ),
          if (_type.hasOptions) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _options,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Options',
                helperText: 'One per line.',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ],
          const SizedBox(height: 12),
          TextField(
            controller: _help,
            decoration: const InputDecoration(labelText: 'Help text (optional)'),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            isExpanded: true,
            initialValue: _page,
            decoration: const InputDecoration(labelText: 'Page'),
            items: [
              for (var p = 0; p < widget.form.pageCount + 1; p++)
                DropdownMenuItem(
                  value: p,
                  child: Text(p == widget.form.pageCount ? 'Page ${p + 1} (new)' : 'Page ${p + 1}'),
                ),
            ],
            onChanged: (v) => setState(() => _page = v ?? 0),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Required'),
            subtitle: const Text(
              'Only enforced while the question is visible.',
              style: TextStyle(fontSize: 12),
            ),
            value: _required,
            onChanged: (v) => setState(() => _required = v),
          ),
          const Divider(),
          const SizedBox(height: 8),
          const Text('Show this question only when…', style: TextStyle(fontWeight: FontWeight.w700)),
          if (candidates.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Add a dropdown or choose-one question above this one to '
                'branch off it.',
                style: TextStyle(color: Colors.black54, fontSize: 12),
              ),
            )
          else ...[
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: candidates.any((f) => f.id == _conditionField) ? _conditionField : '',
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Question'),
              items: [
                const DropdownMenuItem(value: '', child: Text('Always show')),
                for (final f in candidates) DropdownMenuItem(value: f.id, child: Text(f.label)),
              ],
              onChanged: (v) => setState(() {
                _conditionField = v ?? '';
                _conditionValue = '';
              }),
            ),
            if (controller != null) ...[
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: controller.options.contains(_conditionValue) ? _conditionValue : null,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'is'),
                items: [
                  for (final o in controller.options) DropdownMenuItem(value: o, child: Text(o)),
                ],
                onChanged: (v) => setState(() => _conditionValue = v ?? ''),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

/// Which staff get an in-app notification per response.
///
/// Deliberately a pick from real accounts rather than a list of typed
/// email addresses: this app can deliver to an inbox it owns, and cannot
/// send mail. Offering an email box would promise something that never
/// arrives.
class _NotifyPicker extends ConsumerWidget {
  final FormDefinition draft;
  final void Function(FormDefinition Function(FormDefinition)) onChanged;

  const _NotifyPicker({required this.draft, required this.onChanged});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final staff = (ref.watch(allMembersProvider).valueOrNull ?? const <AppUser>[])
        .where((m) => m.isStaff)
        .toList();

    if (staff.isEmpty) {
      return const Text(
        'No staff accounts yet, so there is nobody to notify.',
        style: TextStyle(color: Colors.black54, fontSize: 12),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        for (final member in staff)
          FilterChip(
            label: Text(member.displayName.isEmpty ? member.email : member.displayName),
            selected: draft.notifyUids.contains(member.uid),
            onSelected: (on) => onChanged((d) => d.copyWith(
                  notifyUids: on
                      ? [...d.notifyUids, member.uid]
                      : d.notifyUids.where((uid) => uid != member.uid).toList(),
                )),
          ),
      ],
    );
  }
}
