/// A single attendance record for one gathering on one date.
class AttendanceRecord {
  final String id;
  final DateTime date;
  final String serviceLabel;
  final List<String> presentMemberIds;
  final int visitorCount;
  final String note;

  AttendanceRecord({
    String? id,
    required this.date,
    required this.serviceLabel,
    List<String>? presentMemberIds,
    this.visitorCount = 0,
    this.note = '',
  })  : id = id ??
            '${DateTime.now().microsecondsSinceEpoch}_${DateTime.now().microsecond}',
        presentMemberIds = presentMemberIds ?? const [];

  int get total => presentMemberIds.length + visitorCount;

  AttendanceRecord copyWith({
    DateTime? date,
    String? serviceLabel,
    List<String>? presentMemberIds,
    int? visitorCount,
    String? note,
  }) =>
      AttendanceRecord(
        id: id,
        date: date ?? this.date,
        serviceLabel: serviceLabel ?? this.serviceLabel,
        presentMemberIds: presentMemberIds ?? this.presentMemberIds,
        visitorCount: visitorCount ?? this.visitorCount,
        note: note ?? this.note,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'serviceLabel': serviceLabel,
        'presentMemberIds': presentMemberIds,
        'visitorCount': visitorCount,
        'note': note,
      };

  factory AttendanceRecord.fromJson(Map<String, dynamic> j) => AttendanceRecord(
        id: j['id'],
        date: DateTime.tryParse(j['date'] ?? '') ?? DateTime.now(),
        serviceLabel: j['serviceLabel'] ?? '',
        presentMemberIds: (j['presentMemberIds'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
        visitorCount: (j['visitorCount'] ?? 0) as int,
        note: j['note'] ?? '',
      );
}
