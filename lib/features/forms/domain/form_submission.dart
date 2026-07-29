import 'package:flutter/foundation.dart';

@immutable
class FormSubmission {
  final String id;
  final String formId;

  /// Denormalised, like every other historical record here: a submission
  /// must still read correctly after the form is renamed or deleted.
  final String formTitle;

  /// Empty for a public submission - a visitor filling in a camp
  /// registration has no account, and requiring one would lose them.
  final String uid;

  final String submitterName;
  final String submitterEmail;

  /// Field id to answer. Every value is a string: a checkbox stores
  /// 'true', a file stores its URL. One shape keeps CSV export and the
  /// Firestore document honest.
  final Map<String, String> answers;

  final DateTime submittedAt;

  const FormSubmission({
    this.id = '',
    required this.formId,
    this.formTitle = '',
    this.uid = '',
    this.submitterName = '',
    this.submitterEmail = '',
    this.answers = const {},
    required this.submittedAt,
  });

  factory FormSubmission.fromMap(String id, Map<String, dynamic> map) => FormSubmission(
        id: id,
        formId: map['formId'] as String? ?? '',
        formTitle: map['formTitle'] as String? ?? '',
        uid: map['uid'] as String? ?? '',
        submitterName: map['submitterName'] as String? ?? '',
        submitterEmail: map['submitterEmail'] as String? ?? '',
        answers: (map['answers'] as Map<dynamic, dynamic>? ?? const {})
            .map((key, value) => MapEntry('$key', '${value ?? ''}')),
        submittedAt: DateTime.tryParse(map['submittedAt'] as String? ?? '') ?? DateTime.now(),
      );

  Map<String, dynamic> toMap() => {
        'formId': formId,
        'formTitle': formTitle,
        'uid': uid,
        'submitterName': submitterName,
        'submitterEmail': submitterEmail,
        'answers': answers,
        'submittedAt': submittedAt.toIso8601String(),
      };

  String get who => submitterName.isNotEmpty
      ? submitterName
      : (submitterEmail.isNotEmpty ? submitterEmail : 'Anonymous');
}
