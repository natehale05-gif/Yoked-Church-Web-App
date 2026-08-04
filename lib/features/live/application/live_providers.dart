import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/live_repository.dart';
import '../domain/live_status.dart';

final liveRepositoryProvider = Provider<LiveRepository>((ref) {
  throw UnimplementedError('liveRepositoryProvider must be overridden in ProviderScope');
});

/// Whether this church is streaming right now. Watched rather than
/// fetched, so a service starting mid-visit raises the banner without a
/// reload - which is the only way a home page is any use on a Sunday.
final liveStatusProvider = StreamProvider<LiveStatus>((ref) {
  return ref.watch(liveRepositoryProvider).watch();
});
