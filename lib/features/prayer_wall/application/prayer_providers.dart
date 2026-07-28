import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_providers.dart';
import '../data/prayer_repository.dart';
import '../domain/prayer_post.dart';

final prayerPostRepositoryProvider = Provider<PrayerPostRepository>((ref) {
  throw UnimplementedError('prayerPostRepositoryProvider must be overridden in ProviderScope');
});

final intercessionRepositoryProvider = Provider<IntercessionRepository>((ref) {
  throw UnimplementedError('intercessionRepositoryProvider must be overridden in ProviderScope');
});

final prayerRefreshProvider = StateProvider<int>((ref) => 0);

/// Everything, for the moderation queue.
final allPrayerPostsProvider = FutureProvider<List<PrayerPost>>((ref) {
  ref.watch(prayerRefreshProvider);
  return ref.watch(prayerPostRepositoryProvider).fetchAll();
});

/// The wall itself. Only approved posts, ever.
final prayerWallProvider = Provider<AsyncValue<List<PrayerPost>>>((ref) {
  return ref.watch(allPrayerPostsProvider).whenData(
        (all) => all.where((p) => p.status == PrayerStatus.approved).toList(),
      );
});

/// A member's own posts, whatever their status, so they can see that
/// something they submitted is still waiting on staff rather than
/// wondering why it vanished.
final myPrayerPostsProvider = Provider<List<PrayerPost>>((ref) {
  final uid = ref.watch(currentUserProvider)?.uid;
  if (uid == null) return const [];
  final all = ref.watch(allPrayerPostsProvider).valueOrNull ?? const <PrayerPost>[];
  return all.where((p) => p.uid == uid && p.status != PrayerStatus.approved).toList();
});

final pendingPrayerCountProvider = Provider<int>((ref) {
  final all = ref.watch(allPrayerPostsProvider).valueOrNull ?? const <PrayerPost>[];
  return all.where((p) => p.status == PrayerStatus.pending).length;
});

/// Prayer counts for every post on the wall, from one batched read
/// rather than a query per post.
final prayerCountsProvider = FutureProvider<Map<String, int>>((ref) async {
  ref.watch(prayerRefreshProvider);
  final posts = ref.watch(prayerWallProvider).valueOrNull ?? const <PrayerPost>[];
  if (posts.isEmpty) return const {};

  final records = await ref.watch(intercessionRepositoryProvider).forPosts(
        posts.map((p) => p.id).toList(),
      );

  final counts = <String, int>{};
  for (final record in records) {
    counts.update(record.postId, (v) => v + 1, ifAbsent: () => 1);
  }
  return {for (final post in posts) post.id: counts[post.id] ?? 0};
});

/// Post ids this member has already prayed for, so the button reads
/// "Praying" rather than inviting a second tap.
final myIntercessionsProvider = FutureProvider<Set<String>>((ref) async {
  ref.watch(prayerRefreshProvider);
  final uid = ref.watch(currentUserProvider)?.uid;
  if (uid == null) return const {};
  final mine = await ref.watch(intercessionRepositoryProvider).forMember(uid);
  return mine.map((i) => i.postId).toSet();
});

final prayerControllerProvider = Provider<PrayerController>((ref) => PrayerController(ref));

class PrayerController {
  final Ref _ref;

  PrayerController(this._ref);

  /// A member's request always starts pending. Staff approval is what
  /// puts it in front of the congregation, and the Firestore rules
  /// enforce that too.
  Future<void> submit({required String body, required bool anonymous}) async {
    final user = _ref.read(currentUserProvider);
    if (user == null || body.trim().isEmpty) return;

    await _ref.read(prayerPostRepositoryProvider).create(PrayerPost(
          uid: user.uid,
          authorName: anonymous ? '' : user.displayName,
          body: body.trim(),
          anonymous: anonymous,
          status: PrayerStatus.pending,
          createdAt: DateTime.now(),
        ));
    _bump();
  }

  Future<void> approve(PrayerPost post) async {
    final staff = _ref.read(currentUserProvider);
    await _ref.read(prayerPostRepositoryProvider).update(
          post.copyWith(status: PrayerStatus.approved, moderatedBy: staff?.displayName ?? 'Staff'),
        );
    _bump();
  }

  Future<void> remove(PrayerPost post) async {
    final staff = _ref.read(currentUserProvider);
    await _ref.read(prayerPostRepositoryProvider).update(
          post.copyWith(status: PrayerStatus.removed, moderatedBy: staff?.displayName ?? 'Staff'),
        );
    _bump();
  }

  Future<void> deleteForever(String postId) async {
    await _ref.read(prayerPostRepositoryProvider).delete(postId);
    _bump();
  }

  /// Toggle "I prayed for this". Idempotent: the deterministic id means
  /// a double tap cannot double-count.
  Future<void> togglePrayed(String postId) async {
    final user = _ref.read(currentUserProvider);
    if (user == null) return;

    final repo = _ref.read(intercessionRepositoryProvider);
    final already = await repo.fetchById(intercessionId(postId, user.uid));

    if (already != null) {
      await repo.unpray(postId: postId, uid: user.uid);
    } else {
      await repo.pray(PrayerIntercession(postId: postId, uid: user.uid, prayedAt: DateTime.now()));
    }
    _bump();
  }

  void _bump() => _ref.read(prayerRefreshProvider.notifier).state++;
}
