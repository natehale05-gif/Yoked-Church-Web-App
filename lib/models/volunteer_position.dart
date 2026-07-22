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
    required this.description,
    this.eventId = '',
    required this.date,
    required this.location,
    required this.slotsNeeded,
  });

  factory VolunteerPosition.fromMap(String id, Map<String, dynamic> map) {
    return VolunteerPosition(
      id: id,
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      eventId: map['eventId'] as String? ?? '',
      date: DateTime.tryParse(map['date'] as String? ?? '') ?? DateTime.now(),
      location: map['location'] as String? ?? '',
      slotsNeeded: (map['slotsNeeded'] as num?)?.toInt() ?? 1,
    );
  }

  Map<String, dynamic> toMap() => {
        'title': title,
        'description': description,
        'eventId': eventId,
        'date': date.toIso8601String(),
        'location': location,
        'slotsNeeded': slotsNeeded,
      };
}
