import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_providers.dart';
import '../data/rsvp_repository.dart';
import '../domain/church_event.dart';
import '../domain/event_rsvp.dart';
import 'event_providers.dart';

final rsvpRepositoryProvider = Provider<RsvpRepository>((ref) {
  throw UnimplementedError('rsvpRepositoryProvider must be overridden in ProviderScope');
});

final rsvpRefreshProvider = StateProvider<int>((ref) => 0);

final myRsvpsProvider = FutureProvider<List<EventRsvp>>((ref) async {
  ref.watch(rsvpRefreshProvider);
  final uid = ref.watch(currentUserProvider)?.uid;
  if (uid == null) return const [];
  return ref.watch(rsvpRepositoryProvider).forMember(uid);
});

/// Event ids the signed-in member has RSVP'd to. Read once per page
/// rather than per event row - the old implementation fired a query from
/// inside `build()` for every card on screen.
final myRsvpEventIdsProvider = Provider<Set<String>>((ref) {
  return (ref.watch(myRsvpsProvider).valueOrNull ?? const []).map((r) => r.eventId).toSet();
});

final myUpcomingEventsProvider = Provider<AsyncValue<List<ChurchEvent>>>((ref) {
  final rsvpIds = ref.watch(myRsvpEventIdsProvider);
  return ref.watch(upcomingEventsProvider).whenData(
        (events) => events.where((e) => rsvpIds.contains(e.id)).toList(),
      );
});

final eventRsvpsProvider = FutureProvider.family<List<EventRsvp>, String>((ref, eventId) {
  ref.watch(rsvpRefreshProvider);
  return ref.watch(rsvpRepositoryProvider).forEvent(eventId);
});

final rsvpControllerProvider = Provider<RsvpController>((ref) => RsvpController(ref));

class RsvpController {
  final Ref _ref;

  RsvpController(this._ref);

  Future<void> toggle(String eventId) async {
    final user = _ref.read(currentUserProvider);
    if (user == null) return;
    final repo = _ref.read(rsvpRepositoryProvider);

    if (_ref.read(myRsvpEventIdsProvider).contains(eventId)) {
      await repo.cancel(eventId: eventId, uid: user.uid);
    } else {
      await repo.setRsvp(EventRsvp(
        eventId: eventId,
        uid: user.uid,
        memberName: user.displayName,
        respondedAt: DateTime.now(),
      ));
    }
    _ref.read(rsvpRefreshProvider.notifier).state++;
  }
}
