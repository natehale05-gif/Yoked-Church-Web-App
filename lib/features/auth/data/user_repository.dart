import '../../../core/firestore/crud_repository.dart';
import '../domain/app_user.dart';

abstract interface class UserRepository implements CrudRepository<AppUser> {
  Future<List<AppUser>> fetchDirectory();
  Future<void> updateRole(String uid, UserRole role);
}

mixin _UserCodec implements EntityCodec<AppUser> {
  @override
  AppUser fromMap(String id, Map<String, dynamic> map) => AppUser.fromMap(id, map);
  @override
  Map<String, dynamic> toMap(AppUser entity) => entity.toMap();
  @override
  String idOf(AppUser entity) => entity.uid;
}

class FirestoreUserRepository extends FirestoreCrudRepository<AppUser> with _UserCodec implements UserRepository {
  FirestoreUserRepository(super.churchId);

  @override
  String get collectionPath => 'users';
  @override
  String? get orderByField => 'displayName';

  @override
  Future<List<AppUser>> fetchDirectory() => fetchWhere('directoryOptIn', true);

  @override
  Future<void> updateRole(String uid, UserRole role) => collection.doc(uid).update({'role': role.name});

  /// Profiles are keyed by auth uid, not an auto-generated id.
  @override
  Future<String> create(AppUser entity) async {
    await collection.doc(entity.uid).set(toMap(entity));
    return entity.uid;
  }
}

class LocalUserRepository extends LocalCrudRepository<AppUser> with _UserCodec implements UserRepository {
  @override
  String? get seedAsset => 'assets/data/members.json';

  @override
  int Function(AppUser, AppUser)? get sorter => (a, b) => a.displayName.compareTo(b.displayName);

  @override
  Future<List<AppUser>> fetchDirectory() => fetchWhere((u) => u.directoryOptIn);

  @override
  Future<void> updateRole(String uid, UserRole role) async {
    final user = await fetchById(uid);
    if (user != null) await update(user.copyWith(role: role));
  }
}
