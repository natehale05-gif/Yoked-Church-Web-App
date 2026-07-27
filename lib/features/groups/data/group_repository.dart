import '../../../core/firestore/crud_repository.dart';
import '../domain/group.dart';

abstract interface class GroupRepository implements CrudRepository<ChurchGroup> {}

abstract interface class MembershipRepository implements CrudRepository<GroupMembership> {
  Future<List<GroupMembership>> forMember(String uid);
  Future<List<GroupMembership>> forGroup(String groupId);
}

mixin _GroupCodec implements EntityCodec<ChurchGroup> {
  @override
  ChurchGroup fromMap(String id, Map<String, dynamic> map) => ChurchGroup.fromMap(id, map);
  @override
  Map<String, dynamic> toMap(ChurchGroup entity) => entity.toMap();
  @override
  String idOf(ChurchGroup entity) => entity.id;
}

mixin _MembershipCodec implements EntityCodec<GroupMembership> {
  @override
  GroupMembership fromMap(String id, Map<String, dynamic> map) => GroupMembership.fromMap(id, map);
  @override
  Map<String, dynamic> toMap(GroupMembership entity) => entity.toMap();
  @override
  String idOf(GroupMembership entity) => entity.id;
}

class FirestoreGroupRepository extends FirestoreCrudRepository<ChurchGroup>
    with _GroupCodec
    implements GroupRepository {
  @override
  String get collectionPath => 'groups';
  @override
  String? get orderByField => 'name';
}

class LocalGroupRepository extends LocalCrudRepository<ChurchGroup> with _GroupCodec implements GroupRepository {
  @override
  String? get seedAsset => 'assets/data/groups.json';
  @override
  int Function(ChurchGroup, ChurchGroup)? get sorter => (a, b) => a.name.compareTo(b.name);
}

class FirestoreMembershipRepository extends FirestoreCrudRepository<GroupMembership>
    with _MembershipCodec
    implements MembershipRepository {
  @override
  String get collectionPath => 'groupMemberships';

  @override
  Future<List<GroupMembership>> forMember(String uid) => fetchWhere('uid', uid);

  @override
  Future<List<GroupMembership>> forGroup(String groupId) => fetchWhere('groupId', groupId);
}

class LocalMembershipRepository extends LocalCrudRepository<GroupMembership>
    with _MembershipCodec
    implements MembershipRepository {
  @override
  Future<List<GroupMembership>> forMember(String uid) => fetchWhere((m) => m.uid == uid);

  @override
  Future<List<GroupMembership>> forGroup(String groupId) => fetchWhere((m) => m.groupId == groupId);
}
