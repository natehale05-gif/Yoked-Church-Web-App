import 'church_form.dart';
import 'form_submission.dart';

/// One row per submission, one column per question.
///
/// Columns come from the form's *current* schema, not from the union of
/// keys seen in the data: a church opens this in a spreadsheet expecting
/// its own questions in its own order, and a question that was deleted
/// last week should not resurrect itself as a column.
///
/// Answers to questions that no longer exist are not silently dropped
/// either - they land in a trailing "Other answers" column, so nothing a
/// member typed is lost between the record and the export.
String submissionsToCsv(FormDefinition form, List<FormSubmission> submissions) {
  final known = {for (final f in form.fields) f.id};
  final hasExtras = submissions.any((s) => s.answers.keys.any((k) => !known.contains(k)));

  final header = <String>[
    'Submitted',
    'Name',
    'Email',
    for (final field in form.fields) field.label,
    if (hasExtras) 'Other answers',
  ];

  final rows = <List<String>>[
    header,
    for (final submission in submissions)
      [
        submission.submittedAt.toIso8601String(),
        submission.submitterName,
        submission.submitterEmail,
        for (final field in form.fields) submission.answers[field.id] ?? '',
        if (hasExtras)
          submission.answers.entries
              .where((e) => !known.contains(e.key))
              .map((e) => '${e.key}: ${e.value}')
              .join('; '),
      ],
  ];

  return rows.map((row) => row.map(csvCell).join(',')).join('\r\n');
}

/// RFC 4180 quoting.
///
/// A church's answers are full of commas ("Peanut, tree nut"), quotes,
/// and the odd pasted line break from a paragraph question - any one of
/// which silently shifts every later column if it goes out raw.
String csvCell(String value) {
  final needsQuotes = value.contains(RegExp('[",\r\n]'));
  if (!needsQuotes) return value;
  return '"${value.replaceAll('"', '""')}"';
}

/// A filename a church can find again in its downloads folder.
String csvFileName(FormDefinition form, DateTime at) =>
    '${form.slug.isEmpty ? 'form' : form.slug}-${dateStamp(at)}.csv';

String dateStamp(DateTime at) =>
    '${at.year.toString().padLeft(4, '0')}-'
    '${at.month.toString().padLeft(2, '0')}-'
    '${at.day.toString().padLeft(2, '0')}';
