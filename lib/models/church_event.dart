class ChurchEvent {
  final String id;
  final String title;
  final DateTime start;
  final DateTime? end;
  final String location;
  final String description;
  final String category;
  final String imageUrl;
  final String registrationUrl;

  const ChurchEvent({
    required this.id,
    required this.title,
    required this.start,
    this.end,
    this.location = '',
    this.description = '',
    this.category = 'General',
    this.imageUrl = '',
    this.registrationUrl = '',
  });

  ChurchEvent copyWith({
    String? title,
    DateTime? start,
    DateTime? end,
    String? location,
    String? description,
    String? category,
    String? imageUrl,
    String? registrationUrl,
  }) {
    return ChurchEvent(
      id: id,
      title: title ?? this.title,
      start: start ?? this.start,
      end: end ?? this.end,
      location: location ?? this.location,
      description: description ?? this.description,
      category: category ?? this.category,
      imageUrl: imageUrl ?? this.imageUrl,
      registrationUrl: registrationUrl ?? this.registrationUrl,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'start': start.toIso8601String(),
        'end': end?.toIso8601String(),
        'location': location,
        'description': description,
        'category': category,
        'imageUrl': imageUrl,
        'registrationUrl': registrationUrl,
      };

  factory ChurchEvent.fromJson(Map<String, dynamic> json) => ChurchEvent(
        id: json['id'] as String,
        title: json['title'] as String? ?? '',
        start:
            DateTime.tryParse(json['start'] as String? ?? '') ?? DateTime.now(),
        end: DateTime.tryParse(json['end'] as String? ?? ''),
        location: json['location'] as String? ?? '',
        description: json['description'] as String? ?? '',
        category: json['category'] as String? ?? 'General',
        imageUrl: json['imageUrl'] as String? ?? '',
        registrationUrl: json['registrationUrl'] as String? ?? '',
      );
}
