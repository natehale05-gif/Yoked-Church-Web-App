import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_providers.dart';
import '../../notifications/application/notification_providers.dart';
import '../data/volunteering_repository.dart';
import '../domain/volunteering.dart';

final volunteerPositionRepositoryProvider = Provider<VolunteerPositionRepository>((ref) {
  throw UnimplementedError('volunteerPositionRepositoryProvider must be overridden in ProviderScope');
});

final volunteerAssignmentRepositoryProvider = Provider<VolunteerAssignmentRepository>((ref) {
  throw UnimplementedError('volunteerAssignmentRepositoryProvider must be overridden in ProviderScope');
});

final volunteerRefreshProvider = StateProvider<int>((ref) => 0);

final volunteerPositionsProvider = StreamProvider<List<VolunteerPosition>>((ref) {
  return ref.watch(volunteerPositionRepositoryProvider).watchAll();
});

final myAssignmentsProvider = FutureProvider<List<VolunteerAssignment>>((ref) async {
  ref.watch(volunteerRefreshProvider);
  final uid = ref.watch(currentUserProvider)?.uid;
  if (uid == null) return const [];
  return ref.watch(volunteerAssignmentRepositoryProvider).forMember(uid);
});

final positionAssignmentsProvider =
    FutureProvider.family<List<VolunteerAssignment>, String>((ref, positionId) {
  ref.watch(volunteerRefreshProvider);
  return ref.watch(volunteerAssignmentRepositoryProvider).forPosition(positionId);
});

/// Staff view of every assignment - used for the "requests waiting on
/// you" count on the admin overview.
final allAssignmentsProvider = FutureProvider<List<VolunteerAssignment>>((ref) {
  ref.watch(volunteerRefreshProvider);
  return ref.watch(volunteerAssignmentRepositoryProvider).fetchAll();
});

/// Remaining slots per position, computed from a single batched read of
/// all assignments rather than one query per position.
final openSlotsProvider = FutureProvider<Map<String, int>>((ref) async {
  ref.watch(volunteerRefreshProvider);
  final positions = await ref.watch(volunteerPositionsProvider.future);
  if (positions.isEmpty) return const {};

  final assignments = await ref
      .watch(volunteerAssignmentRepositoryProvider)
      .forPositions(positions.map((p) => p.id).toList());

  final filled = <String, int>{};
  for (final assignment in assignments.where((a) => a.countsTowardSlots)) {
    filled.update(assignment.positionId, (v) => v + 1, ifAbsent: () => 1);
  }
  return {
    for (final position in positions) position.id: position.slotsNeeded - (filled[position.id] ?? 0),
  };
});

final volunteerControllerProvider = Provider<VolunteerController>((ref) => VolunteerController(ref));

class VolunteerController {
  final Ref _ref;

  VolunteerController(this._ref);

  VolunteerAssignmentRepository get _assignments => _ref.read(volunteerAssignmentRepositoryProvider);

  /// Member action: request a slot. Always pending until staff approve.
  Future<void> signUp(String positionId) async {
    final user = _ref.read(currentUserProvider);
    if (user == null) return;
    await _assignments.create(VolunteerAssignment(
      positionId: positionId,
      uid: user.uid,
      memberName: user.displayName,
      status: AssignmentStatus.pending,
      assignedBy: 'self',
      assignedAt: DateTime.now(),
    ));
    _bump();
  }

  /// Staff action: assign someone directly. Confirmed immediately, since
  /// a staff member has already made the call - and the member is told.
  Future<void> assign({required VolunteerPosition position, required String uid, required String memberName}) async {
    final admin = _ref.read(currentUserProvider);
    await _assignments.create(VolunteerAssignment(
      positionId: position.id,
      uid: uid,
      memberName: memberName,
      status: AssignmentStatus.approved,
      assignedBy: admin?.uid ?? 'staff',
      assignedAt: DateTime.now(),
    ));
    await _notifyAssigned(position, uid);
    _bump();
  }

  /// Staff action: approve a pending self-signup. This is the moment it
  /// becomes a real commitment, so this is when the member is notified.
  Future<void> approve(VolunteerAssignment assignment, VolunteerPosition position) async {
    await _assignments.update(assignment.copyWith(status: AssignmentStatus.approved));
    await _notifyAssigned(position, assignment.uid);
    _bump();
  }

  Future<void> decline(VolunteerAssignment assignment) async {
    await _assignments.update(assignment.copyWith(status: AssignmentStatus.declined));
    _bump();
  }

  Future<void> remove(String assignmentId) async {
    await _assignments.delete(assignmentId);
    _bump();
  }

  Future<void> _notifyAssigned(VolunteerPosition position, String uid) {
    return _ref.read(notificationSenderProvider).send(
          uid: uid,
          title: "You're serving!",
          message: 'You have been confirmed for "${position.title}".',
          linkPath: '/account/volunteering',
          category: 'volunteering',
        );
  }

  void _bump() => _ref.read(volunteerRefreshProvider.notifier).state++;
}
