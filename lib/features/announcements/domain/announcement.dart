import 'package:flutter/foundation.dart';

/// Who an announcement went to. Kept on the record so staff can see the
/// reach of something they sent last month.
enum AnnouncementAudience { everyone, staff, group }

@immutable
class Announcement {
  final String id;
  final String title;
  final String body;
  final AnnouncementAudience audience;

  /// Set only when [audience] is [AnnouncementAudience.group].
  final String groupId;
  final String groupName;
  final String sentByName;
  final int recipientCount;
  final DateTime sentAt;

  const Announcement({
    this.id = '',
    required this.title,
    required this.body,
    this.audience = AnnouncementAudience.everyone,
    this.groupId = '',
    this.groupName = '',
    this.sentByName = '',
    this.recipientCount = 0,
    required this.sentAt,
  });

  factory Announcement.fromMap(String id, Map<String, dynamic> map) => Announcement(
        id: id,
        title: map['title'] as String? ?? '',
        body: map['body'] as String? ?? '',
        audience: AnnouncementAudience.values.firstWhere(
          (a) => a.name == map['audience'],
          orElse: () => AnnouncementAudience.everyone,
        ),
        groupId: map['groupId'] as String? ?? '',
        groupName: map['groupName'] as String? ?? '',
        sentByName: map['sentByName'] as String? ?? '',
        recipientCount: (map['recipientCount'] as num?)?.toInt() ?? 0,
        sentAt: DateTime.tryParse(map['sentAt'] as String? ?? '') ?? DateTime.now(),
      );

  Map<String, dynamic> toMap() => {
        'title': title,
        'body': body,
        'audience': audience.name,
        'groupId': groupId,
        'groupName': groupName,
        'sentByName': sentByName,
        'recipientCount': recipientCount,
        'sentAt': sentAt.toIso8601String(),
      };

  String get audienceLabel => switch (audience) {
        AnnouncementAudience.everyone => 'Everyone',
        AnnouncementAudience.staff => 'Staff only',
        AnnouncementAudience.group => groupName.isEmpty ? 'A group' : groupName,
      };
}
