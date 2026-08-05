import '../../../core/firestore/crud_repository.dart';
import '../domain/resource.dart';

abstract interface class ResourceRepository implements CrudRepository<Resource> {}

mixin _ResourceCodec implements EntityCodec<Resource> {
  @override
  Resource fromMap(String id, Map<String, dynamic> map) => Resource.fromMap(id, map);
  @override
  Map<String, dynamic> toMap(Resource entity) => entity.toMap();
  @override
  String idOf(Resource entity) => entity.id;
}

class FirestoreResourceRepository extends FirestoreCrudRepository<Resource>
    with _ResourceCodec
    implements ResourceRepository {
  FirestoreResourceRepository(super.churchId);

  @override
  String get collectionPath => 'resources';
  @override
  String? get orderByField => 'createdAt';
  @override
  bool get descending => true;
}

class LocalResourceRepository extends LocalCrudRepository<Resource>
    with _ResourceCodec
    implements ResourceRepository {
  LocalResourceRepository([super.churchId]);

  @override
  String? get seedAsset => 'assets/data/resources.json';
  @override
  int Function(Resource, Resource)? get sorter => (a, b) => b.createdAt.compareTo(a.createdAt);
}
