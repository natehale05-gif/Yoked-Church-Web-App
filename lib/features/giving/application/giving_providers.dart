import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_providers.dart';
import '../data/giving_repository.dart';
import '../domain/giving_record.dart';

final givingRepositoryProvider = Provider<GivingRepository>((ref) {
  throw UnimplementedError('givingRepositoryProvider must be overridden in ProviderScope');
});

final myGivingProvider = FutureProvider<List<GivingRecord>>((ref) async {
  final uid = ref.watch(currentUserProvider)?.uid;
  if (uid == null) return const [];
  return ref.watch(givingRepositoryProvider).forMember(uid);
});

final myGivingByYearProvider = Provider<AsyncValue<List<GivingSummary>>>((ref) {
  return ref.watch(myGivingProvider).whenData(GivingSummary.byYear);
});

final allGivingProvider = StreamProvider<List<GivingRecord>>((ref) {
  return ref.watch(givingRepositoryProvider).watchAll();
});
