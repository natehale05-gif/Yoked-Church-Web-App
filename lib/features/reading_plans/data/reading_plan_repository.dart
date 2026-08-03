import '../../../core/firestore/crud_repository.dart';
import '../domain/reading_plan.dart';

abstract interface class ReadingPlanRepository implements CrudRepository<ReadingPlan> {}

abstract interface class PlanProgressRepository implements CrudRepository<PlanProgress> {
  Future<List<PlanProgress>> forMember(String uid);

  /// Deterministic id, so starting a plan twice updates one record
  /// rather than forking a member's history.
  Future<void> setProgress(PlanProgress progress);
}

mixin _PlanCodec implements EntityCodec<ReadingPlan> {
  @override
  ReadingPlan fromMap(String id, Map<String, dynamic> map) => ReadingPlan.fromMap(id, map);
  @override
  Map<String, dynamic> toMap(ReadingPlan entity) => entity.toMap();
  @override
  String idOf(ReadingPlan entity) => entity.id;
}

mixin _ProgressCodec implements EntityCodec<PlanProgress> {
  @override
  PlanProgress fromMap(String id, Map<String, dynamic> map) => PlanProgress.fromMap(id, map);
  @override
  Map<String, dynamic> toMap(PlanProgress entity) => entity.toMap();
  @override
  String idOf(PlanProgress entity) => entity.id;
}

class FirestoreReadingPlanRepository extends FirestoreCrudRepository<ReadingPlan>
    with _PlanCodec
    implements ReadingPlanRepository {
  @override
  String get collectionPath => 'readingPlans';
  @override
  String? get orderByField => 'title';
}

class LocalReadingPlanRepository extends LocalCrudRepository<ReadingPlan>
    with _PlanCodec
    implements ReadingPlanRepository {
  @override
  String? get seedAsset => 'assets/data/reading_plans.json';
  @override
  int Function(ReadingPlan, ReadingPlan)? get sorter => (a, b) => a.title.compareTo(b.title);
}

class FirestorePlanProgressRepository extends FirestoreCrudRepository<PlanProgress>
    with _ProgressCodec
    implements PlanProgressRepository {
  @override
  String get collectionPath => 'planProgress';

  @override
  Future<List<PlanProgress>> forMember(String uid) => fetchWhere('uid', uid);

  @override
  Future<void> setProgress(PlanProgress progress) =>
      collection.doc(progressId(progress.planId, progress.uid)).set(toMap(progress));
}

class LocalPlanProgressRepository extends LocalCrudRepository<PlanProgress>
    with _ProgressCodec
    implements PlanProgressRepository {
  @override
  String? get seedAsset => 'assets/data/plan_progress.json';

  @override
  Future<List<PlanProgress>> forMember(String uid) => fetchWhere((p) => p.uid == uid);

  @override
  Future<void> setProgress(PlanProgress progress) async {
    final id = progressId(progress.planId, progress.uid);
    await update(PlanProgress(
      id: id,
      uid: progress.uid,
      planId: progress.planId,
      completedDays: progress.completedDays,
      startedAt: progress.startedAt,
      lastReadAt: progress.lastReadAt,
    ));
  }
}
