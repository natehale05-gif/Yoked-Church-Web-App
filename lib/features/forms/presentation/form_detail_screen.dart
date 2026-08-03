import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/config/settings_providers.dart';
import '../../../core/storage/file_storage.dart';
import '../../../core/widgets/app_shell.dart';
import '../../../core/widgets/async_value_widget.dart';
import '../../../core/widgets/section_container.dart';
import '../../auth/application/auth_providers.dart';
import '../application/form_providers.dart';
import '../domain/church_form.dart';

class FormDetailScreen extends ConsumerWidget {
  final String slug;

  const FormDetailScreen({super.key, required this.slug});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AsyncValueWidget<FormDefinition?>(
      value: ref.watch(formBySlugProvider(slug)),
      errorContext: 'this form',
      data: (form) {
        if (form == null) return const _Unavailable(message: "We couldn't find that form.");
        // A draft or members-only form is not browsable by URL. The
        // wording is deliberately the same either way: whether a private
        // form exists is itself information.
        if (!form.published || (form.membersOnly && !ref.watch(isSignedInProvider))) {
          return const _Unavailable(message: "That form isn't available.");
        }
        return _FormRunner(form: form);
      },
    );
  }
}

class _Unavailable extends StatelessWidget {
  final String message;

  const _Unavailable({required this.message});

  @override
  Widget build(BuildContext context) {
    return PageBody(
      children: [
        SectionContainer(
          maxWidth: 620,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(message, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 20),
              ElevatedButton(onPressed: () => context.go('/forms'), child: const Text('All forms')),
            ],
          ),
        ),
      ],
    );
  }
}

class _FormRunner extends ConsumerStatefulWidget {
  final FormDefinition form;

  const _FormRunner({required this.form});

  @override
  ConsumerState<_FormRunner> createState() => _FormRunnerState();
}

class _FormRunnerState extends ConsumerState<_FormRunner> {
  final Map<String, String> _answers = {};
  final _name = TextEditingController();
  final _email = TextEditingController();
  int _page = 0;
  bool _submitted = false;
  bool _busy = false;
  String? _error;
  Set<String> _flagged = {};

  FormDefinition get form => widget.form;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    super.dispose();
  }

  void _set(String fieldId, String value) {
    setState(() {
      _answers[fieldId] = value;
      // A field that just became invalid stays flagged until it is
      // answered, but answering it clears the mark immediately rather
      // than waiting for another failed submit.
      _flagged = _flagged.where((id) => id != fieldId || value.trim().isEmpty).toSet();
    });
  }

  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _error = null;
    });

    final failure = await ref.read(formControllerProvider).submit(
          form: form,
          answers: _answers,
          submitterName: _name.text,
          submitterEmail: _email.text,
        );
    if (!mounted) return;

    setState(() {
      _busy = false;
      switch (failure) {
        case null:
          _submitted = true;
        case FormClosed(closedAt: final at):
          _error = at == null
              ? 'This form is no longer accepting responses.'
              : 'This form closed on ${DateFormat.yMMMd().format(at)}.';
        case FormNotAcceptingSubmissions():
          _error = 'This form is no longer accepting responses.';
        case MissingAnswers(fields: final fields):
          _flagged = fields.map((f) => f.id).toSet();
          // Jump to the first page that still needs something, so the
          // member isn't told "something's missing" about a page they
          // cannot see.
          _page = fields.map((f) => f.page).reduce((a, b) => a < b ? a : b);
          _error = fields.length == 1
              ? '"${fields.first.label}" is required.'
              : '${fields.length} required questions still need an answer.';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final brand = ref.watch(settingsProvider).colors;

    if (_submitted) {
      return PageBody(
        children: [
          PageBanner(eyebrow: 'Forms', title: form.title),
          SectionContainer(
            maxWidth: 640,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.check_circle_outline, color: Colors.green, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text('Thank you.', style: Theme.of(context).textTheme.headlineSmall),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  form.confirmationMessage.isEmpty
                      ? "We've got your response."
                      : form.confirmationMessage,
                  style: const TextStyle(height: 1.6),
                ),
                const SizedBox(height: 24),
                ElevatedButton(onPressed: () => context.go('/'), child: const Text('Back home')),
              ],
            ),
          ),
        ],
      );
    }

    final visible = form.visibleFields(_answers);
    final pages = {for (final f in visible) f.page}.toList()..sort();
    final effectivePages = pages.isEmpty ? [0] : pages;
    final pageIndex = effectivePages.contains(_page) ? effectivePages.indexOf(_page) : 0;
    final currentPage = effectivePages[pageIndex];
    final onLastPage = pageIndex == effectivePages.length - 1;
    final fieldsHere = visible.where((f) => f.page == currentPage).toList();

    return PageBody(
      children: [
        PageBanner(eyebrow: 'Forms', title: form.title, subtitle: form.description),
        SectionContainer(
          maxWidth: 640,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (form.closesAt != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    'Closes ${DateFormat.yMMMMd().format(form.closesAt!)}',
                    style: const TextStyle(color: Colors.black54),
                  ),
                ),
              if (effectivePages.length > 1) ...[
                Text(
                  'Step ${pageIndex + 1} of ${effectivePages.length}',
                  style: TextStyle(color: brand.primary, fontWeight: FontWeight.w700, fontSize: 12),
                ),
                const SizedBox(height: 6),
                LinearProgressIndicator(value: (pageIndex + 1) / effectivePages.length),
                const SizedBox(height: 20),
              ],
              for (final field in fieldsHere)
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: _FieldInput(
                    // Without this, Flutter reuses one field's State for
                    // whatever question lands in the same slot on the
                    // next page - and the text controller carries the
                    // previous answer across with it.
                    key: ValueKey(field.id),
                    formId: form.id,
                    field: field,
                    value: _answers[field.id] ?? '',
                    flagged: _flagged.contains(field.id),
                    onChanged: (v) => _set(field.id, v),
                  ),
                ),
              if (onLastPage && !ref.watch(isSignedInProvider)) ...[
                const Divider(),
                const SizedBox(height: 12),
                const Text(
                  'So we can get back to you',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _name,
                  decoration: const InputDecoration(labelText: 'Your name', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _email,
                  decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 20),
              ],
              if (_error != null)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.error.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                ),
              Row(
                children: [
                  if (pageIndex > 0)
                    OutlinedButton(
                      onPressed: () => setState(() => _page = effectivePages[pageIndex - 1]),
                      child: const Text('Back'),
                    ),
                  const Spacer(),
                  if (!onLastPage)
                    ElevatedButton(
                      onPressed: () => setState(() => _page = effectivePages[pageIndex + 1]),
                      child: const Text('Next'),
                    )
                  else
                    ElevatedButton(
                      onPressed: _busy ? null : _submit,
                      child: _busy
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Submit'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// One question. Deliberately a plain widget over a shared string value
/// rather than a `Form`/`TextFormField` tree: the schema is data, the
/// answers are one map, and validation lives in the domain where the
/// conditional rules already are.
class _FieldInput extends StatefulWidget {
  final String formId;
  final FormFieldDef field;
  final String value;
  final bool flagged;
  final ValueChanged<String> onChanged;

  const _FieldInput({
    super.key,
    required this.formId,
    required this.field,
    required this.value,
    required this.flagged,
    required this.onChanged,
  });

  @override
  State<_FieldInput> createState() => _FieldInputState();
}

class _FieldInputState extends State<_FieldInput> {
  /// Held across rebuilds. Rebuilding a `TextEditingController` from the
  /// answer on every keystroke would send the caret back to position
  /// zero, which makes a long-answer box unusable.
  late final TextEditingController _text = TextEditingController(text: widget.value);

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final field = widget.field;
    final value = widget.value;
    final flagged = widget.flagged;
    final onChanged = widget.onChanged;
    final label = field.required ? '${field.label} *' : field.label;
    final border = flagged
        ? OutlineInputBorder(borderSide: BorderSide(color: Theme.of(context).colorScheme.error))
        : const OutlineInputBorder();
    final decoration = InputDecoration(
      labelText: label,
      helperText: field.helpText.isEmpty ? null : field.helpText,
      helperMaxLines: 3,
      border: border,
      enabledBorder: border,
    );

    switch (field.type) {
      case FormFieldType.longText:
        return TextField(
          decoration: decoration,
          maxLines: 4,
          controller: _text,
          onChanged: onChanged,
        );
      case FormFieldType.checkbox:
        return CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          title: Text(label),
          subtitle: field.helpText.isEmpty ? null : Text(field.helpText),
          // Stored as a string like every other answer, so one CSV column
          // and one Firestore shape covers every field type.
          value: value == 'true',
          onChanged: (v) => onChanged(v == true ? 'true' : ''),
        );
      case FormFieldType.dropdown:
        return DropdownButtonFormField<String>(
          initialValue: field.options.contains(value) ? value : null,
          isExpanded: true,
          decoration: decoration,
          items: [for (final o in field.options) DropdownMenuItem(value: o, child: Text(o))],
          onChanged: (v) => onChanged(v ?? ''),
        );
      case FormFieldType.radio:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
            if (field.helpText.isNotEmpty)
              Text(field.helpText, style: const TextStyle(color: Colors.black54, fontSize: 12)),
            for (final option in field.options)
              RadioListTile<String>(
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: Text(option),
                value: option,
                // ignore: deprecated_member_use
                groupValue: value,
                // ignore: deprecated_member_use
                onChanged: (v) => onChanged(v ?? ''),
              ),
          ],
        );
      case FormFieldType.date:
        return InkWell(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: DateTime.tryParse(value) ?? DateTime.now(),
              firstDate: DateTime(1920),
              lastDate: DateTime(DateTime.now().year + 5),
            );
            if (picked != null) onChanged(picked.toIso8601String());
          },
          child: InputDecorator(
            decoration: decoration,
            child: Text(
              value.isEmpty ? '—' : DateFormat.yMMMd().format(DateTime.parse(value)),
            ),
          ),
        );
      case FormFieldType.file:
        return _FileAnswer(
          formId: widget.formId,
          decoration: decoration,
          value: value,
          controller: _text,
          onChanged: onChanged,
        );
      case FormFieldType.shortText:
      case FormFieldType.email:
      case FormFieldType.phone:
      case FormFieldType.number:
        return TextField(
          decoration: decoration,
          keyboardType: switch (field.type) {
            FormFieldType.email => TextInputType.emailAddress,
            FormFieldType.phone => TextInputType.phone,
            FormFieldType.number => TextInputType.number,
            _ => TextInputType.text,
          },
          controller: _text,
          onChanged: onChanged,
        );
    }
  }
}

/// A file question. Uploads through the [FileStorage] seam when the
/// church has one, and falls back to a pasted link when it does not -
/// the same "say so up front" contract the resource library uses, rather
/// than a button that fails at the tap.
class _FileAnswer extends ConsumerStatefulWidget {
  final String formId;
  final InputDecoration decoration;
  final String value;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _FileAnswer({
    required this.formId,
    required this.decoration,
    required this.value,
    required this.controller,
    required this.onChanged,
  });

  @override
  ConsumerState<_FileAnswer> createState() => _FileAnswerState();
}

class _FileAnswerState extends ConsumerState<_FileAnswer> {
  bool _uploading = false;
  String? _error;
  String _fileName = '';

  Future<void> _pick() async {
    // withData, because on web there is no path to read from later.
    final picked = await FilePicker.pickFiles(withData: true);
    final file = picked?.files.singleOrNull;
    final bytes = file?.bytes;
    if (file == null || bytes == null) return;

    setState(() {
      _uploading = true;
      _error = null;
    });
    try {
      final url = await ref.read(formControllerProvider).uploadAnswerFile(
            formId: widget.formId,
            fileName: file.name,
            bytes: bytes,
            contentType: contentTypeFor(file.extension),
          );
      if (!mounted) return;
      setState(() {
        _uploading = false;
        _fileName = file.name;
      });
      widget.onChanged(url);
    } on UploadFailure catch (error) {
      if (!mounted) return;
      setState(() {
        _uploading = false;
        _error = error.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final canUpload = ref.read(formControllerProvider).canUploadAnswers;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          decoration: widget.decoration.copyWith(
            helperText: widget.decoration.helperText ??
                (canUpload ? 'Attach a file, or paste a link to one' : 'Paste a link to your file'),
          ),
          controller: widget.controller,
          onChanged: widget.onChanged,
        ),
        if (canUpload)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                OutlinedButton.icon(
                  onPressed: _uploading ? null : _pick,
                  icon: const Icon(Icons.attach_file, size: 16),
                  label: Text(_uploading ? 'Uploading…' : 'Choose a file'),
                ),
                if (_fileName.isNotEmpty) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Attached $_fileName',
                      style: const TextStyle(color: Colors.black54, fontSize: 12),
                    ),
                  ),
                ],
              ],
            ),
          ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12),
            ),
          ),
      ],
    );
  }
}

/// Enough of a mapping for what a church actually attaches. Anything
/// else is stored as a generic download rather than guessed at.
String contentTypeFor(String? extension) => switch ((extension ?? '').toLowerCase()) {
      'pdf' => 'application/pdf',
      'png' => 'image/png',
      'jpg' || 'jpeg' => 'image/jpeg',
      'gif' => 'image/gif',
      'doc' => 'application/msword',
      'docx' => 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'xls' => 'application/vnd.ms-excel',
      'xlsx' => 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      'txt' => 'text/plain',
      _ => 'application/octet-stream',
    };
