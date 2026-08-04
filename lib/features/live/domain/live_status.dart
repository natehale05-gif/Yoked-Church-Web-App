import 'package:flutter/foundation.dart';

/// Whether the church is streaming right now, as last observed by the
/// scheduled job that polls their YouTube channel.
///
/// One document per church rather than a document that appears and
/// disappears: [checkedAt] is the difference between "we looked and they
/// are not live" and "nothing has ever looked", and an admin who has just
/// pasted a channel id needs to be able to tell those apart.
@immutable
class LiveStatus {
  /// Live *now*, as of [checkedAt].
  final bool live;

  /// The YouTube video id of the stream, empty when not live.
  final String videoId;

  final String title;

  /// When the stream started, for "live for 20 minutes".
  final DateTime? startedAt;

  /// When the poller last looked. Null means it never has.
  final DateTime? checkedAt;

  const LiveStatus({
    this.live = false,
    this.videoId = '',
    this.title = '',
    this.startedAt,
    this.checkedAt,
  });

  /// Only meaningful while [live]; the video id is cleared when a stream
  /// ends, precisely so nothing can link to a dead one.
  String get watchUrl => videoId.isEmpty ? '' : 'https://www.youtube.com/watch?v=$videoId';

  /// True only when there is somewhere to send a person right now.
  bool get isWatchable => live && videoId.isNotEmpty;

  factory LiveStatus.fromMap(Map<String, dynamic> map) => LiveStatus(
        live: map['live'] as bool? ?? false,
        videoId: map['videoId'] as String? ?? '',
        title: map['title'] as String? ?? '',
        startedAt: _time(map['startedAt']),
        checkedAt: _time(map['checkedAt']),
      );

  Map<String, dynamic> toMap() => {
        'live': live,
        'videoId': videoId,
        'title': title,
        'startedAt': startedAt?.toIso8601String(),
        'checkedAt': checkedAt?.toIso8601String(),
      };

  /// Accepts either an ISO string or a Firestore `Timestamp`, since the
  /// function writes server timestamps and the bundled sample writes
  /// strings.
  static DateTime? _time(Object? value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    // Firestore Timestamp, kept behind `dynamic` so this file needs no
    // dependency on cloud_firestore.
    try {
      return (value as dynamic).toDate() as DateTime;
    } catch (_) {
      return null;
    }
  }
}
