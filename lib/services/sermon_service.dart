import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../config/church_config.dart';
import '../models/sermon.dart';

/// Loads sermons either from bundled sample data (default, no backend
/// required) or from Firestore once a customer wires up their own
/// Firebase project and flips [ChurchConfig.useFirebase] to true.
class SermonService {
  const SermonService();

  Future<List<Sermon>> fetchSermons() async {
    if (ChurchConfig.useFirebase) {
      final snapshot = await FirebaseFirestore.instance
          .collection('sermons')
          .orderBy('date', descending: true)
          .get();
      return snapshot.docs.map((doc) => Sermon.fromMap(doc.id, doc.data())).toList();
    }

    final raw = await rootBundle.loadString('assets/data/sermons.json');
    final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
    final sermons = decoded
        .cast<Map<String, dynamic>>()
        .toList()
        .asMap()
        .entries
        .map((entry) => Sermon.fromMap('local-${entry.key}', entry.value))
        .toList();
    sermons.sort((a, b) => b.date.compareTo(a.date));
    return sermons;
  }
}
