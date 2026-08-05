import '../../../core/firestore/crud_repository.dart';
import '../domain/church_info.dart';

abstract interface class StaffRepository implements CrudRepository<StaffMember> {}

abstract interface class LocationRepository implements CrudRepository<ChurchLocation> {}

abstract interface class FaqRepository implements CrudRepository<Faq> {}

mixin _StaffCodec implements EntityCodec<StaffMember> {
  @override
  StaffMember fromMap(String id, Map<String, dynamic> map) => StaffMember.fromMap(id, map);
  @override
  Map<String, dynamic> toMap(StaffMember entity) => entity.toMap();
  @override
  String idOf(StaffMember entity) => entity.id;
}

mixin _LocationCodec implements EntityCodec<ChurchLocation> {
  @override
  ChurchLocation fromMap(String id, Map<String, dynamic> map) => ChurchLocation.fromMap(id, map);
  @override
  Map<String, dynamic> toMap(ChurchLocation entity) => entity.toMap();
  @override
  String idOf(ChurchLocation entity) => entity.id;
}

mixin _FaqCodec implements EntityCodec<Faq> {
  @override
  Faq fromMap(String id, Map<String, dynamic> map) => Faq.fromMap(id, map);
  @override
  Map<String, dynamic> toMap(Faq entity) => entity.toMap();
  @override
  String idOf(Faq entity) => entity.id;
}

class FirestoreStaffRepository extends FirestoreCrudRepository<StaffMember>
    with _StaffCodec
    implements StaffRepository {
  FirestoreStaffRepository(super.churchId);

  @override
  String get collectionPath => 'staffMembers';
  @override
  String? get orderByField => 'sortOrder';
}

class LocalStaffRepository extends LocalCrudRepository<StaffMember> with _StaffCodec implements StaffRepository {
  LocalStaffRepository([super.churchId]);

  @override
  String? get seedAsset => 'assets/data/staff.json';
  @override
  int Function(StaffMember, StaffMember)? get sorter => (a, b) => a.sortOrder.compareTo(b.sortOrder);
}

class FirestoreLocationRepository extends FirestoreCrudRepository<ChurchLocation>
    with _LocationCodec
    implements LocationRepository {
  FirestoreLocationRepository(super.churchId);

  @override
  String get collectionPath => 'locations';
  @override
  String? get orderByField => 'sortOrder';
}

class LocalLocationRepository extends LocalCrudRepository<ChurchLocation>
    with _LocationCodec
    implements LocationRepository {
  LocalLocationRepository([super.churchId]);

  @override
  String? get seedAsset => 'assets/data/locations.json';
  @override
  int Function(ChurchLocation, ChurchLocation)? get sorter => (a, b) => a.sortOrder.compareTo(b.sortOrder);
}

class FirestoreFaqRepository extends FirestoreCrudRepository<Faq> with _FaqCodec implements FaqRepository {
  FirestoreFaqRepository(super.churchId);

  @override
  String get collectionPath => 'faqs';
  @override
  String? get orderByField => 'sortOrder';
}

class LocalFaqRepository extends LocalCrudRepository<Faq> with _FaqCodec implements FaqRepository {
  LocalFaqRepository([super.churchId]);

  @override
  String? get seedAsset => 'assets/data/faqs.json';
  @override
  int Function(Faq, Faq)? get sorter => (a, b) => a.sortOrder.compareTo(b.sortOrder);
}
