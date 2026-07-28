import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'church_settings.dart';

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
  final StreamController<ChurchSettings> _changes = StreamController<ChurchSettings>.broadcast();

  ChurchSettings? _cached;

  @override
  Future<ChurchSettings> fetch() async {
    if (_cached != null) return _cached!;
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
  static const _docPath = 'churchSettings/main';

  DocumentReference<Map<String, dynamic>> get _doc => FirebaseFirestore.instance.doc(_docPath);

  /// Falls back to the bundled asset when the settings doc has not been
  /// created yet, so a freshly-configured Firebase project still renders
  /// a complete site instead of an empty one.
  final LocalSettingsRepository _fallback = LocalSettingsRepository();

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
