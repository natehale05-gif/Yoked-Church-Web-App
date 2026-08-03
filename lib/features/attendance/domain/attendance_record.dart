import 'package:flutter/foundation.dart';

/// What was counted. The distinction is not cosmetic: it decides *how*
/// attendance is taken.
enum GatheringType {
  /// A Sunday service. Counted as a number - nobody scans four hundred
  /// people through a door.
  service,

  /// A one-off event. Also a headcount, though RSVPs give a starting
  /// guess.
  event,

  /// A small group. Counted person by person against the roster, because
  /// the pastoral question is *who* stopped coming, not how many chairs
  /// were filled.
  group,
}

/// One gathering, one date, one count.
///
/// Both modes live on the same record rather than in two collections:
/// a church's attendance history mixes services and groups, and the
/// reports page has to total across all of it.
@immutable
class AttendanceRecord {
  final String id;
  final GatheringType gatheringType;

  /// Event or group document id. For a service there is no document -
  /// service times are church settings, not records - so the label from
  /// [ChurchSettings.serviceTimes] stands in as the id.
  final String gatheringId;

  /// Denormalised so history still reads correctly after a group is
  /// renamed or an event is deleted. Attendance is a historical record;
  /// it should not develop holes because someone tidied up the calendar.
  final String gatheringName;

  final DateTime date;

  /// Used when [presentUids] is empty.
  final int headcount;

  /// Used for groups. Members of the roster who were actually there.
  final List<String> presentUids;

  final String note;
  final String recordedBy;

  const AttendanceRecord({
    this.id = '',
    required this.gatheringType,
    required this.gatheringId,
    this.gatheringName = '',
    required this.date,
    this.headcount = 0,
    this.presentUids = const [],
    this.note = '',
    this.recordedBy = '',
  });

  factory AttendanceRecord.fromMap(String id, Map<String, dynamic> map) => AttendanceRecord(
        id: id,
        gatheringType: GatheringType.values.firstWhere(
          (t) => t.name == map['gatheringType'],
          orElse: () => GatheringType.service,
        ),
        gatheringId: map['gatheringId'] as String? ?? '',
        gatheringName: map['gatheringName'] as String? ?? '',
        date: DateTime.tryParse(map['date'] as String? ?? '') ?? DateTime.now(),
        headcount: (map['headcount'] as num?)?.toInt() ?? 0,
        presentUids: (map['presentUids'] as List<dynamic>? ?? const []).whereType<String>().toList(),
        note: map['note'] as String? ?? '',
        recordedBy: map['recordedBy'] as String? ?? '',
      );

  Map<String, dynamic> toMap() => {
        'gatheringType': gatheringType.name,
        'gatheringId': gatheringId,
        'gatheringName': gatheringName,
        'date': date.toIso8601String(),
        'headcount': headcount,
        'presentUids': presentUids,
        'note': note,
        'recordedBy': recordedBy,
      };

  AttendanceRecord copyWith({
    int? headcount,
    List<String>? presentUids,
    String? note,
    String? recordedBy,
  }) =>
      AttendanceRecord(
        id: id,
        gatheringType: gatheringType,
        gatheringId: gatheringId,
        gatheringName: gatheringName,
        date: date,
        headcount: headcount ?? this.headcount,
        presentUids: presentUids ?? this.presentUids,
        note: note ?? this.note,
        recordedBy: recordedBy ?? this.recordedBy,
      );

  /// The number this record contributes to any total.
  ///
  /// A per-person record is authoritative about its own size, so the
  /// roster wins whenever it has anyone in it. A history mixing both
  /// modes still adds up, which is the whole reason for one model.
  int get effectiveCount => presentUids.isNotEmpty ? presentUids.length : headcount;

  bool get isPerPerson => presentUids.isNotEmpty;

  bool wasPresent(String uid) => presentUids.contains(uid);
}

/// One record per gathering per day.
///
/// Deterministic, so recording Sunday twice corrects the number instead
/// of counting the congregation twice - the same reason RSVPs and
/// reading-plan progress use composite ids.
String attendanceId(GatheringType type, String gatheringId, DateTime date) =>
    '${type.name}__${gatheringId}__${dateKey(date)}';

/// Date-only key. Attendance is taken for a day, not an instant, so the
/// time component must never split one gathering into two records.
String dateKey(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

DateTime dayOf(DateTime date) => DateTime(date.year, date.month, date.day);

/// A gathering's history, newest first, with its running total.
@immutable
class AttendanceSeries {
  final GatheringType type;
  final String gatheringId;
  final String gatheringName;
  final List<AttendanceRecord> records;

  const AttendanceSeries({
    required this.type,
    required this.gatheringId,
    required this.gatheringName,
    required this.records,
  });

  int get total => records.fold(0, (sum, r) => sum + r.effectiveCount);

  int get occasions => records.length;

  /// Rounded, because a church talks about "about ninety on a Sunday" -
  /// a decimal average would imply a precision headcounts don't have.
  int get average => records.isEmpty ? 0 : (total / records.length).round();

  AttendanceRecord? get latest => records.isEmpty ? null : records.first;

  /// Group by gathering, newest first within each. Pure, so the reports
  /// page and the group-leader view share one definition of "history".
  static List<AttendanceSeries> group(List<AttendanceRecord> records) {
    final buckets = <String, List<AttendanceRecord>>{};
    for (final record in records) {
      buckets.putIfAbsent('${record.gatheringType.name}__${record.gatheringId}', () => []).add(record);
    }

    final series = buckets.values.map((list) {
      final sorted = list..sort((a, b) => b.date.compareTo(a.date));
      return AttendanceSeries(
        type: sorted.first.gatheringType,
        gatheringId: sorted.first.gatheringId,
        gatheringName: sorted.first.gatheringName,
        records: sorted,
      );
    }).toList();

    series.sort((a, b) {
      final byType = a.type.index.compareTo(b.type.index);
      return byType != 0 ? byType : a.gatheringName.compareTo(b.gatheringName);
    });
    return series;
  }
}
