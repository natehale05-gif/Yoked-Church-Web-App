import '../../../core/firestore/crud_repository.dart';
import '../domain/event_rsvp.dart';

abstract interface class RsvpRepository implements CrudRepository<EventRsvp> {
  Future<List<EventRsvp>> forMember(String uid);
  Future<List<EventRsvp>> forEvent(String eventId);

  /// Deterministic id so a member can never double-RSVP to one event.
  Future<void> setRsvp(EventRsvp rsvp);
  Future<void> cancel({required String eventId, required String uid});
}

String rsvpId(String eventId, String uid) => '${eventId}__$uid';

mixin _RsvpCodec implements EntityCodec<EventRsvp> {
  @override
  EventRsvp fromMap(String id, Map<String, dynamic> map) => EventRsvp.fromMap(id, map);
  @override
  Map<String, dynamic> toMap(EventRsvp entity) => entity.toMap();
  @override
  String idOf(EventRsvp entity) => entity.id;
}

class FirestoreRsvpRepository extends FirestoreCrudRepository<EventRsvp> with _RsvpCodec implements RsvpRepository {
  FirestoreRsvpRepository(super.churchId);

  @override
  String get collectionPath => 'eventRsvps';

  @override
  Future<List<EventRsvp>> forMember(String uid) => fetchWhere('uid', uid);

  @override
  Future<List<EventRsvp>> forEvent(String eventId) => fetchWhere('eventId', eventId);

  @override
  Future<void> setRsvp(EventRsvp rsvp) =>
      collection.doc(rsvpId(rsvp.eventId, rsvp.uid)).set(toMap(rsvp));

  @override
  Future<void> cancel({required String eventId, required String uid}) =>
      collection.doc(rsvpId(eventId, uid)).delete();
}

class LocalRsvpRepository extends LocalCrudRepository<EventRsvp> with _RsvpCodec implements RsvpRepository {
  LocalRsvpRepository([super.churchId]);

  @override
  String? get seedAsset => 'assets/data/event_rsvps.json';

  @override
  Future<List<EventRsvp>> forMember(String uid) => fetchWhere((r) => r.uid == uid);

  @override
  Future<List<EventRsvp>> forEvent(String eventId) => fetchWhere((r) => r.eventId == eventId);

  @override
  Future<void> setRsvp(EventRsvp rsvp) async {
    final id = rsvpId(rsvp.eventId, rsvp.uid);
    await update(EventRsvp(
      id: id,
      eventId: rsvp.eventId,
      uid: rsvp.uid,
      memberName: rsvp.memberName,
      partySize: rsvp.partySize,
      respondedAt: rsvp.respondedAt,
    ));
  }

  @override
  Future<void> cancel({required String eventId, required String uid}) => delete(rsvpId(eventId, uid));
}
