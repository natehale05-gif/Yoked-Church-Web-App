import '../../../core/firestore/crud_repository.dart';
import '../domain/volunteering.dart';

abstract interface class VolunteerPositionRepository implements CrudRepository<VolunteerPosition> {}

abstract interface class VolunteerAssignmentRepository implements CrudRepository<VolunteerAssignment> {
  Future<List<VolunteerAssignment>> forMember(String uid);
  Future<List<VolunteerAssignment>> forPosition(String positionId);

  /// One batched read for many positions - avoids the per-position query
  /// loop the previous implementation used to build the "open slots" view.
  Future<List<VolunteerAssignment>> forPositions(List<String> positionIds);
}

mixin _PositionCodec implements EntityCodec<VolunteerPosition> {
  @override
  VolunteerPosition fromMap(String id, Map<String, dynamic> map) => VolunteerPosition.fromMap(id, map);
  @override
  Map<String, dynamic> toMap(VolunteerPosition entity) => entity.toMap();
  @override
  String idOf(VolunteerPosition entity) => entity.id;
}

mixin _AssignmentCodec implements EntityCodec<VolunteerAssignment> {
  @override
  VolunteerAssignment fromMap(String id, Map<String, dynamic> map) => VolunteerAssignment.fromMap(id, map);
  @override
  Map<String, dynamic> toMap(VolunteerAssignment entity) => entity.toMap();
  @override
  String idOf(VolunteerAssignment entity) => entity.id;
}

class FirestoreVolunteerPositionRepository extends FirestoreCrudRepository<VolunteerPosition>
    with _PositionCodec
    implements VolunteerPositionRepository {
  @override
  String get collectionPath => 'volunteerPositions';
  @override
  String? get orderByField => 'date';
}

class LocalVolunteerPositionRepository extends LocalCrudRepository<VolunteerPosition>
    with _PositionCodec
    implements VolunteerPositionRepository {
  @override
  String? get seedAsset => 'assets/data/volunteer_positions.json';
  @override
  int Function(VolunteerPosition, VolunteerPosition)? get sorter => (a, b) => a.date.compareTo(b.date);
}

class FirestoreVolunteerAssignmentRepository extends FirestoreCrudRepository<VolunteerAssignment>
    with _AssignmentCodec
    implements VolunteerAssignmentRepository {
  @override
  String get collectionPath => 'volunteerAssignments';

  @override
  Future<List<VolunteerAssignment>> forMember(String uid) => fetchWhere('uid', uid);

  @override
  Future<List<VolunteerAssignment>> forPosition(String positionId) => fetchWhere('positionId', positionId);

  @override
  Future<List<VolunteerAssignment>> forPositions(List<String> positionIds) =>
      fetchWhereIn('positionId', positionIds);
}

class LocalVolunteerAssignmentRepository extends LocalCrudRepository<VolunteerAssignment>
    with _AssignmentCodec
    implements VolunteerAssignmentRepository {
  @override
  String? get seedAsset => 'assets/data/volunteer_assignments.json';

  @override
  Future<List<VolunteerAssignment>> forMember(String uid) => fetchWhere((a) => a.uid == uid);

  @override
  Future<List<VolunteerAssignment>> forPosition(String positionId) =>
      fetchWhere((a) => a.positionId == positionId);

  @override
  Future<List<VolunteerAssignment>> forPositions(List<String> positionIds) =>
      fetchWhere((a) => positionIds.contains(a.positionId));
}
