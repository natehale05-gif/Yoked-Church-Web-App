import '../../../core/firestore/crud_repository.dart';
import '../domain/attendance_record.dart';

abstract interface class AttendanceRepository implements CrudRepository<AttendanceRecord> {
  Future<List<AttendanceRecord>> forGathering(String gatheringId);

  /// Upsert under the deterministic id, so taking attendance twice for
  /// one Sunday corrects the record rather than doubling it.
  Future<void> setRecord(AttendanceRecord record);
}

mixin _AttendanceCodec implements EntityCodec<AttendanceRecord> {
  @override
  AttendanceRecord fromMap(String id, Map<String, dynamic> map) => AttendanceRecord.fromMap(id, map);
  @override
  Map<String, dynamic> toMap(AttendanceRecord entity) => entity.toMap();
  @override
  String idOf(AttendanceRecord entity) => entity.id;
}

class FirestoreAttendanceRepository extends FirestoreCrudRepository<AttendanceRecord>
    with _AttendanceCodec
    implements AttendanceRepository {
  @override
  String get collectionPath => 'attendanceRecords';
  @override
  String? get orderByField => 'date';
  @override
  bool get descending => true;

  @override
  Future<List<AttendanceRecord>> forGathering(String gatheringId) => fetchWhere('gatheringId', gatheringId);

  @override
  Future<void> setRecord(AttendanceRecord record) => collection
      .doc(attendanceId(record.gatheringType, record.gatheringId, record.date))
      .set(toMap(record));
}

class LocalAttendanceRepository extends LocalCrudRepository<AttendanceRecord>
    with _AttendanceCodec
    implements AttendanceRepository {
  @override
  String? get seedAsset => 'assets/data/attendance.json';
  @override
  int Function(AttendanceRecord, AttendanceRecord)? get sorter => (a, b) => b.date.compareTo(a.date);

  @override
  Future<List<AttendanceRecord>> forGathering(String gatheringId) =>
      fetchWhere((r) => r.gatheringId == gatheringId);

  @override
  Future<void> setRecord(AttendanceRecord record) => update(AttendanceRecord(
        id: attendanceId(record.gatheringType, record.gatheringId, record.date),
        gatheringType: record.gatheringType,
        gatheringId: record.gatheringId,
        gatheringName: record.gatheringName,
        date: record.date,
        headcount: record.headcount,
        presentUids: record.presentUids,
        note: record.note,
        recordedBy: record.recordedBy,
      ));
}
