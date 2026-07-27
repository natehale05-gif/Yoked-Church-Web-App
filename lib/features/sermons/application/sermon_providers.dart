import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/sermon_repository.dart';
import '../domain/sermon.dart';
import '../domain/sermon_series.dart';

final sermonRepositoryProvider = Provider<SermonRepository>((ref) {
  throw UnimplementedError('sermonRepositoryProvider must be overridden in ProviderScope');
});

final sermonSeriesRepositoryProvider = Provider<SermonSeriesRepository>((ref) {
  throw UnimplementedError('sermonSeriesRepositoryProvider must be overridden in ProviderScope');
});

/// Everything, including unpublished drafts - for the staff CMS.
final allSermonsProvider = StreamProvider<List<Sermon>>((ref) {
  return ref.watch(sermonRepositoryProvider).watchAll();
});

/// What visitors see. Drafts and pending YouTube auto-imports stay hidden
/// until a staff member publishes them.
final publishedSermonsProvider = Provider<AsyncValue<List<Sermon>>>((ref) {
  return ref.watch(allSermonsProvider).whenData((sermons) => sermons.where((s) => s.published).toList());
});

final sermonSeriesProvider = StreamProvider<List<SermonSeries>>((ref) {
  return ref.watch(sermonSeriesRepositoryProvider).watchAll();
});

final sermonByIdProvider = FutureProvider.family<Sermon?, String>((ref, id) {
  return ref.watch(sermonRepositoryProvider).fetchById(id);
});

/// Free-text search box contents on the sermons page.
final sermonSearchQueryProvider = StateProvider<String>((ref) => '');

/// Selected series filter, or null for "all series".
final sermonSeriesFilterProvider = StateProvider<String?>((ref) => null);

/// Published sermons narrowed by the active search text and series filter.
final filteredSermonsProvider = Provider<AsyncValue<List<Sermon>>>((ref) {
  final query = ref.watch(sermonSearchQueryProvider);
  final seriesId = ref.watch(sermonSeriesFilterProvider);

  return ref.watch(publishedSermonsProvider).whenData((sermons) {
    return sermons.where((sermon) {
      final seriesOk = seriesId == null || sermon.seriesId == seriesId;
      return seriesOk && sermon.matches(query);
    }).toList();
  });
});
