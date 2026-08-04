import '../../../core/firestore/crud_repository.dart';
import '../domain/connect_submission.dart';

abstract interface class ConnectRepository implements CrudRepository<ConnectSubmission> {}

mixin _ConnectCodec implements EntityCodec<ConnectSubmission> {
  @override
  ConnectSubmission fromMap(String id, Map<String, dynamic> map) => ConnectSubmission.fromMap(id, map);
  @override
  Map<String, dynamic> toMap(ConnectSubmission entity) => entity.toMap();
  @override
  String idOf(ConnectSubmission entity) => entity.id;
}

class FirestoreConnectRepository extends FirestoreCrudRepository<ConnectSubmission>
    with _ConnectCodec
    implements ConnectRepository {
  FirestoreConnectRepository(super.churchId);

  @override
  String get collectionPath => 'submissions';
  @override
  String? get orderByField => 'submittedAt';
  @override
  bool get descending => true;
}

/// Keeps submissions in memory only. In the no-backend demo mode there is
/// nowhere durable to send them, so the Connect screen tells the visitor
/// to email the church directly rather than silently dropping the message.
class LocalConnectRepository extends LocalCrudRepository<ConnectSubmission>
    with _ConnectCodec
    implements ConnectRepository {
  LocalConnectRepository([super.churchId]);

  @override
  String? get seedAsset => 'assets/data/connect_submissions.json';

  @override
  int Function(ConnectSubmission, ConnectSubmission)? get sorter =>
      (a, b) => b.submittedAt.compareTo(a.submittedAt);
}
