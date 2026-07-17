class Sermon {
  final String id;
  final String title;
  final String speaker;
  final DateTime date;
  final String series;
  final String videoUrl;
  final String thumbnailUrl;
  final String description;

  const Sermon({
    required this.id,
    required this.title,
    required this.speaker,
    required this.date,
    required this.series,
    required this.videoUrl,
    required this.thumbnailUrl,
    required this.description,
  });

  factory Sermon.fromMap(String id, Map<String, dynamic> map) {
    return Sermon(
      id: id,
      title: map['title'] as String? ?? '',
      speaker: map['speaker'] as String? ?? '',
      date: DateTime.tryParse(map['date'] as String? ?? '') ?? DateTime.now(),
      series: map['series'] as String? ?? '',
      videoUrl: map['videoUrl'] as String? ?? '',
      thumbnailUrl: map['thumbnailUrl'] as String? ?? '',
      description: map['description'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'title': title,
        'speaker': speaker,
        'date': date.toIso8601String(),
        'series': series,
        'videoUrl': videoUrl,
        'thumbnailUrl': thumbnailUrl,
        'description': description,
      };
}
