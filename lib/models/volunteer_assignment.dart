enum AssignmentStatus { pending, approved, declined }

AssignmentStatus assignmentStatusFromString(String? value) {
  return AssignmentStatus.values.firstWhere((s) => s.name == value, orElse: () => AssignmentStatus.pending);
}

class VolunteerAssignment {
  final String id;
  final String positionId;
  final String uid;
  final AssignmentStatus status;
  final String assignedBy;
  final DateTime assignedAt;

  const VolunteerAssignment({
    required this.id,
    required this.positionId,
    required this.uid,
    required this.status,
    required this.assignedBy,
    required this.assignedAt,
  });

  factory VolunteerAssignment.fromMap(String id, Map<String, dynamic> map) {
    return VolunteerAssignment(
      id: id,
      positionId: map['positionId'] as String? ?? '',
      uid: map['uid'] as String? ?? '',
      status: assignmentStatusFromString(map['status'] as String?),
      assignedBy: map['assignedBy'] as String? ?? '',
      assignedAt: DateTime.tryParse(map['assignedAt'] as String? ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'positionId': positionId,
        'uid': uid,
        'status': status.name,
        'assignedBy': assignedBy,
        'assignedAt': assignedAt.toIso8601String(),
      };
}
