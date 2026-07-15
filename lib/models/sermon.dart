class Sermon {
  final String id;
  final String title;
  final String speaker;
  final String series;
  final DateTime date;
  final String description;
  final String scripture;

  /// A link to audio/video (YouTube, Spotify, mp3, etc.).
  final String mediaUrl;
  final String imageUrl;

  const Sermon({
    required this.id,
    required this.title,
    required this.speaker,
    this.series = '',
    required this.date,
    this.description = '',
    this.scripture = '',
    this.mediaUrl = '',
    this.imageUrl = '',
  });

  Sermon copyWith({
    String? title,
    String? speaker,
    String? series,
    DateTime? date,
    String? description,
    String? scripture,
    String? mediaUrl,
    String? imageUrl,
  }) {
    return Sermon(
      id: id,
      title: title ?? this.title,
      speaker: speaker ?? this.speaker,
      series: series ?? this.series,
      date: date ?? this.date,
      description: description ?? this.description,
      scripture: scripture ?? this.scripture,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'speaker': speaker,
        'series': series,
        'date': date.toIso8601String(),
        'description': description,
        'scripture': scripture,
        'mediaUrl': mediaUrl,
        'imageUrl': imageUrl,
      };

  factory Sermon.fromJson(Map<String, dynamic> json) => Sermon(
        id: json['id'] as String,
        title: json['title'] as String? ?? '',
        speaker: json['speaker'] as String? ?? '',
        series: json['series'] as String? ?? '',
        date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
        description: json['description'] as String? ?? '',
        scripture: json['scripture'] as String? ?? '',
        mediaUrl: json['mediaUrl'] as String? ?? '',
        imageUrl: json['imageUrl'] as String? ?? '',
      );
}
