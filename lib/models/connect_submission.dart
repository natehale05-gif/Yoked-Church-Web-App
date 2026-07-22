/// A form submission from the Connect / Prayer Request page.
/// [type] distinguishes a prayer request from a general connect card
/// so both can share one form and one Firestore collection.
enum ConnectType { prayerRequest, connectCard }

ConnectType connectTypeFromString(String? value) {
  return ConnectType.values.firstWhere((t) => t.name == value, orElse: () => ConnectType.connectCard);
}

/// Staff-facing follow-up state, set from the admin Connect inbox.
enum SubmissionStatus { open, followedUp }

SubmissionStatus submissionStatusFromString(String? value) {
  return SubmissionStatus.values.firstWhere((s) => s.name == value, orElse: () => SubmissionStatus.open);
}

class ConnectSubmission {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String message;
  final ConnectType type;
  final DateTime submittedAt;
  final SubmissionStatus status;
  final String staffNote;

  const ConnectSubmission({
    this.id = '',
    required this.name,
    required this.email,
    required this.phone,
    required this.message,
    required this.type,
    required this.submittedAt,
    this.status = SubmissionStatus.open,
    this.staffNote = '',
  });

  factory ConnectSubmission.fromMap(String id, Map<String, dynamic> map) {
    return ConnectSubmission(
      id: id,
      name: map['name'] as String? ?? '',
      email: map['email'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      message: map['message'] as String? ?? '',
      type: connectTypeFromString(map['type'] as String?),
      submittedAt: DateTime.tryParse(map['submittedAt'] as String? ?? '') ?? DateTime.now(),
      status: submissionStatusFromString(map['status'] as String?),
      staffNote: map['staffNote'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'email': email,
        'phone': phone,
        'message': message,
        'type': type.name,
        'submittedAt': submittedAt.toIso8601String(),
        'status': status.name,
        'staffNote': staffNote,
      };
}
