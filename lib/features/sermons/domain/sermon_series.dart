import 'package:flutter/foundation.dart';

@immutable
class SermonSeries {
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final DateTime startDate;

  const SermonSeries({
    required this.id,
    required this.name,
    this.description = '',
    this.imageUrl = '',
    required this.startDate,
  });

  factory SermonSeries.fromMap(String id, Map<String, dynamic> map) => SermonSeries(
        id: id,
        name: map['name'] as String? ?? '',
        description: map['description'] as String? ?? '',
        imageUrl: map['imageUrl'] as String? ?? '',
        startDate: DateTime.tryParse(map['startDate'] as String? ?? '') ?? DateTime.now(),
      );

  Map<String, dynamic> toMap() => {
        'name': name,
        'description': description,
        'imageUrl': imageUrl,
        'startDate': startDate.toIso8601String(),
      };

  SermonSeries copyWith({String? id, String? name, String? description, String? imageUrl, DateTime? startDate}) =>
      SermonSeries(
        id: id ?? this.id,
        name: name ?? this.name,
        description: description ?? this.description,
        imageUrl: imageUrl ?? this.imageUrl,
        startDate: startDate ?? this.startDate,
      );
}
