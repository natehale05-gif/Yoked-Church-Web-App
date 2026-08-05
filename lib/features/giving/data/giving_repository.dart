import '../../../core/firestore/crud_repository.dart';
import '../domain/giving_record.dart';

abstract interface class GivingRepository implements CrudRepository<GivingRecord> {
  Future<List<GivingRecord>> forMember(String uid);
}

mixin _GivingCodec implements EntityCodec<GivingRecord> {
  @override
  GivingRecord fromMap(String id, Map<String, dynamic> map) => GivingRecord.fromMap(id, map);
  @override
  Map<String, dynamic> toMap(GivingRecord entity) => entity.toMap();
  @override
  String idOf(GivingRecord entity) => entity.id;
}

class FirestoreGivingRepository extends FirestoreCrudRepository<GivingRecord>
    with _GivingCodec
    implements GivingRepository {
  FirestoreGivingRepository(super.churchId);

  @override
  String get collectionPath => 'givingRecords';
  @override
  String? get orderByField => 'date';
  @override
  bool get descending => true;

  @override
  Future<List<GivingRecord>> forMember(String uid) => fetchWhere('uid', uid);
}

class LocalGivingRepository extends LocalCrudRepository<GivingRecord>
    with _GivingCodec
    implements GivingRepository {
  LocalGivingRepository([super.churchId]);

  @override
  String? get seedAsset => 'assets/data/giving.json';

  @override
  int Function(GivingRecord, GivingRecord)? get sorter => (a, b) => b.date.compareTo(a.date);

  @override
  Future<List<GivingRecord>> forMember(String uid) => fetchWhere((r) => r.uid == uid);
}
