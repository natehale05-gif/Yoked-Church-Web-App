import 'package:flutter/foundation.dart';

@immutable
class ChurchEvent {
  final String id;
  final String title;
  final DateTime start;
  final DateTime? end;
  final String location;
  final String description;
  final String imageUrl;
  final String category;
  final bool rsvpEnabled;
  final int capacity;

  const ChurchEvent({
    required this.id,
    required this.title,
    required this.start,
    this.end,
    this.location = '',
    this.description = '',
    this.imageUrl = '',
    this.category = '',
    this.rsvpEnabled = true,
    this.capacity = 0,
  });

  factory ChurchEvent.fromMap(String id, Map<String, dynamic> map) => ChurchEvent(
        id: id,
        title: map['title'] as String? ?? '',
        start: DateTime.tryParse(map['start'] as String? ?? '') ?? DateTime.now(),
        end: map['end'] == null ? null : DateTime.tryParse(map['end'] as String),
        location: map['location'] as String? ?? '',
        description: map['description'] as String? ?? '',
        imageUrl: map['imageUrl'] as String? ?? '',
        category: map['category'] as String? ?? '',
        rsvpEnabled: map['rsvpEnabled'] as bool? ?? true,
        capacity: (map['capacity'] as num?)?.toInt() ?? 0,
      );

  Map<String, dynamic> toMap() => {
        'title': title,
        'start': start.toIso8601String(),
        'end': end?.toIso8601String(),
        'location': location,
        'description': description,
        'imageUrl': imageUrl,
        'category': category,
        'rsvpEnabled': rsvpEnabled,
        'capacity': capacity,
      };

  ChurchEvent copyWith({
    String? id,
    String? title,
    DateTime? start,
    DateTime? end,
    String? location,
    String? description,
    String? imageUrl,
    String? category,
    bool? rsvpEnabled,
    int? capacity,
  }) =>
      ChurchEvent(
        id: id ?? this.id,
        title: title ?? this.title,
        start: start ?? this.start,
        end: end ?? this.end,
        location: location ?? this.location,
        description: description ?? this.description,
        imageUrl: imageUrl ?? this.imageUrl,
        category: category ?? this.category,
        rsvpEnabled: rsvpEnabled ?? this.rsvpEnabled,
        capacity: capacity ?? this.capacity,
      );

  bool get isPast => (end ?? start).isBefore(DateTime.now());

  /// Google Calendar "add event" link, used by the Add to Calendar button.
  /// Stamps local wall-clock time, which is what a church event time means.
  String get googleCalendarUrl {
    String stamp(DateTime d) =>
        '${d.year.toString().padLeft(4, '0')}${d.month.toString().padLeft(2, '0')}${d.day.toString().padLeft(2, '0')}'
        'T${d.hour.toString().padLeft(2, '0')}${d.minute.toString().padLeft(2, '0')}00';
    final params = {
      'action': 'TEMPLATE',
      'text': title,
      'dates': '${stamp(start)}/${stamp(end ?? start.add(const Duration(hours: 1)))}',
      'details': description,
      'location': location,
    };
    final query = params.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&');
    return 'https://calendar.google.com/calendar/render?$query';
  }
}
