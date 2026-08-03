import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/church_info_repository.dart';
import '../domain/church_info.dart';

final staffRepositoryProvider = Provider<StaffRepository>((ref) {
  throw UnimplementedError('staffRepositoryProvider must be overridden in ProviderScope');
});

final locationRepositoryProvider = Provider<LocationRepository>((ref) {
  throw UnimplementedError('locationRepositoryProvider must be overridden in ProviderScope');
});

final faqRepositoryProvider = Provider<FaqRepository>((ref) {
  throw UnimplementedError('faqRepositoryProvider must be overridden in ProviderScope');
});

final staffProvider = StreamProvider<List<StaffMember>>((ref) {
  return ref.watch(staffRepositoryProvider).watchAll();
});

final locationsProvider = StreamProvider<List<ChurchLocation>>((ref) {
  return ref.watch(locationRepositoryProvider).watchAll();
});

final faqsProvider = StreamProvider<List<Faq>>((ref) {
  return ref.watch(faqRepositoryProvider).watchAll();
});
