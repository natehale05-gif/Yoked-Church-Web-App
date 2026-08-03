import '../../../core/firestore/crud_repository.dart';
import '../domain/church_event.dart';

abstract interface class EventRepository implements CrudRepository<ChurchEvent> {}

mixin _EventCodec implements EntityCodec<ChurchEvent> {
  @override
  ChurchEvent fromMap(String id, Map<String, dynamic> map) => ChurchEvent.fromMap(id, map);
  @override
  Map<String, dynamic> toMap(ChurchEvent entity) => entity.toMap();
  @override
  String idOf(ChurchEvent entity) => entity.id;
}

class FirestoreEventRepository extends FirestoreCrudRepository<ChurchEvent>
    with _EventCodec
    implements EventRepository {
  FirestoreEventRepository(super.churchId);

  @override
  String get collectionPath => 'events';
  @override
  String? get orderByField => 'start';
}

class LocalEventRepository extends LocalCrudRepository<ChurchEvent> with _EventCodec implements EventRepository {
  @override
  String? get seedAsset => 'assets/data/events.json';
  @override
  int Function(ChurchEvent, ChurchEvent)? get sorter => (a, b) => a.start.compareTo(b.start);
}
