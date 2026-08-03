import '../../../core/firestore/crud_repository.dart';
import '../domain/check_in.dart';

abstract interface class CheckInRepository implements CrudRepository<CheckInSession> {
  Future<List<CheckInSession>> forGuardian(String uid);
  Future<List<CheckInSession>> forRoom(String roomId);
}

mixin _CheckInCodec implements EntityCodec<CheckInSession> {
  @override
  CheckInSession fromMap(String id, Map<String, dynamic> map) => CheckInSession.fromMap(id, map);
  @override
  Map<String, dynamic> toMap(CheckInSession entity) => entity.toMap();
  @override
  String idOf(CheckInSession entity) => entity.id;
}

class FirestoreCheckInRepository extends FirestoreCrudRepository<CheckInSession>
    with _CheckInCodec
    implements CheckInRepository {
  FirestoreCheckInRepository(super.churchId);

  @override
  String get collectionPath => 'checkIns';
  @override
  String? get orderByField => 'checkedInAt';
  @override
  bool get descending => true;

  @override
  Future<List<CheckInSession>> forGuardian(String uid) => fetchWhere('guardianUid', uid);

  @override
  Future<List<CheckInSession>> forRoom(String roomId) => fetchWhere('roomId', roomId);
}

class LocalCheckInRepository extends LocalCrudRepository<CheckInSession>
    with _CheckInCodec
    implements CheckInRepository {
  @override
  String? get seedAsset => 'assets/data/check_ins.json';

  @override
  int Function(CheckInSession, CheckInSession)? get sorter =>
      (a, b) => b.checkedInAt.compareTo(a.checkedInAt);

  @override
  Future<List<CheckInSession>> forGuardian(String uid) => fetchWhere((s) => s.guardianUid == uid);

  @override
  Future<List<CheckInSession>> forRoom(String roomId) => fetchWhere((s) => s.roomId == roomId);
}
