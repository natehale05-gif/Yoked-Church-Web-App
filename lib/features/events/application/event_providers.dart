import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/event_repository.dart';
import '../domain/church_event.dart';

final eventRepositoryProvider = Provider<EventRepository>((ref) {
  throw UnimplementedError('eventRepositoryProvider must be overridden in ProviderScope');
});

/// Every event, including past ones - for the staff CMS.
final allEventsProvider = StreamProvider<List<ChurchEvent>>((ref) {
  return ref.watch(eventRepositoryProvider).watchAll();
});

/// What visitors see on the public events page.
final upcomingEventsProvider = Provider<AsyncValue<List<ChurchEvent>>>((ref) {
  return ref.watch(allEventsProvider).whenData((events) => events.where((e) => !e.isPast).toList());
});

final eventByIdProvider = FutureProvider.family<ChurchEvent?, String>((ref, id) {
  return ref.watch(eventRepositoryProvider).fetchById(id);
});
