class ChurchEvent {
  final String id;
  final String title;
  final DateTime start;
  final DateTime? end;
  final String location;
  final String description;
  final String imageUrl;

  const ChurchEvent({
    required this.id,
    required this.title,
    required this.start,
    this.end,
    required this.location,
    required this.description,
    this.imageUrl = '',
  });

  factory ChurchEvent.fromMap(String id, Map<String, dynamic> map) {
    return ChurchEvent(
      id: id,
      title: map['title'] as String? ?? '',
      start: DateTime.tryParse(map['start'] as String? ?? '') ?? DateTime.now(),
      end: map['end'] != null ? DateTime.tryParse(map['end'] as String) : null,
      location: map['location'] as String? ?? '',
      description: map['description'] as String? ?? '',
      imageUrl: map['imageUrl'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'title': title,
        'start': start.toIso8601String(),
        'end': end?.toIso8601String(),
        'location': location,
        'description': description,
        'imageUrl': imageUrl,
      };
}
