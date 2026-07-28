import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_providers.dart';
import '../../notifications/application/notification_providers.dart';
import '../data/room_repository.dart';
import '../domain/room.dart';

final roomRepositoryProvider = Provider<RoomRepository>((ref) {
  throw UnimplementedError('roomRepositoryProvider must be overridden in ProviderScope');
});

final bookingRepositoryProvider = Provider<BookingRepository>((ref) {
  throw UnimplementedError('bookingRepositoryProvider must be overridden in ProviderScope');
});

final roomsProvider = StreamProvider<List<Room>>((ref) {
  return ref.watch(roomRepositoryProvider).watchAll();
});

/// Rooms a member may actually request. A nursery exists for check-in
/// but is not a meeting space, so it never reaches the booking form.
final bookableRoomsProvider = Provider<List<Room>>((ref) {
  return (ref.watch(roomsProvider).valueOrNull ?? const <Room>[]).where((r) => r.bookable).toList();
});

final bookingRefreshProvider = StateProvider<int>((ref) => 0);

final allBookingsProvider = FutureProvider<List<RoomBooking>>((ref) {
  ref.watch(bookingRefreshProvider);
  return ref.watch(bookingRepositoryProvider).fetchAll();
});

final myBookingsProvider = FutureProvider<List<RoomBooking>>((ref) async {
  ref.watch(bookingRefreshProvider);
  final uid = ref.watch(currentUserProvider)?.uid;
  if (uid == null) return const [];
  return ref.watch(bookingRepositoryProvider).forMember(uid);
});

final pendingBookingCountProvider = Provider<int>((ref) {
  final all = ref.watch(allBookingsProvider).valueOrNull ?? const <RoomBooking>[];
  return all.where((b) => b.status == BookingStatus.pending && !b.isPast).length;
});

/// The upcoming approved schedule, for the members-facing calendar.
final upcomingBookingsProvider = Provider<List<RoomBooking>>((ref) {
  final all = ref.watch(allBookingsProvider).valueOrNull ?? const <RoomBooking>[];
  return all.where((b) => b.holdsTheRoom && !b.isPast).toList()
    ..sort((a, b) => a.start.compareTo(b.start));
});

/// Why an approval was refused. Carries the clashing booking so the UI
/// can name it - "the room is taken" is useless to a staff member
/// deciding what to do next.
class BookingConflict {
  final RoomBooking existing;

  const BookingConflict(this.existing);
}

final roomControllerProvider = Provider<RoomController>((ref) => RoomController(ref));

class RoomController {
  final Ref _ref;

  RoomController(this._ref);

  /// A member's request always starts pending. It does not hold the room
  /// yet, which is why two people can both ask for Tuesday at 7.
  Future<void> request({
    required Room room,
    required String purpose,
    required DateTime start,
    required DateTime end,
    int expectedAttendance = 0,
  }) async {
    final user = _ref.read(currentUserProvider);
    if (user == null) return;

    final booking = RoomBooking(
      roomId: room.id,
      roomName: room.name,
      requestedByUid: user.uid,
      requestedByName: user.displayName,
      purpose: purpose.trim(),
      start: start,
      end: end,
      expectedAttendance: expectedAttendance,
      status: BookingStatus.pending,
    );
    if (!booking.isWellFormed) return;

    await _ref.read(bookingRepositoryProvider).create(booking);
    _bump();
  }

  /// Everything already approved for this room that would clash, ignoring
  /// [ignoring] so re-approving an existing booking doesn't collide with
  /// itself.
  Future<RoomBooking?> findConflict(RoomBooking candidate) async {
    final sameRoom = await _ref.read(bookingRepositoryProvider).forRoom(candidate.roomId);
    for (final other in sameRoom) {
      if (other.id == candidate.id) continue;
      if (!other.holdsTheRoom) continue;
      if (candidate.overlaps(other)) return other;
    }
    return null;
  }

  /// Staff action. The overlap check happens *here*, not at request time:
  /// two pending requests for the same slot are both legitimate
  /// questions, and only the second approval is the actual clash.
  ///
  /// Returns null on success, or the booking that blocked it.
  Future<BookingConflict?> approve(RoomBooking booking) async {
    final conflict = await findConflict(booking);
    if (conflict != null) return BookingConflict(conflict);

    final staff = _ref.read(currentUserProvider);
    await _ref.read(bookingRepositoryProvider).update(
          booking.copyWith(
            status: BookingStatus.approved,
            moderatedBy: staff?.displayName ?? 'Staff',
          ),
        );
    await _notify(booking, 'Your room booking is confirmed',
        '"${booking.purpose}" in ${booking.roomName} is booked.');
    _bump();
    return null;
  }

  Future<void> decline(RoomBooking booking, {String note = ''}) async {
    final staff = _ref.read(currentUserProvider);
    await _ref.read(bookingRepositoryProvider).update(
          booking.copyWith(
            status: BookingStatus.declined,
            staffNote: note,
            moderatedBy: staff?.displayName ?? 'Staff',
          ),
        );
    await _notify(booking, 'Room booking declined',
        note.isEmpty ? '"${booking.purpose}" could not be booked.' : note);
    _bump();
  }

  /// A member withdrawing their own request, or staff releasing a room.
  Future<void> cancel(RoomBooking booking) async {
    await _ref.read(bookingRepositoryProvider).update(booking.copyWith(status: BookingStatus.cancelled));
    _bump();
  }

  Future<void> deleteBooking(String id) async {
    await _ref.read(bookingRepositoryProvider).delete(id);
    _bump();
  }

  Future<void> _notify(RoomBooking booking, String title, String message) {
    return _ref.read(notificationSenderProvider).send(
          uid: booking.requestedByUid,
          title: title,
          message: message,
          linkPath: '/account/bookings',
          category: 'events',
        );
  }

  void _bump() => _ref.read(bookingRefreshProvider.notifier).state++;
}
