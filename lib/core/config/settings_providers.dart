import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'church_settings.dart';
import 'settings_repository.dart';

/// Overridden once at startup in `main.dart` (and in tests) with either
/// the Firestore or the local implementation. Nothing downstream ever
/// asks "is Firebase configured?" - that decision is made exactly once.
final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  throw UnimplementedError('settingsRepositoryProvider must be overridden in ProviderScope');
});

/// Live church branding/config. Streams so an admin's edit re-themes
/// every open session without a reload.
final churchSettingsProvider = StreamProvider<ChurchSettings>((ref) {
  return ref.watch(settingsRepositoryProvider).watch();
});

/// Synchronous accessor for the many widgets that just need the current
/// values and shouldn't each handle a loading state. Falls back to the
/// bundled defaults until the first emission arrives.
final settingsProvider = Provider<ChurchSettings>((ref) {
  return ref.watch(churchSettingsProvider).valueOrNull ?? ChurchSettings.fallback;
});

/// Convenience for the very common `settings.features.x` read.
final featureFlagsProvider = Provider<FeatureFlags>((ref) => ref.watch(settingsProvider).features);
