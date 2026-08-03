import '../../../core/firestore/crud_repository.dart';
import '../domain/audit_entry.dart';

abstract interface class AuditRepository implements CrudRepository<AuditEntry> {}

mixin _AuditCodec implements EntityCodec<AuditEntry> {
  @override
  AuditEntry fromMap(String id, Map<String, dynamic> map) => AuditEntry.fromMap(id, map);
  @override
  Map<String, dynamic> toMap(AuditEntry entity) => entity.toMap();
  @override
  String idOf(AuditEntry entity) => entity.id;
}

class FirestoreAuditRepository extends FirestoreCrudRepository<AuditEntry>
    with _AuditCodec
    implements AuditRepository {
  FirestoreAuditRepository(super.churchId);

  @override
  String get collectionPath => 'auditLog';
  @override
  String? get orderByField => 'at';
  @override
  bool get descending => true;
}

class LocalAuditRepository extends LocalCrudRepository<AuditEntry> with _AuditCodec implements AuditRepository {
  @override
  String? get seedAsset => 'assets/data/audit_log.json';

  @override
  int Function(AuditEntry, AuditEntry)? get sorter => (a, b) => b.at.compareTo(a.at);
}
