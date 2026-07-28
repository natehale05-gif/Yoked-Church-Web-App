import 'package:flutter/foundation.dart';

/// A short daily reading written by the church.
///
/// [publishDate] is a scheduling field, not just a display one: a
/// devotional dated in the future stays off the public site until that
/// day arrives, so staff can write a month at a time.
@immutable
class Devotional {
  final String id;
  final String title;
  final String body;
  final String scripture;
  final String author;
  final DateTime publishDate;
  final bool published;

  const Devotional({
    this.id = '',
    required this.title,
    this.body = '',
    this.scripture = '',
    this.author = '',
    required this.publishDate,
    this.published = true,
  });

  factory Devotional.fromMap(String id, Map<String, dynamic> map) => Devotional(
        id: id,
        title: map['title'] as String? ?? '',
        body: map['body'] as String? ?? '',
        scripture: map['scripture'] as String? ?? '',
        author: map['author'] as String? ?? '',
        publishDate: DateTime.tryParse(map['publishDate'] as String? ?? '') ?? DateTime.now(),
        published: map['published'] as bool? ?? true,
      );

  Map<String, dynamic> toMap() => {
        'title': title,
        'body': body,
        'scripture': scripture,
        'author': author,
        'publishDate': publishDate.toIso8601String(),
        'published': published,
      };

  Devotional copyWith({
    String? id,
    String? title,
    String? body,
    String? scripture,
    String? author,
    DateTime? publishDate,
    bool? published,
  }) =>
      Devotional(
        id: id ?? this.id,
        title: title ?? this.title,
        body: body ?? this.body,
        scripture: scripture ?? this.scripture,
        author: author ?? this.author,
        publishDate: publishDate ?? this.publishDate,
        published: published ?? this.published,
      );

  /// Live on the public site: published *and* dated today or earlier.
  bool isLiveAt(DateTime now) => published && !publishDate.isAfter(now);

  /// Enough of the body to preview in a list, cut on a word boundary so
  /// the excerpt doesn't end mid-word.
  String get excerpt {
    final flat = body.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (flat.length <= 160) return flat;
    final cut = flat.lastIndexOf(' ', 160);
    return '${flat.substring(0, cut == -1 ? 160 : cut)}…';
  }

  bool matches(String query) {
    if (query.trim().isEmpty) return true;
    final q = query.toLowerCase();
    return title.toLowerCase().contains(q) ||
        scripture.toLowerCase().contains(q) ||
        author.toLowerCase().contains(q) ||
        body.toLowerCase().contains(q);
  }
}
