import 'package:flutter/foundation.dart';

@immutable
class ChurchGroup {
  final String id;
  final String name;
  final String description;
  final String category;
  final String meetingDay;
  final String meetingTime;
  final String location;
  final String leaderName;

  /// The leader's account, when they have one. Distinct from
  /// [leaderName]: the name is display copy a church types in, this is
  /// the identity that grants them their own group's attendance history.
  final String leaderUid;
  final String imageUrl;
  final bool openToJoin;

  const ChurchGroup({
    required this.id,
    required this.name,
    this.description = '',
    this.category = '',
    this.meetingDay = '',
    this.meetingTime = '',
    this.location = '',
    this.leaderName = '',
    this.leaderUid = '',
    this.imageUrl = '',
    this.openToJoin = true,
  });

  factory ChurchGroup.fromMap(String id, Map<String, dynamic> map) => ChurchGroup(
        id: id,
        name: map['name'] as String? ?? '',
        description: map['description'] as String? ?? '',
        category: map['category'] as String? ?? '',
        meetingDay: map['meetingDay'] as String? ?? '',
        meetingTime: map['meetingTime'] as String? ?? '',
        location: map['location'] as String? ?? '',
        leaderName: map['leaderName'] as String? ?? '',
        leaderUid: map['leaderUid'] as String? ?? '',
        imageUrl: map['imageUrl'] as String? ?? '',
        openToJoin: map['openToJoin'] as bool? ?? true,
      );

  Map<String, dynamic> toMap() => {
        'name': name,
        'description': description,
        'category': category,
        'meetingDay': meetingDay,
        'meetingTime': meetingTime,
        'location': location,
        'leaderName': leaderName,
        'leaderUid': leaderUid,
        'imageUrl': imageUrl,
        'openToJoin': openToJoin,
      };

  String get whenAndWhere =>
      [meetingDay, meetingTime, location].where((s) => s.isNotEmpty).join(' · ');

  ChurchGroup copyWith({
    String? id,
    String? name,
    String? description,
    String? category,
    String? meetingDay,
    String? meetingTime,
    String? location,
    String? leaderName,
    String? leaderUid,
    String? imageUrl,
    bool? openToJoin,
  }) =>
      ChurchGroup(
        id: id ?? this.id,
        name: name ?? this.name,
        description: description ?? this.description,
        category: category ?? this.category,
        meetingDay: meetingDay ?? this.meetingDay,
        meetingTime: meetingTime ?? this.meetingTime,
        location: location ?? this.location,
        leaderName: leaderName ?? this.leaderName,
        leaderUid: leaderUid ?? this.leaderUid,
        imageUrl: imageUrl ?? this.imageUrl,
        openToJoin: openToJoin ?? this.openToJoin,
      );
}

enum MembershipStatus { pending, approved }

@immutable
class GroupMembership {
  final String id;
  final String groupId;
  final String uid;
  final String memberName;
  final MembershipStatus status;
  final DateTime joinedAt;

  const GroupMembership({
    this.id = '',
    required this.groupId,
    required this.uid,
    this.memberName = '',
    this.status = MembershipStatus.pending,
    required this.joinedAt,
  });

  factory GroupMembership.fromMap(String id, Map<String, dynamic> map) => GroupMembership(
        id: id,
        groupId: map['groupId'] as String? ?? '',
        uid: map['uid'] as String? ?? '',
        memberName: map['memberName'] as String? ?? '',
        status: MembershipStatus.values.firstWhere(
          (s) => s.name == map['status'],
          orElse: () => MembershipStatus.pending,
        ),
        joinedAt: DateTime.tryParse(map['joinedAt'] as String? ?? '') ?? DateTime.now(),
      );

  Map<String, dynamic> toMap() => {
        'groupId': groupId,
        'uid': uid,
        'memberName': memberName,
        'status': status.name,
        'joinedAt': joinedAt.toIso8601String(),
      };

  GroupMembership copyWith({String? id, MembershipStatus? status}) => GroupMembership(
        id: id ?? this.id,
        groupId: groupId,
        uid: uid,
        memberName: memberName,
        status: status ?? this.status,
        joinedAt: joinedAt,
      );
}
