import 'package:flutter/foundation.dart';

/// One day of a plan. Days are embedded in the plan document rather than
/// held in a subcollection: a plan is small and always read whole, so
/// this is one read instead of one per day.
@immutable
class ReadingDay {
  final int dayNumber;
  final String reference;

  /// Optional devotional to pair with the reading.
  final String devotionalId;
  final String note;

  const ReadingDay({
    required this.dayNumber,
    required this.reference,
    this.devotionalId = '',
    this.note = '',
  });

  factory ReadingDay.fromMap(Map<String, dynamic> map) => ReadingDay(
        dayNumber: (map['dayNumber'] as num?)?.toInt() ?? 0,
        reference: map['reference'] as String? ?? '',
        devotionalId: map['devotionalId'] as String? ?? '',
        note: map['note'] as String? ?? '',
      );

  Map<String, dynamic> toMap() => {
        'dayNumber': dayNumber,
        'reference': reference,
        'devotionalId': devotionalId,
        'note': note,
      };
}

@immutable
class ReadingPlan {
  final String id;
  final String title;
  final String description;
  final List<ReadingDay> days;
  final bool published;

  const ReadingPlan({
    this.id = '',
    required this.title,
    this.description = '',
    this.days = const [],
    this.published = true,
  });

  factory ReadingPlan.fromMap(String id, Map<String, dynamic> map) {
    final raw = map['days'];
    final days = raw is List
        ? raw
            .whereType<Map<dynamic, dynamic>>()
            .map((d) => ReadingDay.fromMap(d.cast<String, dynamic>()))
            .toList()
        : <ReadingDay>[];
    days.sort((a, b) => a.dayNumber.compareTo(b.dayNumber));

    return ReadingPlan(
      id: id,
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      days: days,
      published: map['published'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() => {
        'title': title,
        'description': description,
        'days': days.map((d) => d.toMap()).toList(),
        'published': published,
      };

  ReadingPlan copyWith({
    String? id,
    String? title,
    String? description,
    List<ReadingDay>? days,
    bool? published,
  }) =>
      ReadingPlan(
        id: id ?? this.id,
        title: title ?? this.title,
        description: description ?? this.description,
        days: days ?? this.days,
        published: published ?? this.published,
      );

  int get dayCount => days.length;
}

/// One member's progress through one plan.
///
/// [completedDays] holds day *numbers*, not indexes, so reordering or
/// inserting a day in the plan can't silently re-point someone's history
/// at a different reading.
@immutable
class PlanProgress {
  final String id;
  final String uid;
  final String planId;
  final Set<int> completedDays;
  final DateTime startedAt;
  final DateTime lastReadAt;

  const PlanProgress({
    this.id = '',
    required this.uid,
    required this.planId,
    this.completedDays = const {},
    required this.startedAt,
    required this.lastReadAt,
  });

  factory PlanProgress.fromMap(String id, Map<String, dynamic> map) {
    final raw = map['completedDays'];
    return PlanProgress(
      id: id,
      uid: map['uid'] as String? ?? '',
      planId: map['planId'] as String? ?? '',
      completedDays: raw is List ? raw.whereType<num>().map((n) => n.toInt()).toSet() : const {},
      startedAt: DateTime.tryParse(map['startedAt'] as String? ?? '') ?? DateTime.now(),
      lastReadAt: DateTime.tryParse(map['lastReadAt'] as String? ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'planId': planId,
        // Sorted so the stored document is stable and diffable rather
        // than reordering on every write.
        'completedDays': (completedDays.toList()..sort()),
        'startedAt': startedAt.toIso8601String(),
        'lastReadAt': lastReadAt.toIso8601String(),
      };

  PlanProgress copyWith({Set<int>? completedDays, DateTime? lastReadAt}) => PlanProgress(
        id: id,
        uid: uid,
        planId: planId,
        completedDays: completedDays ?? this.completedDays,
        startedAt: startedAt,
        lastReadAt: lastReadAt ?? this.lastReadAt,
      );

  bool isDone(int dayNumber) => completedDays.contains(dayNumber);

  double fractionOf(ReadingPlan plan) {
    if (plan.dayCount == 0) return 0;
    // Count only days the plan still has, so removing a day from the
    // plan can't leave someone stuck above 100%.
    final live = plan.days.where((d) => completedDays.contains(d.dayNumber)).length;
    return live / plan.dayCount;
  }

  /// The next unread day, or null when the plan is finished.
  ReadingDay? nextDay(ReadingPlan plan) {
    for (final day in plan.days) {
      if (!completedDays.contains(day.dayNumber)) return day;
    }
    return null;
  }
}

/// Deterministic id, so a member has exactly one progress record per
/// plan and starting twice can't fork their history. Same approach as
/// `rsvpId(eventId, uid)`.
String progressId(String planId, String uid) => '${planId}__$uid';
