import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_providers.dart';
import '../../auth/domain/app_user.dart';
import '../../rooms/application/room_providers.dart';
import '../../rooms/domain/room.dart';
import '../data/check_in_repository.dart';
import '../domain/check_in.dart';

final checkInRepositoryProvider = Provider<CheckInRepository>((ref) {
  throw UnimplementedError('checkInRepositoryProvider must be overridden in ProviderScope');
});

final checkInRefreshProvider = StateProvider<int>((ref) => 0);

final allCheckInsProvider = FutureProvider<List<CheckInSession>>((ref) {
  ref.watch(checkInRefreshProvider);
  return ref.watch(checkInRepositoryProvider).fetchAll();
});

/// Everyone currently in the building. This is the roster a volunteer
/// works from, and the count that matters for room ratios.
final activeCheckInsProvider = Provider<List<CheckInSession>>((ref) {
  final all = ref.watch(allCheckInsProvider).valueOrNull ?? const <CheckInSession>[];
  return all.where((s) => s.isActive).toList();
});

final activeCheckInCountProvider = Provider<int>((ref) => ref.watch(activeCheckInsProvider).length);

/// Grouped by room, so the check-in desk can see at a glance which room
/// is filling up.
final checkInsByRoomProvider = Provider<Map<String, List<CheckInSession>>>((ref) {
  final grouped = <String, List<CheckInSession>>{};
  for (final session in ref.watch(activeCheckInsProvider)) {
    grouped.putIfAbsent(session.roomId, () => []).add(session);
  }
  return grouped;
});

/// A guardian's own children, so a parent can see the pickup code on
/// their phone rather than needing a paper slip.
final myCheckInsProvider = FutureProvider<List<CheckInSession>>((ref) async {
  ref.watch(checkInRefreshProvider);
  final uid = ref.watch(currentUserProvider)?.uid;
  if (uid == null) return const [];
  return ref.watch(checkInRepositoryProvider).forGuardian(uid);
});

/// Rooms available to check a child into. Deliberately the *non*-bookable
/// ones plus anything else staff have set up - a nursery is a check-in
/// room precisely because it is not a meeting space.
final checkInRoomsProvider = Provider<List<Room>>((ref) {
  return ref.watch(roomsProvider).valueOrNull ?? const <Room>[];
});

/// Children on this member's profile, offered as one-tap check-in.
/// A household member with a birth date is almost certainly a child.
final myHouseholdProvider = Provider<List<HouseholdMember>>((ref) {
  return ref.watch(currentUserProvider)?.household ?? const [];
});

final checkInControllerProvider = Provider<CheckInController>((ref) => CheckInController(ref));

class CheckInController {
  final Ref _ref;

  CheckInController(this._ref);

  /// Check a child in and mint a pickup code that is unique among the
  /// children currently in the building.
  Future<CheckInSession?> checkIn({
    required String childName,
    DateTime? childBirthDate,
    required Room room,
    required String guardianUid,
    String guardianName = '',
    String guardianPhone = '',
    String allergyNote = '',
  }) async {
    if (childName.trim().isEmpty) return null;

    // Read the live roster rather than a cached provider: two volunteers
    // checking children in on two tablets must not mint the same code.
    final all = await _ref.read(checkInRepositoryProvider).fetchAll();
    final inUse = all.where((s) => s.isActive).map((s) => s.pickupCode);

    final session = CheckInSession(
      childName: childName.trim(),
      childBirthDate: childBirthDate,
      guardianUid: guardianUid,
      guardianName: guardianName,
      guardianPhone: guardianPhone,
      roomId: room.id,
      roomName: room.name,
      allergyNote: allergyNote.trim(),
      checkedInAt: DateTime.now(),
      pickupCode: generatePickupCode(inUse),
    );

    final id = await _ref.read(checkInRepositoryProvider).create(session);
    _bump();
    return await _ref.read(checkInRepositoryProvider).fetchById(id) ?? session;
  }

  /// Release a child against a pickup code.
  ///
  /// The code is matched against *active* sessions only, and burning it
  /// is part of the same call - so a second attempt with the same code
  /// fails, and the volunteer is told when the child was already
  /// collected rather than getting a bare "invalid".
  Future<ReleaseResult> release({required String code, String releasedTo = ''}) async {
    final typed = code.trim().toUpperCase();
    if (typed.isEmpty) return const ReleaseResult.notFound();

    final all = await _ref.read(checkInRepositoryProvider).fetchAll();
    final matches = all.where((s) => s.pickupCode.toUpperCase() == typed).toList();
    if (matches.isEmpty) return const ReleaseResult.notFound();

    final active = matches.where((s) => s.isActive).toList();
    if (active.isEmpty) {
      // The code is real but spent. Naming when and to whom is what lets
      // a volunteer resolve a confused pickup.
      matches.sort((a, b) => (b.codeUsedAt ?? b.checkedInAt).compareTo(a.codeUsedAt ?? a.checkedInAt));
      return ReleaseResult.alreadyUsed(matches.first);
    }

    final session = active.first;
    final collected = session.copyWith(
      status: CheckInStatus.collected,
      codeUsedAt: DateTime.now(),
      releasedTo: releasedTo.trim(),
    );
    await _ref.read(checkInRepositoryProvider).update(collected);
    _bump();
    return ReleaseResult.success(collected);
  }

  /// Staff override, for the case the code is genuinely lost. Recorded
  /// as such rather than pretending a code was presented.
  Future<void> releaseWithoutCode(CheckInSession session, {required String releasedTo}) async {
    await _ref.read(checkInRepositoryProvider).update(
          session.copyWith(
            status: CheckInStatus.collected,
            codeUsedAt: DateTime.now(),
            releasedTo: releasedTo.trim().isEmpty ? 'staff override' : '${releasedTo.trim()} (staff override)',
          ),
        );
    _bump();
  }

  void _bump() => _ref.read(checkInRefreshProvider.notifier).state++;
}
