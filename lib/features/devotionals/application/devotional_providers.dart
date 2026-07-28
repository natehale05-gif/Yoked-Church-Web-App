import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/devotional_repository.dart';
import '../domain/devotional.dart';

final devotionalRepositoryProvider = Provider<DevotionalRepository>((ref) {
  throw UnimplementedError('devotionalRepositoryProvider must be overridden in ProviderScope');
});

/// Everything, including drafts and future-dated entries - the staff CMS.
final allDevotionalsProvider = StreamProvider<List<Devotional>>((ref) {
  return ref.watch(devotionalRepositoryProvider).watchAll();
});

/// What visitors see. Mirrors [publishedSermonsProvider]: the filter
/// lives here rather than in each screen, so no screen can forget it and
/// leak a draft.
final publishedDevotionalsProvider = Provider<AsyncValue<List<Devotional>>>((ref) {
  final now = DateTime.now();
  return ref.watch(allDevotionalsProvider).whenData(
        (all) => all.where((d) => d.isLiveAt(now)).toList(),
      );
});

/// The most recent live devotional, for the home page card.
final todaysDevotionalProvider = Provider<AsyncValue<Devotional?>>((ref) {
  return ref.watch(publishedDevotionalsProvider).whenData(
        (live) => live.isEmpty ? null : live.first,
      );
});

final devotionalByIdProvider = FutureProvider.family<Devotional?, String>((ref, id) {
  return ref.watch(devotionalRepositoryProvider).fetchById(id);
});

final devotionalSearchQueryProvider = StateProvider<String>((ref) => '');

final filteredDevotionalsProvider = Provider<AsyncValue<List<Devotional>>>((ref) {
  final query = ref.watch(devotionalSearchQueryProvider);
  return ref.watch(publishedDevotionalsProvider).whenData(
        (live) => live.where((d) => d.matches(query)).toList(),
      );
});
