import 'package:flutter/foundation.dart';

/// A member's own notes on a sermon.
///
/// Not to be confused with [Sermon.notes], which is the church's outline
/// and is published to everyone. This is private to its author: nobody
/// else, staff included, can read it.
@immutable
class SermonNote {
  final String id;
  final String uid;
  final String sermonId;

  /// Denormalised so the member's notes list can render without loading
  /// every sermon, and still reads correctly if a sermon is deleted.
  final String sermonTitle;
  final DateTime sermonDate;

  final String body;
  final DateTime updatedAt;

  const SermonNote({
    this.id = '',
    required this.uid,
    required this.sermonId,
    this.sermonTitle = '',
    required this.sermonDate,
    this.body = '',
    required this.updatedAt,
  });

  factory SermonNote.fromMap(String id, Map<String, dynamic> map) => SermonNote(
        id: id,
        uid: map['uid'] as String? ?? '',
        sermonId: map['sermonId'] as String? ?? '',
        sermonTitle: map['sermonTitle'] as String? ?? '',
        sermonDate: DateTime.tryParse(map['sermonDate'] as String? ?? '') ?? DateTime.now(),
        body: map['body'] as String? ?? '',
        updatedAt: DateTime.tryParse(map['updatedAt'] as String? ?? '') ?? DateTime.now(),
      );

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'sermonId': sermonId,
        'sermonTitle': sermonTitle,
        'sermonDate': sermonDate.toIso8601String(),
        'body': body,
        'updatedAt': updatedAt.toIso8601String(),
      };

  SermonNote copyWith({String? body, DateTime? updatedAt}) => SermonNote(
        id: id,
        uid: uid,
        sermonId: sermonId,
        sermonTitle: sermonTitle,
        sermonDate: sermonDate,
        body: body ?? this.body,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  bool get isEmpty => body.trim().isEmpty;

  String get excerpt {
    final flat = body.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (flat.length <= 140) return flat;
    final cut = flat.lastIndexOf(' ', 140);
    return '${flat.substring(0, cut == -1 ? 140 : cut)}…';
  }
}

/// Deterministic id, so one member has exactly one note per sermon and
/// an autosave can't race itself into duplicates.
String sermonNoteId(String sermonId, String uid) => '${sermonId}__$uid';
