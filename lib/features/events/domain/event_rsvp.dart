import 'package:flutter/foundation.dart';

@immutable
class EventRsvp {
  final String id;
  final String eventId;
  final String uid;
  final String memberName;
  final int partySize;
  final DateTime respondedAt;

  const EventRsvp({
    this.id = '',
    required this.eventId,
    required this.uid,
    this.memberName = '',
    this.partySize = 1,
    required this.respondedAt,
  });

  factory EventRsvp.fromMap(String id, Map<String, dynamic> map) => EventRsvp(
        id: id,
        eventId: map['eventId'] as String? ?? '',
        uid: map['uid'] as String? ?? '',
        memberName: map['memberName'] as String? ?? '',
        partySize: (map['partySize'] as num?)?.toInt() ?? 1,
        respondedAt: DateTime.tryParse(map['respondedAt'] as String? ?? '') ?? DateTime.now(),
      );

  Map<String, dynamic> toMap() => {
        'eventId': eventId,
        'uid': uid,
        'memberName': memberName,
        'partySize': partySize,
        'respondedAt': respondedAt.toIso8601String(),
      };
}
