enum MembershipStatus { pending, approved }

MembershipStatus membershipStatusFromString(String? value) {
  return MembershipStatus.values.firstWhere(
    (status) => status.name == value,
    orElse: () => MembershipStatus.pending,
  );
}

class GroupMembership {
  final String id;
  final String groupId;
  final String uid;
  final MembershipStatus status;
  final DateTime joinedAt;

  const GroupMembership({
    required this.id,
    required this.groupId,
    required this.uid,
    required this.status,
    required this.joinedAt,
  });

  factory GroupMembership.fromMap(String id, Map<String, dynamic> map) {
    return GroupMembership(
      id: id,
      groupId: map['groupId'] as String? ?? '',
      uid: map['uid'] as String? ?? '',
      status: membershipStatusFromString(map['status'] as String?),
      joinedAt: DateTime.tryParse(map['joinedAt'] as String? ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'groupId': groupId,
        'uid': uid,
        'status': status.name,
        'joinedAt': joinedAt.toIso8601String(),
      };
}
