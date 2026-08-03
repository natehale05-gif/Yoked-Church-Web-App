import 'package:flutter/foundation.dart';

enum ConnectType { connectCard, prayerRequest }

enum SubmissionStatus { open, followedUp }

@immutable
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
  final String assignedTo;

  const ConnectSubmission({
    this.id = '',
    required this.name,
    required this.email,
    this.phone = '',
    this.message = '',
    required this.type,
    required this.submittedAt,
    this.status = SubmissionStatus.open,
    this.staffNote = '',
    this.assignedTo = '',
  });

  factory ConnectSubmission.fromMap(String id, Map<String, dynamic> map) => ConnectSubmission(
        id: id,
        name: map['name'] as String? ?? '',
        email: map['email'] as String? ?? '',
        phone: map['phone'] as String? ?? '',
        message: map['message'] as String? ?? '',
        type: ConnectType.values.firstWhere(
          (t) => t.name == map['type'],
          orElse: () => ConnectType.connectCard,
        ),
        submittedAt: DateTime.tryParse(map['submittedAt'] as String? ?? '') ?? DateTime.now(),
        status: SubmissionStatus.values.firstWhere(
          (s) => s.name == map['status'],
          orElse: () => SubmissionStatus.open,
        ),
        staffNote: map['staffNote'] as String? ?? '',
        assignedTo: map['assignedTo'] as String? ?? '',
      );

  Map<String, dynamic> toMap() => {
        'name': name,
        'email': email,
        'phone': phone,
        'message': message,
        'type': type.name,
        'submittedAt': submittedAt.toIso8601String(),
        'status': status.name,
        'staffNote': staffNote,
        'assignedTo': assignedTo,
      };

  ConnectSubmission copyWith({
    String? id,
    SubmissionStatus? status,
    String? staffNote,
    String? assignedTo,
  }) =>
      ConnectSubmission(
        id: id ?? this.id,
        name: name,
        email: email,
        phone: phone,
        message: message,
        type: type,
        submittedAt: submittedAt,
        status: status ?? this.status,
        staffNote: staffNote ?? this.staffNote,
        assignedTo: assignedTo ?? this.assignedTo,
      );
}
