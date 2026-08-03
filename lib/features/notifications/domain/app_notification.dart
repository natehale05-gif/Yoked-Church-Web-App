import 'package:flutter/foundation.dart';

@immutable
class AppNotification {
  final String id;
  final String uid;
  final String title;
  final String message;
  final String linkPath;

  /// Matches a key on [NotificationPreferences] so a member can mute a
  /// whole category without losing the others.
  final String category;
  final DateTime createdAt;
  final bool read;

  const AppNotification({
    this.id = '',
    required this.uid,
    required this.title,
    required this.message,
    this.linkPath = '',
    this.category = 'announcements',
    required this.createdAt,
    this.read = false,
  });

  factory AppNotification.fromMap(String id, Map<String, dynamic> map) => AppNotification(
        id: id,
        uid: map['uid'] as String? ?? '',
        title: map['title'] as String? ?? '',
        message: map['message'] as String? ?? '',
        linkPath: map['linkPath'] as String? ?? '',
        category: map['category'] as String? ?? 'announcements',
        createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ?? DateTime.now(),
        read: map['read'] as bool? ?? false,
      );

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'title': title,
        'message': message,
        'linkPath': linkPath,
        'category': category,
        'createdAt': createdAt.toIso8601String(),
        'read': read,
      };

  AppNotification copyWith({String? id, bool? read}) => AppNotification(
        id: id ?? this.id,
        uid: uid,
        title: title,
        message: message,
        linkPath: linkPath,
        category: category,
        createdAt: createdAt,
        read: read ?? this.read,
      );
}
