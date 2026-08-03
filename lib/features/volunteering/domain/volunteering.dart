import 'package:flutter/foundation.dart';

@immutable
class VolunteerPosition {
  final String id;
  final String title;
  final String description;
  final String eventId;
  final DateTime date;
  final String location;
  final int slotsNeeded;

  const VolunteerPosition({
    required this.id,
    required this.title,
    this.description = '',
    this.eventId = '',
    required this.date,
    this.location = '',
    this.slotsNeeded = 1,
  });

  factory VolunteerPosition.fromMap(String id, Map<String, dynamic> map) => VolunteerPosition(
        id: id,
        title: map['title'] as String? ?? '',
        description: map['description'] as String? ?? '',
        eventId: map['eventId'] as String? ?? '',
        date: DateTime.tryParse(map['date'] as String? ?? '') ?? DateTime.now(),
        location: map['location'] as String? ?? '',
        slotsNeeded: (map['slotsNeeded'] as num?)?.toInt() ?? 1,
      );

  Map<String, dynamic> toMap() => {
        'title': title,
        'description': description,
        'eventId': eventId,
        'date': date.toIso8601String(),
        'location': location,
        'slotsNeeded': slotsNeeded,
      };

  VolunteerPosition copyWith({
    String? id,
    String? title,
    String? description,
    String? eventId,
    DateTime? date,
    String? location,
    int? slotsNeeded,
  }) =>
      VolunteerPosition(
        id: id ?? this.id,
        title: title ?? this.title,
        description: description ?? this.description,
        eventId: eventId ?? this.eventId,
        date: date ?? this.date,
        location: location ?? this.location,
        slotsNeeded: slotsNeeded ?? this.slotsNeeded,
      );
}

/// A self-signup starts [pending] and only counts against a position's
/// slots once staff [approved] it. A direct staff assignment is created
/// already approved.
enum AssignmentStatus { pending, approved, declined }

@immutable
class VolunteerAssignment {
  final String id;
  final String positionId;
  final String uid;
  final String memberName;
  final AssignmentStatus status;

  /// `'self'` for a signup, otherwise the assigning staff member's uid.
  final String assignedBy;
  final DateTime assignedAt;

  const VolunteerAssignment({
    this.id = '',
    required this.positionId,
    required this.uid,
    this.memberName = '',
    this.status = AssignmentStatus.pending,
    this.assignedBy = 'self',
    required this.assignedAt,
  });

  bool get countsTowardSlots => status != AssignmentStatus.declined;

  factory VolunteerAssignment.fromMap(String id, Map<String, dynamic> map) => VolunteerAssignment(
        id: id,
        positionId: map['positionId'] as String? ?? '',
        uid: map['uid'] as String? ?? '',
        memberName: map['memberName'] as String? ?? '',
        status: AssignmentStatus.values.firstWhere(
          (s) => s.name == map['status'],
          orElse: () => AssignmentStatus.pending,
        ),
        assignedBy: map['assignedBy'] as String? ?? 'self',
        assignedAt: DateTime.tryParse(map['assignedAt'] as String? ?? '') ?? DateTime.now(),
      );

  Map<String, dynamic> toMap() => {
        'positionId': positionId,
        'uid': uid,
        'memberName': memberName,
        'status': status.name,
        'assignedBy': assignedBy,
        'assignedAt': assignedAt.toIso8601String(),
      };

  VolunteerAssignment copyWith({String? id, AssignmentStatus? status}) => VolunteerAssignment(
        id: id ?? this.id,
        positionId: positionId,
        uid: uid,
        memberName: memberName,
        status: status ?? this.status,
        assignedBy: assignedBy,
        assignedAt: assignedAt,
      );
}
