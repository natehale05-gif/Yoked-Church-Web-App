import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/config/settings_providers.dart';
import '../core/config/settings_repository.dart';
import '../features/church_info/application/church_info_providers.dart';
import '../features/church_info/data/church_info_repository.dart';
import '../features/connect/application/connect_providers.dart';
import '../features/connect/data/connect_repository.dart';
import '../features/events/application/event_providers.dart';
import '../features/events/data/event_repository.dart';
import '../features/sermons/application/sermon_providers.dart';
import '../features/sermons/data/sermon_repository.dart';

/// Which data source the app is running against.
///
/// This is the *only* place that decision is made. Everything downstream
/// depends on repository interfaces and is oblivious to the backend -
/// which is what makes the whole app testable and lets a single build
/// serve both a live church and a zero-backend preview.
enum Backend { local, firestore }

/// Bundled-content mode: reads come from `assets/data/*.json`, writes are
/// held in memory for the session. The entire app - including staff and
/// admin screens - is fully usable in this mode, which is what makes the
/// template demo-able before a customer sets up Firebase.
List<Override> localOverrides() => [
      settingsRepositoryProvider.overrideWithValue(LocalSettingsRepository()),
      sermonRepositoryProvider.overrideWithValue(LocalSermonRepository()),
      sermonSeriesRepositoryProvider.overrideWithValue(LocalSermonSeriesRepository()),
      eventRepositoryProvider.overrideWithValue(LocalEventRepository()),
      connectRepositoryProvider.overrideWithValue(LocalConnectRepository()),
      staffRepositoryProvider.overrideWithValue(LocalStaffRepository()),
      locationRepositoryProvider.overrideWithValue(LocalLocationRepository()),
      faqRepositoryProvider.overrideWithValue(LocalFaqRepository()),
    ];

/// Live mode against a configured Firebase project.
List<Override> firestoreOverrides() => [
      settingsRepositoryProvider.overrideWithValue(FirestoreSettingsRepository()),
      sermonRepositoryProvider.overrideWithValue(FirestoreSermonRepository()),
      sermonSeriesRepositoryProvider.overrideWithValue(FirestoreSermonSeriesRepository()),
      eventRepositoryProvider.overrideWithValue(FirestoreEventRepository()),
      connectRepositoryProvider.overrideWithValue(FirestoreConnectRepository()),
      staffRepositoryProvider.overrideWithValue(FirestoreStaffRepository()),
      locationRepositoryProvider.overrideWithValue(FirestoreLocationRepository()),
      faqRepositoryProvider.overrideWithValue(FirestoreFaqRepository()),
    ];

List<Override> overridesFor(Backend backend) =>
    backend == Backend.firestore ? firestoreOverrides() : localOverrides();
