import 'package:flutter/foundation.dart';

/// Where a request is in moderation. Nothing reaches the wall until
/// staff approve it - the same approve-first shape as group joins and
/// volunteer signups, and for a stronger reason: a prayer request is
/// visible to the whole congregation and can name other people.
enum PrayerStatus { pending, approved, removed }

@immutable
class PrayerPost {
  final String id;
  final String uid;

  /// The author's name, or empty when [anonymous].
  final String authorName;
  final String body;
  final bool anonymous;
  final PrayerStatus status;
  final DateTime createdAt;

  /// Set when staff act on it, so the moderation queue can show who
  /// handled a request without a separate audit lookup.
  final String moderatedBy;

  const PrayerPost({
    this.id = '',
    required this.uid,
    this.authorName = '',
    required this.body,
    this.anonymous = false,
    this.status = PrayerStatus.pending,
    required this.createdAt,
    this.moderatedBy = '',
  });

  factory PrayerPost.fromMap(String id, Map<String, dynamic> map) => PrayerPost(
        id: id,
        uid: map['uid'] as String? ?? '',
        authorName: map['authorName'] as String? ?? '',
        body: map['body'] as String? ?? '',
        anonymous: map['anonymous'] as bool? ?? false,
        status: PrayerStatus.values.firstWhere(
          (s) => s.name == map['status'],
          orElse: () => PrayerStatus.pending,
        ),
        createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ?? DateTime.now(),
        moderatedBy: map['moderatedBy'] as String? ?? '',
      );

  Map<String, dynamic> toMap() => {
        'uid': uid,
        // Never persist the name on an anonymous post. Storing it and
        // hiding it in the UI would leave it one query away.
        'authorName': anonymous ? '' : authorName,
        'body': body,
        'anonymous': anonymous,
        'status': status.name,
        'createdAt': createdAt.toIso8601String(),
        'moderatedBy': moderatedBy,
      };

  PrayerPost copyWith({PrayerStatus? status, String? moderatedBy}) => PrayerPost(
        id: id,
        uid: uid,
        authorName: authorName,
        body: body,
        anonymous: anonymous,
        status: status ?? this.status,
        createdAt: createdAt,
        moderatedBy: moderatedBy ?? this.moderatedBy,
      );

  String get displayName => anonymous || authorName.isEmpty ? 'Anonymous' : authorName;
}

/// One member praying for one post. A separate record rather than a
/// counter on the post, so "have I already prayed for this?" is
/// answerable and a second tap can't double-count.
@immutable
class PrayerIntercession {
  final String id;
  final String postId;
  final String uid;
  final DateTime prayedAt;

  const PrayerIntercession({
    this.id = '',
    required this.postId,
    required this.uid,
    required this.prayedAt,
  });

  factory PrayerIntercession.fromMap(String id, Map<String, dynamic> map) => PrayerIntercession(
        id: id,
        postId: map['postId'] as String? ?? '',
        uid: map['uid'] as String? ?? '',
        prayedAt: DateTime.tryParse(map['prayedAt'] as String? ?? '') ?? DateTime.now(),
      );

  Map<String, dynamic> toMap() => {
        'postId': postId,
        'uid': uid,
        'prayedAt': prayedAt.toIso8601String(),
      };
}

/// Deterministic id: the same trick as rsvpId, and it makes a second
/// "I prayed for this" tap idempotent for free.
String intercessionId(String postId, String uid) => '${postId}__$uid';
