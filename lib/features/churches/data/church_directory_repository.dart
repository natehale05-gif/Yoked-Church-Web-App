import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../domain/church_summary.dart';

/// The list of churches a member can choose between.
///
/// The one repository in the app that is *not* scoped to a church, for
/// the obvious reason: it is what you use before you have one.
abstract interface class ChurchDirectoryRepository {
  Future<List<ChurchSummary>> fetchAll();
  Future<ChurchSummary?> fetchById(String id);
}

/// Reads the bundled `assets/data/churches.json`.
///
/// Three churches with genuinely different names, colours and copy, so
/// the zero-backend build demonstrates the actual point of the picker -
/// choose a different church and the whole app re-themes - rather than
/// listing three names that all lead to the same site.
class LocalChurchDirectoryRepository implements ChurchDirectoryRepository {
  static List<Map<String, dynamic>>? _cache;

  static Future<List<Map<String, dynamic>>> load() async {
    if (_cache != null) return _cache!;
    try {
      final raw = await rootBundle.loadString('assets/data/churches.json');
      _cache = (jsonDecode(raw) as List<dynamic>)
          .whereType<Map<String, dynamic>>()
          .toList();
    } catch (_) {
      // A missing or malformed asset must not leave a member unable to
      // reach any church at all.
      _cache = const [];
    }
    return _cache!;
  }

  @override
  Future<List<ChurchSummary>> fetchAll() async {
    final raw = await load();
    return [
      for (final map in raw) ChurchSummary.fromMap(map['id'] as String? ?? '', map),
    ];
  }

  @override
  Future<ChurchSummary?> fetchById(String id) async {
    final all = await fetchAll();
    for (final church in all) {
      if (church.id == id) return church;
    }
    return null;
  }
}

class FirestoreChurchDirectoryRepository implements ChurchDirectoryRepository {
  CollectionReference<Map<String, dynamic>> get _churches =>
      FirebaseFirestore.instance.collection('churches');

  @override
  Future<List<ChurchSummary>> fetchAll() async {
    // Ordered by name because the picker is a list a person scans for
    // their own church, not a ranking.
    final snapshot = await _churches.orderBy('churchName').get();
    return snapshot.docs.map((doc) => ChurchSummary.fromMap(doc.id, doc.data())).toList();
  }

  @override
  Future<ChurchSummary?> fetchById(String id) async {
    final doc = await _churches.doc(id).get();
    final data = doc.data();
    return data == null ? null : ChurchSummary.fromMap(doc.id, data);
  }
}
