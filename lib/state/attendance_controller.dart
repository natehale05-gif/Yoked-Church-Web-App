import 'package:flutter/foundation.dart';

import '../data/local_store.dart';
import '../data/seed.dart';
import '../models/attendance.dart';

class AttendanceController extends ChangeNotifier {
  AttendanceController(this._store) {
    if (_store.contains(_key)) {
      _records = _store.readList(_key).map(AttendanceRecord.fromJson).toList();
    } else {
      _records = defaultAttendance();
      _persist();
    }
  }

  static const _key = 'attendance';
  final LocalStore _store;
  late List<AttendanceRecord> _records;

  /// Most recent first.
  List<AttendanceRecord> get records {
    final list = [..._records];
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  AttendanceRecord? get latest => records.isEmpty ? null : records.first;

  double get averageTotal {
    if (_records.isEmpty) return 0;
    final sum = _records.fold<int>(0, (a, r) => a + r.total);
    return sum / _records.length;
  }

  /// How many recorded gatherings a member has attended.
  int attendedCountFor(String memberId) =>
      _records.where((r) => r.presentMemberIds.contains(memberId)).length;

  Future<void> upsert(AttendanceRecord record) async {
    final i = _records.indexWhere((r) => r.id == record.id);
    if (i >= 0) {
      _records[i] = record;
    } else {
      _records.add(record);
    }
    await _persist();
    notifyListeners();
  }

  Future<void> remove(String id) async {
    _records.removeWhere((r) => r.id == id);
    await _persist();
    notifyListeners();
  }

  Future<void> _persist() =>
      _store.writeList(_key, _records.map((r) => r.toJson()).toList());
}
