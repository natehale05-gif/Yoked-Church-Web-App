import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/export/file_download.dart';
import '../../../core/widgets/app_shell.dart';
import '../../../core/widgets/async_value_widget.dart';
import '../../../core/widgets/section_container.dart';
import '../../forms/application/form_providers.dart';
import '../../forms/domain/church_form.dart';
import '../../forms/domain/form_submission.dart';
import '../../forms/domain/submission_csv.dart';
import 'admin_header.dart';

/// The inbox for one form. Separate from the builder because reading
/// answers and changing questions are different jobs, and a church that
/// is doing one is never doing the other.
class FormResponsesScreen extends ConsumerWidget {
  final String formId;

  const FormResponsesScreen({super.key, required this.formId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final forms = ref.watch(formsProvider).valueOrNull ?? const <FormDefinition>[];
    final form = forms.where((f) => f.id == formId).firstOrNull;
    final submissions = ref.watch(submissionsForFormProvider(formId));

    if (form == null) {
      return const PageBody(
        children: [
          AdminHeader(title: 'Responses', subtitle: 'That form no longer exists.'),
        ],
      );
    }

    final rows = submissions.valueOrNull ?? const <FormSubmission>[];

    return PageBody(
      children: [
        AdminHeader(
          title: '${form.title} · responses',
          subtitle: rows.isEmpty
              ? 'Nothing has come in yet.'
              : '${rows.length} response${rows.length == 1 ? '' : 's'}',
        ),
        SectionContainer(
          maxWidth: 900,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: () => context.go('/admin/forms/$formId'),
                    icon: const Icon(Icons.edit_outlined, size: 16),
                    label: const Text('Edit questions'),
                  ),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: rows.isEmpty ? null : () => _export(context, form, rows),
                    icon: const Icon(Icons.download_outlined, size: 18),
                    label: const Text('Export CSV'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              AsyncListWidget<FormSubmission>(
                value: submissions,
                errorContext: 'these responses',
                emptyMessage: 'No responses yet.',
                data: (list) => Column(
                  children: [for (final s in list) _SubmissionCard(form: form, submission: s)],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _export(
    BuildContext context,
    FormDefinition form,
    List<FormSubmission> rows,
  ) async {
    final csv = submissionsToCsv(form, rows);
    if (downloadText(
      fileName: csvFileName(form, DateTime.now()),
      contents: csv,
      mimeType: 'text/csv',
    )) {
      return;
    }

    // No browser to save through. Rather than a button that does nothing,
    // hand over the text itself.
    await Clipboard.setData(ClipboardData(text: csv));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('CSV copied to the clipboard - paste it into a spreadsheet.')),
    );
  }
}

class _SubmissionCard extends ConsumerWidget {
  final FormDefinition form;
  final FormSubmission submission;

  const _SubmissionCard({required this.form, required this.submission});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final known = {for (final f in form.fields) f.id};
    final orphaned = submission.answers.keys.where((k) => !known.contains(k)).toList();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(submission.who, style: Theme.of(context).textTheme.titleMedium),
                ),
                Text(
                  DateFormat.yMMMd().add_jm().format(submission.submittedAt),
                  style: const TextStyle(color: Colors.black54, fontSize: 12),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 18),
                  tooltip: 'Delete this response',
                  onPressed: () async {
                    if (!await confirmDelete(context, "${submission.who}'s response")) return;
                    await ref.read(formControllerProvider).deleteSubmission(submission.id);
                  },
                ),
              ],
            ),
            if (submission.submitterEmail.isNotEmpty)
              Text(submission.submitterEmail, style: const TextStyle(color: Colors.black54, fontSize: 12)),
            const SizedBox(height: 12),
            for (final field in form.fields)
              if ((submission.answers[field.id] ?? '').isNotEmpty)
                _AnswerRow(label: field.label, value: submission.answers[field.id]!, field: field),
            // An answer whose question was later deleted still shows,
            // labelled by its id. Losing what someone typed because the
            // form was edited afterwards would be worse than an ugly row.
            for (final key in orphaned)
              _AnswerRow(label: '($key - question removed)', value: submission.answers[key]!),
          ],
        ),
      ),
    );
  }
}

class _AnswerRow extends StatelessWidget {
  final String label;
  final String value;
  final FormFieldDef? field;

  const _AnswerRow({required this.label, required this.value, this.field});

  @override
  Widget build(BuildContext context) {
    final isLink = field?.type == FormFieldType.file || value.startsWith('http');
    final display = field?.type == FormFieldType.date
        ? DateFormat.yMMMd().format(DateTime.tryParse(value) ?? DateTime.now())
        : (field?.type == FormFieldType.checkbox && value == 'true' ? 'Yes' : value);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 220,
            child: Text(label, style: const TextStyle(color: Colors.black54, fontSize: 13)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: isLink
                ? InkWell(
                    onTap: () => launchUrl(Uri.parse(value), mode: LaunchMode.externalApplication),
                    child: Text(
                      display,
                      style: const TextStyle(decoration: TextDecoration.underline),
                    ),
                  )
                : Text(display),
          ),
        ],
      ),
    );
  }
}
