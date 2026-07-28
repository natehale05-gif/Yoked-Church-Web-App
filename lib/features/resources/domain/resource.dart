import 'package:flutter/foundation.dart';

/// Something the church wants people to be able to open: a study guide,
/// a form, a kids curriculum, a recommended video.
///
/// [url] is the only thing that matters for opening it. Whether it was
/// uploaded here or pasted from Drive is a detail the reader never sees;
/// [storagePath] is set only for uploads, so the blob can be cleaned up
/// when the record is deleted.
@immutable
class Resource {
  final String id;
  final String title;
  final String description;
  final String category;
  final String url;

  /// Original filename, shown when the URL itself is unreadable.
  final String fileName;
  final String storagePath;

  /// Hidden from signed-out visitors. Not a security boundary - it keeps
  /// internal material off the public page.
  final bool membersOnly;
  final DateTime createdAt;

  const Resource({
    this.id = '',
    required this.title,
    this.description = '',
    this.category = '',
    required this.url,
    this.fileName = '',
    this.storagePath = '',
    this.membersOnly = false,
    required this.createdAt,
  });

  factory Resource.fromMap(String id, Map<String, dynamic> map) => Resource(
        id: id,
        title: map['title'] as String? ?? '',
        description: map['description'] as String? ?? '',
        category: map['category'] as String? ?? '',
        url: map['url'] as String? ?? '',
        fileName: map['fileName'] as String? ?? '',
        storagePath: map['storagePath'] as String? ?? '',
        membersOnly: map['membersOnly'] as bool? ?? false,
        createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ?? DateTime.now(),
      );

  Map<String, dynamic> toMap() => {
        'title': title,
        'description': description,
        'category': category,
        'url': url,
        'fileName': fileName,
        'storagePath': storagePath,
        'membersOnly': membersOnly,
        'createdAt': createdAt.toIso8601String(),
      };

  Resource copyWith({
    String? title,
    String? description,
    String? category,
    String? url,
    String? fileName,
    String? storagePath,
    bool? membersOnly,
  }) =>
      Resource(
        id: id,
        title: title ?? this.title,
        description: description ?? this.description,
        category: category ?? this.category,
        url: url ?? this.url,
        fileName: fileName ?? this.fileName,
        storagePath: storagePath ?? this.storagePath,
        membersOnly: membersOnly ?? this.membersOnly,
        createdAt: createdAt,
      );

  bool get isUpload => storagePath.isNotEmpty;

  /// Coarse type, used only to pick an icon.
  ResourceKind get kind {
    final target = (fileName.isNotEmpty ? fileName : url).toLowerCase();
    if (target.contains('.pdf')) return ResourceKind.pdf;
    if (RegExp(r'\.(docx?|odt|rtf)').hasMatch(target)) return ResourceKind.document;
    if (RegExp(r'\.(xlsx?|csv|ods)').hasMatch(target)) return ResourceKind.sheet;
    if (RegExp(r'\.(mp3|m4a|wav|aac)').hasMatch(target)) return ResourceKind.audio;
    if (RegExp(r'\.(mp4|mov|m4v|webm)').hasMatch(target)) return ResourceKind.video;
    if (target.contains('youtube.com') || target.contains('youtu.be') || target.contains('vimeo.com')) {
      return ResourceKind.video;
    }
    return ResourceKind.link;
  }

  bool matches(String query) {
    if (query.trim().isEmpty) return true;
    final q = query.toLowerCase();
    return title.toLowerCase().contains(q) ||
        description.toLowerCase().contains(q) ||
        category.toLowerCase().contains(q);
  }
}

enum ResourceKind { pdf, document, sheet, audio, video, link }
