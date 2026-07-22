class EventRsvp {
  final String id;
  final String eventId;
  final String uid;
  final DateTime respondedAt;

  const EventRsvp({
    required this.id,
    required this.eventId,
    required this.uid,
    required this.respondedAt,
  });

  factory EventRsvp.fromMap(String id, Map<String, dynamic> map) {
    return EventRsvp(
      id: id,
      eventId: map['eventId'] as String? ?? '',
      uid: map['uid'] as String? ?? '',
      respondedAt: DateTime.tryParse(map['respondedAt'] as String? ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'eventId': eventId,
        'uid': uid,
        'respondedAt': respondedAt.toIso8601String(),
      };
}
