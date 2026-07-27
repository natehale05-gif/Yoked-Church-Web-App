import 'package:flutter/foundation.dart';

@immutable
class Sermon {
  final String id;
  final String title;
  final String speaker;
  final DateTime date;
  final String seriesId;
  final String seriesName;
  final String scripture;
  final String videoUrl;
  final String audioUrl;
  final String thumbnailUrl;
  final String description;
  final String notes;

  /// Where this sermon came from. `youtubeAuto` is reserved for the
  /// planned YouTube live-sync import, which lands unpublished for staff
  /// review rather than going straight onto the public site.
  final SermonSource source;
  final bool published;

  const Sermon({
    required this.id,
    required this.title,
    required this.speaker,
    required this.date,
    this.seriesId = '',
    this.seriesName = '',
    this.scripture = '',
    this.videoUrl = '',
    this.audioUrl = '',
    this.thumbnailUrl = '',
    this.description = '',
    this.notes = '',
    this.source = SermonSource.manual,
    this.published = true,
  });

  factory Sermon.fromMap(String id, Map<String, dynamic> map) => Sermon(
        id: id,
        title: map['title'] as String? ?? '',
        speaker: map['speaker'] as String? ?? '',
        date: DateTime.tryParse(map['date'] as String? ?? '') ?? DateTime.now(),
        seriesId: map['seriesId'] as String? ?? '',
        seriesName: map['seriesName'] as String? ?? '',
        scripture: map['scripture'] as String? ?? '',
        videoUrl: map['videoUrl'] as String? ?? '',
        audioUrl: map['audioUrl'] as String? ?? '',
        thumbnailUrl: map['thumbnailUrl'] as String? ?? '',
        description: map['description'] as String? ?? '',
        notes: map['notes'] as String? ?? '',
        source: SermonSource.values.firstWhere(
          (s) => s.name == map['source'],
          orElse: () => SermonSource.manual,
        ),
        published: map['published'] as bool? ?? true,
      );

  Map<String, dynamic> toMap() => {
        'title': title,
        'speaker': speaker,
        'date': date.toIso8601String(),
        'seriesId': seriesId,
        'seriesName': seriesName,
        'scripture': scripture,
        'videoUrl': videoUrl,
        'audioUrl': audioUrl,
        'thumbnailUrl': thumbnailUrl,
        'description': description,
        'notes': notes,
        'source': source.name,
        'published': published,
      };

  Sermon copyWith({
    String? id,
    String? title,
    String? speaker,
    DateTime? date,
    String? seriesId,
    String? seriesName,
    String? scripture,
    String? videoUrl,
    String? audioUrl,
    String? thumbnailUrl,
    String? description,
    String? notes,
    SermonSource? source,
    bool? published,
  }) =>
      Sermon(
        id: id ?? this.id,
        title: title ?? this.title,
        speaker: speaker ?? this.speaker,
        date: date ?? this.date,
        seriesId: seriesId ?? this.seriesId,
        seriesName: seriesName ?? this.seriesName,
        scripture: scripture ?? this.scripture,
        videoUrl: videoUrl ?? this.videoUrl,
        audioUrl: audioUrl ?? this.audioUrl,
        thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
        description: description ?? this.description,
        notes: notes ?? this.notes,
        source: source ?? this.source,
        published: published ?? this.published,
      );

  /// Case-insensitive match across the fields a visitor would search by.
  bool matches(String query) {
    if (query.trim().isEmpty) return true;
    final q = query.toLowerCase();
    return title.toLowerCase().contains(q) ||
        speaker.toLowerCase().contains(q) ||
        seriesName.toLowerCase().contains(q) ||
        scripture.toLowerCase().contains(q) ||
        description.toLowerCase().contains(q);
  }
}

enum SermonSource { manual, youtubeAuto }
