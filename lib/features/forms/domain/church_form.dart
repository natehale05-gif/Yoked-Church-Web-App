import 'package:flutter/foundation.dart';

/// Named [FormFieldType] rather than reusing Flutter's `FormField`
/// vocabulary, because these describe a *stored schema* - a church types
/// them in, they outlive any widget tree.
enum FormFieldType {
  shortText,
  longText,
  email,
  phone,
  number,
  date,
  dropdown,
  radio,
  checkbox,
  file,
}

extension FormFieldTypeLabel on FormFieldType {
  String get label => switch (this) {
        FormFieldType.shortText => 'Short text',
        FormFieldType.longText => 'Paragraph',
        FormFieldType.email => 'Email',
        FormFieldType.phone => 'Phone',
        FormFieldType.number => 'Number',
        FormFieldType.date => 'Date',
        FormFieldType.dropdown => 'Dropdown',
        FormFieldType.radio => 'Choose one',
        FormFieldType.checkbox => 'Checkbox',
        FormFieldType.file => 'File upload',
      };

  bool get hasOptions => this == FormFieldType.dropdown || this == FormFieldType.radio;
}

/// "Show this field only when [fieldId] answers [equals]."
///
/// One condition per field, not a boolean tree. A church secretary
/// building a camp registration needs "if attending, ask which week";
/// nobody has ever needed a nested AND/OR, and offering one guarantees
/// forms nobody can debug.
@immutable
class FieldCondition {
  final String fieldId;
  final String equals;

  const FieldCondition({required this.fieldId, required this.equals});

  factory FieldCondition.fromMap(Map<String, dynamic> map) => FieldCondition(
        fieldId: map['fieldId'] as String? ?? '',
        equals: map['equals'] as String? ?? '',
      );

  Map<String, dynamic> toMap() => {'fieldId': fieldId, 'equals': equals};
}

@immutable
class FormFieldDef {
  final String id;
  final String label;
  final FormFieldType type;
  final bool required;
  final List<String> options;
  final String helpText;

  /// Zero-based. Multi-page forms exist because a twenty-question
  /// registration on one screen gets abandoned.
  final int page;

  final FieldCondition? showIf;

  const FormFieldDef({
    required this.id,
    required this.label,
    this.type = FormFieldType.shortText,
    this.required = false,
    this.options = const [],
    this.helpText = '',
    this.page = 0,
    this.showIf,
  });

  factory FormFieldDef.fromMap(Map<String, dynamic> map) => FormFieldDef(
        id: map['id'] as String? ?? '',
        label: map['label'] as String? ?? '',
        type: FormFieldType.values.firstWhere(
          (t) => t.name == map['type'],
          orElse: () => FormFieldType.shortText,
        ),
        required: map['required'] as bool? ?? false,
        options: (map['options'] as List<dynamic>? ?? const []).whereType<String>().toList(),
        helpText: map['helpText'] as String? ?? '',
        page: (map['page'] as num?)?.toInt() ?? 0,
        showIf: map['showIf'] == null
            ? null
            : FieldCondition.fromMap((map['showIf'] as Map<dynamic, dynamic>).cast<String, dynamic>()),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'label': label,
        'type': type.name,
        'required': required,
        'options': options,
        'helpText': helpText,
        'page': page,
        if (showIf != null) 'showIf': showIf!.toMap(),
      };

  FormFieldDef copyWith({
    String? label,
    FormFieldType? type,
    bool? required,
    List<String>? options,
    String? helpText,
    int? page,
    FieldCondition? showIf,
    bool clearCondition = false,
  }) =>
      FormFieldDef(
        id: id,
        label: label ?? this.label,
        type: type ?? this.type,
        required: required ?? this.required,
        options: options ?? this.options,
        helpText: helpText ?? this.helpText,
        page: page ?? this.page,
        showIf: clearCondition ? null : (showIf ?? this.showIf),
      );
}

@immutable
class FormDefinition {
  final String id;
  final String title;

  /// The public URL segment. Stable and human-readable, because these get
  /// printed in bulletins.
  final String slug;

  final String description;
  final List<FormFieldDef> fields;
  final bool published;

  /// Signed-in members only. Distinct from [published]: a members-only
  /// form is live, just not to the public internet.
  final bool membersOnly;

  final DateTime? closesAt;

  /// Staff to notify when a submission arrives. Wired in the next slice;
  /// stored here because it is part of the form's definition.
  final List<String> notifyUids;

  final String confirmationMessage;

  const FormDefinition({
    this.id = '',
    required this.title,
    required this.slug,
    this.description = '',
    this.fields = const [],
    this.published = false,
    this.membersOnly = false,
    this.closesAt,
    this.notifyUids = const [],
    this.confirmationMessage = '',
  });

  factory FormDefinition.fromMap(String id, Map<String, dynamic> map) => FormDefinition(
        id: id,
        title: map['title'] as String? ?? '',
        slug: map['slug'] as String? ?? '',
        description: map['description'] as String? ?? '',
        fields: (map['fields'] as List<dynamic>? ?? const [])
            .whereType<Map<dynamic, dynamic>>()
            .map((f) => FormFieldDef.fromMap(f.cast<String, dynamic>()))
            .toList(),
        published: map['published'] as bool? ?? false,
        membersOnly: map['membersOnly'] as bool? ?? false,
        closesAt: DateTime.tryParse(map['closesAt'] as String? ?? ''),
        notifyUids: (map['notifyUids'] as List<dynamic>? ?? const []).whereType<String>().toList(),
        confirmationMessage: map['confirmationMessage'] as String? ?? '',
      );

  Map<String, dynamic> toMap() => {
        'title': title,
        'slug': slug,
        'description': description,
        'fields': [for (final f in fields) f.toMap()],
        'published': published,
        'membersOnly': membersOnly,
        'closesAt': closesAt?.toIso8601String() ?? '',
        'notifyUids': notifyUids,
        'confirmationMessage': confirmationMessage,
      };

  FormDefinition copyWith({
    String? id,
    String? title,
    String? slug,
    String? description,
    List<FormFieldDef>? fields,
    bool? published,
    bool? membersOnly,
    DateTime? closesAt,
    bool clearClosesAt = false,
    List<String>? notifyUids,
    String? confirmationMessage,
  }) =>
      FormDefinition(
        id: id ?? this.id,
        title: title ?? this.title,
        slug: slug ?? this.slug,
        description: description ?? this.description,
        fields: fields ?? this.fields,
        published: published ?? this.published,
        membersOnly: membersOnly ?? this.membersOnly,
        closesAt: clearClosesAt ? null : (closesAt ?? this.closesAt),
        notifyUids: notifyUids ?? this.notifyUids,
        confirmationMessage: confirmationMessage ?? this.confirmationMessage,
      );

  int get pageCount =>
      fields.isEmpty ? 1 : fields.map((f) => f.page).reduce((a, b) => a > b ? a : b) + 1;

  bool get hasClosed => closesAt != null && closesAt!.isBefore(DateTime.now());

  /// A form only accepts answers when it is published *and* still open.
  /// Both halves are checked again in the controller - hiding the button
  /// is presentation, not enforcement.
  bool get isAcceptingSubmissions => published && !hasClosed;

  /// Which fields a member should actually see, given what they have
  /// answered so far.
  ///
  /// Evaluated in field order, so a condition may only depend on a field
  /// *above* it - and a field whose controller is itself hidden is hidden
  /// too, rather than reappearing under a branch that was closed.
  ///
  /// A condition pointing at a field that no longer exists leaves its
  /// field visible: an orphaned reference is a broken form either way,
  /// and showing an extra question is recoverable where silently hiding a
  /// required one is not.
  List<FormFieldDef> visibleFields(Map<String, String> answers) {
    final known = {for (final f in fields) f.id};
    final visible = <String>{};
    final result = <FormFieldDef>[];

    for (final field in fields) {
      final condition = field.showIf;
      final show = condition == null ||
          !known.contains(condition.fieldId) ||
          (visible.contains(condition.fieldId) &&
              (answers[condition.fieldId] ?? '') == condition.equals);
      if (show) {
        visible.add(field.id);
        result.add(field);
      }
    }
    return result;
  }

  List<FormFieldDef> visibleFieldsOnPage(Map<String, String> answers, int page) =>
      visibleFields(answers).where((f) => f.page == page).toList();

  /// Required fields the member has not answered.
  ///
  /// Only ever looks at visible fields: a hidden field is never required,
  /// or a form becomes unsubmittable because of a question nobody can
  /// see.
  List<FormFieldDef> missingRequired(Map<String, String> answers) => visibleFields(answers)
      .where((f) => f.required && (answers[f.id] ?? '').trim().isEmpty)
      .toList();

  /// The answers that actually belong to this submission.
  ///
  /// Answers to hidden fields are dropped, so toggling a branch back and
  /// forth cannot smuggle a stale answer into the record.
  Map<String, String> prune(Map<String, String> answers) {
    final visible = {for (final f in visibleFields(answers)) f.id};
    return {
      for (final entry in answers.entries)
        if (visible.contains(entry.key) && entry.value.trim().isNotEmpty) entry.key: entry.value,
    };
  }
}

/// URL-safe slug from a title. Not unique on its own - the repository
/// checks that - but stable and readable, which is what a bulletin needs.
String slugify(String input) {
  final lower = input.toLowerCase().trim();
  final cleaned = lower.replaceAll(RegExp(r'[^a-z0-9]+'), '-');
  return cleaned.replaceAll(RegExp(r'^-+|-+$'), '');
}

/// A field id that survives a label being reworded. Conditions point at
/// ids, so renaming "Are you coming?" must not silently orphan the
/// branch hanging off it.
String newFieldId(Iterable<String> taken) {
  var n = taken.length + 1;
  while (taken.contains('f$n')) {
    n++;
  }
  return 'f$n';
}
