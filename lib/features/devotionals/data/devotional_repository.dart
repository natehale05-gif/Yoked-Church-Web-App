import '../../../core/firestore/crud_repository.dart';
import '../domain/devotional.dart';

abstract interface class DevotionalRepository implements CrudRepository<Devotional> {}

mixin _DevotionalCodec implements EntityCodec<Devotional> {
  @override
  Devotional fromMap(String id, Map<String, dynamic> map) => Devotional.fromMap(id, map);
  @override
  Map<String, dynamic> toMap(Devotional entity) => entity.toMap();
  @override
  String idOf(Devotional entity) => entity.id;
}

class FirestoreDevotionalRepository extends FirestoreCrudRepository<Devotional>
    with _DevotionalCodec
    implements DevotionalRepository {
  FirestoreDevotionalRepository(super.churchId);

  @override
  String get collectionPath => 'devotionals';
  @override
  String? get orderByField => 'publishDate';
  @override
  bool get descending => true;
}

class LocalDevotionalRepository extends LocalCrudRepository<Devotional>
    with _DevotionalCodec
    implements DevotionalRepository {
  @override
  String? get seedAsset => 'assets/data/devotionals.json';
  @override
  int Function(Devotional, Devotional)? get sorter => (a, b) => b.publishDate.compareTo(a.publishDate);
}
