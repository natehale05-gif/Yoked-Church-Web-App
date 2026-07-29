import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/settings_providers.dart';
import '../../auth/application/auth_providers.dart';
import '../../events/application/event_providers.dart';
import '../../events/domain/church_event.dart';
import '../../groups/application/group_providers.dart';
import '../../groups/domain/group.dart';
import '../data/attendance_repository.dart';
import '../domain/attendance_record.dart';

final attendanceRepositoryProvider = Provider<AttendanceRepository>((ref) {
  throw UnimplementedError('attendanceRepositoryProvider must be overridden in ProviderScope');
});

final attendanceRefreshProvider = StateProvider<int>((ref) => 0);

final allAttendanceProvider = FutureProvider<List<AttendanceRecord>>((ref) {
  ref.watch(attendanceRefreshProvider);
  return ref.watch(attendanceRepositoryProvider).fetchAll();
});

/// Every gathering a record can be filed against, as one flat list for the
/// picker. Services come from church settings rather than a collection -
/// a service time is configuration, not a document - so its label doubles
/// as its id.
typedef Gathering = ({GatheringType type, String id, String name});

final gatheringsProvider = Provider<List<Gathering>>((ref) {
  final settings = ref.watch(settingsProvider);
  final groups = ref.watch(groupsProvider).valueOrNull ?? const <ChurchGroup>[];

  // Newest first, and past events included: attendance is recorded after
  // a gathering happens, so an "upcoming only" list would offer exactly
  // the events nobody can count yet.
  final events = [...ref.watch(allEventsProvider).valueOrNull ?? const <ChurchEvent>[]]
    ..sort((a, b) => b.start.compareTo(a.start));

  return [
    for (final service in settings.serviceTimes)
      (
        type: GatheringType.service,
        id: '${service.day} ${service.time}'.trim(),
        name: service.label.isEmpty
            ? '${service.day} ${service.time}'.trim()
            : '${service.label} (${service.day} ${service.time})',
      ),
    for (final event in events) (type: GatheringType.event, id: event.id, name: event.title),
    for (final group in groups) (type: GatheringType.group, id: group.id, name: group.name),
  ];
});

/// The whole history, grouped. Both the admin history list and the
/// reports page read this so they can never disagree about a total.
final attendanceSeriesProvider = Provider<List<AttendanceSeries>>((ref) {
  return AttendanceSeries.group(ref.watch(allAttendanceProvider).valueOrNull ?? const []);
});

final gatheringHistoryProvider =
    FutureProvider.family<List<AttendanceRecord>, String>((ref, gatheringId) async {
  ref.watch(attendanceRefreshProvider);
  final records = await ref.watch(attendanceRepositoryProvider).forGathering(gatheringId);
  return records..sort((a, b) => b.date.compareTo(a.date));
});

/// Groups the signed-in member leads. Empty for almost everyone, which is
/// why the group-leader panel hides itself entirely rather than showing an
/// empty state.
final myLedGroupsProvider = Provider<List<ChurchGroup>>((ref) {
  final uid = ref.watch(currentUserProvider)?.uid;
  if (uid == null || uid.isEmpty) return const [];
  final groups = ref.watch(groupsProvider).valueOrNull ?? const <ChurchGroup>[];
  return groups.where((g) => g.leaderUid == uid).toList();
});

final attendanceControllerProvider =
    Provider<AttendanceController>((ref) => AttendanceController(ref));

class AttendanceController {
  final Ref _ref;

  AttendanceController(this._ref);

  /// Services and events: a number and a date.
  Future<void> recordHeadcount({
    required Gathering gathering,
    required DateTime date,
    required int headcount,
    String note = '',
  }) async {
    if (headcount < 0) return;
    await _save(AttendanceRecord(
      gatheringType: gathering.type,
      gatheringId: gathering.id,
      gatheringName: gathering.name,
      date: dayOf(date),
      headcount: headcount,
      note: note.trim(),
      recordedBy: _who,
    ));
  }

  /// Groups: the roster, ticked.
  ///
  /// An empty roster is stored as a headcount of zero rather than an empty
  /// per-person record, so "nobody came" survives the round trip instead
  /// of reading as "attendance was never taken".
  Future<void> recordRoster({
    required Gathering gathering,
    required DateTime date,
    required List<String> presentUids,
    String note = '',
  }) async {
    await _save(AttendanceRecord(
      gatheringType: gathering.type,
      gatheringId: gathering.id,
      gatheringName: gathering.name,
      date: dayOf(date),
      headcount: 0,
      presentUids: presentUids,
      note: note.trim(),
      recordedBy: _who,
    ));
  }

  Future<void> deleteRecord(String id) async {
    await _ref.read(attendanceRepositoryProvider).delete(id);
    _bump();
  }

  Future<void> _save(AttendanceRecord record) async {
    await _ref.read(attendanceRepositoryProvider).setRecord(record);
    _bump();
  }

  String get _who => _ref.read(currentUserProvider)?.displayName ?? 'Staff';

  void _bump() => _ref.read(attendanceRefreshProvider.notifier).state++;
}
