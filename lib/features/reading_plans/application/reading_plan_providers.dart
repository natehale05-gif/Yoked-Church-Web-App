import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_providers.dart';
import '../data/reading_plan_repository.dart';
import '../domain/reading_plan.dart';

final readingPlanRepositoryProvider = Provider<ReadingPlanRepository>((ref) {
  throw UnimplementedError('readingPlanRepositoryProvider must be overridden in ProviderScope');
});

final planProgressRepositoryProvider = Provider<PlanProgressRepository>((ref) {
  throw UnimplementedError('planProgressRepositoryProvider must be overridden in ProviderScope');
});

/// Everything, including drafts - the staff CMS.
final allReadingPlansProvider = StreamProvider<List<ReadingPlan>>((ref) {
  return ref.watch(readingPlanRepositoryProvider).watchAll();
});

final publishedReadingPlansProvider = Provider<AsyncValue<List<ReadingPlan>>>((ref) {
  return ref.watch(allReadingPlansProvider).whenData((all) => all.where((p) => p.published).toList());
});

final readingPlanByIdProvider = FutureProvider.family<ReadingPlan?, String>((ref, id) {
  return ref.watch(readingPlanRepositoryProvider).fetchById(id);
});

/// Bumped after any progress write so dependent views refetch.
final progressRefreshProvider = StateProvider<int>((ref) => 0);

final myProgressProvider = FutureProvider<List<PlanProgress>>((ref) async {
  ref.watch(progressRefreshProvider);
  final uid = ref.watch(currentUserProvider)?.uid;
  if (uid == null) return const [];
  return ref.watch(planProgressRepositoryProvider).forMember(uid);
});

/// This member's progress on one plan, or null if they haven't started.
final progressForPlanProvider = Provider.family<PlanProgress?, String>((ref, planId) {
  final mine = ref.watch(myProgressProvider).valueOrNull ?? const <PlanProgress>[];
  for (final progress in mine) {
    if (progress.planId == planId) return progress;
  }
  return null;
});

/// Plans this member has started but not finished, newest activity
/// first - the "pick up where you left off" list.
final plansInProgressProvider = Provider<List<({ReadingPlan plan, PlanProgress progress})>>((ref) {
  final plans = ref.watch(publishedReadingPlansProvider).valueOrNull ?? const <ReadingPlan>[];
  final mine = ref.watch(myProgressProvider).valueOrNull ?? const <PlanProgress>[];
  final byId = {for (final plan in plans) plan.id: plan};

  final rows = <({ReadingPlan plan, PlanProgress progress})>[];
  for (final progress in mine) {
    final plan = byId[progress.planId];
    if (plan != null) rows.add((plan: plan, progress: progress));
  }
  rows.sort((a, b) => b.progress.lastReadAt.compareTo(a.progress.lastReadAt));
  return rows;
});

final readingPlanControllerProvider = Provider<ReadingPlanController>((ref) => ReadingPlanController(ref));

class ReadingPlanController {
  final Ref _ref;

  ReadingPlanController(this._ref);

  /// Reads the authoritative record straight from the repository rather
  /// than from [myProgressProvider]'s cache. That cache only refreshes a
  /// frame after a write, so two quick taps would both start from the
  /// same stale value and the first would be silently lost. The
  /// deterministic id exists exactly so this read is a single lookup.
  Future<PlanProgress?> _current(String planId, String uid) =>
      _ref.read(planProgressRepositoryProvider).fetchById(progressId(planId, uid));

  /// Begin a plan, or leave it alone if already started - tapping
  /// "Start" twice must not wipe someone's progress.
  Future<void> start(String planId) async {
    final user = _ref.read(currentUserProvider);
    if (user == null) return;
    if (await _current(planId, user.uid) != null) return;

    final now = DateTime.now();
    await _ref.read(planProgressRepositoryProvider).setProgress(
          PlanProgress(uid: user.uid, planId: planId, startedAt: now, lastReadAt: now),
        );
    _bump();
  }

  /// Check or uncheck a single day. Starts the plan implicitly if the
  /// member checks a day without having pressed Start.
  Future<void> setDayComplete(String planId, int dayNumber, bool complete) async {
    final user = _ref.read(currentUserProvider);
    if (user == null) return;

    final now = DateTime.now();
    final existing = await _current(planId, user.uid);
    final base = existing ?? PlanProgress(uid: user.uid, planId: planId, startedAt: now, lastReadAt: now);

    final days = {...base.completedDays};
    if (complete) {
      days.add(dayNumber);
    } else {
      days.remove(dayNumber);
    }

    await _ref
        .read(planProgressRepositoryProvider)
        .setProgress(base.copyWith(completedDays: days, lastReadAt: now));
    _bump();
  }

  /// Abandon a plan and forget the progress. The member's own data, so
  /// this is theirs to delete.
  Future<void> leave(String planId) async {
    final user = _ref.read(currentUserProvider);
    if (user == null) return;
    await _ref.read(planProgressRepositoryProvider).delete(progressId(planId, user.uid));
    _bump();
  }

  void _bump() => _ref.read(progressRefreshProvider.notifier).state++;
}
