import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../../features/churches/data/church_directory_repository.dart';
import 'church_settings.dart';
import 'tenant.dart';

/// Reads/writes the church's branding + configuration.
///
/// This is the reference shape every repository in the app follows: one
/// abstract interface, a Firestore implementation for real deployments,
/// and a local implementation that serves bundled sample content and
/// keeps writes in memory so the whole app (including admin screens) is
/// fully usable and testable with no backend at all.
abstract interface class SettingsRepository {
  Future<ChurchSettings> fetch();
  Stream<ChurchSettings> watch();
  Future<void> save(ChurchSettings settings);
}

/// Loads the bundled `assets/data/church_settings.json`. Used for the
/// zero-backend demo/preview mode and in tests.
class LocalSettingsRepository implements SettingsRepository {
  LocalSettingsRepository([this.churchId = demoChurchId]);

  /// Which bundled church to serve.
  ///
  /// The demo has three, so that choosing a different one in the picker
  /// visibly re-themes the app rather than showing the same site under a
  /// different name. That is the whole feature, demonstrated with no
  /// backend at all.
  final String churchId;

  final StreamController<ChurchSettings> _changes = StreamController<ChurchSettings>.broadcast();

  ChurchSettings? _cached;

  @override
  Future<ChurchSettings> fetch() async {
    if (_cached != null) return _cached!;

    for (final map in await LocalChurchDirectoryRepository.load()) {
      if (map['id'] == churchId) {
        _cached = ChurchSettings.fromMap(map);
        return _cached!;
      }
    }

    // Not one of the bundled churches - fall back to the single-church
    // sample, which is also what a fork editing one file gets.
    try {
      final raw = await rootBundle.loadString('assets/data/church_settings.json');
      _cached = ChurchSettings.fromMap(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      // A missing or malformed asset must not take the whole site down.
      _cached = ChurchSettings.fallback;
    }
    return _cached!;
  }

  /// Mirrors Firestore's live document stream, so an admin's edit
  /// re-themes every open screen in preview mode too.
  @override
  Stream<ChurchSettings> watch() async* {
    yield await fetch();
    yield* _changes.stream;
  }

  @override
  Future<void> save(ChurchSettings settings) async {
    _cached = settings;
    if (!_changes.isClosed) _changes.add(settings);
  }
}

class FirestoreSettingsRepository implements SettingsRepository {
  FirestoreSettingsRepository(this.churchId);

  /// Which church's settings these are.
  final String churchId;

  /// The church document does double duty: it is both this church's
  /// settings and its entry in the public directory the picker lists.
  /// One document, one read - a member choosing a church has already
  /// fetched everything needed to theme the app as that church.
  ///
  /// This replaced a hardcoded `churchSettings/main`, which was the
  /// clearest statement that the old app could only ever serve one
  /// church.
  DocumentReference<Map<String, dynamic>> get _doc =>
      FirebaseFirestore.instance.doc('churches/$churchId');

  /// Falls back to the bundled asset when the settings doc has not been
  /// created yet, so a freshly-configured Firebase project still renders
  /// a complete site instead of an empty one.
  late final LocalSettingsRepository _fallback = LocalSettingsRepository(churchId);

  @override
  Future<ChurchSettings> fetch() async {
    final snapshot = await _doc.get();
    final data = snapshot.data();
    if (!snapshot.exists || data == null) return _fallback.fetch();
    return ChurchSettings.fromMap(data);
  }

  @override
  Stream<ChurchSettings> watch() async* {
    yield await fetch();
    yield* _doc.snapshots().asyncMap((snapshot) async {
      final data = snapshot.data();
      if (!snapshot.exists || data == null) return _fallback.fetch();
      return ChurchSettings.fromMap(data);
    });
  }

  @override
  Future<void> save(ChurchSettings settings) {
    return _doc.set(settings.toMap());
  }
}
