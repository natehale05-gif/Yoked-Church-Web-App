import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../config/church_config.dart';
import '../models/church_event.dart';

/// Loads events either from bundled sample data (default, no backend
/// required) or from Firestore once [ChurchConfig.useFirebase] is true.
class EventService {
  const EventService();

  Future<List<ChurchEvent>> fetchUpcomingEvents() async {
    if (ChurchConfig.useFirebase) {
      final snapshot = await FirebaseFirestore.instance
          .collection('events')
          .orderBy('start')
          .get();
      return snapshot.docs.map((doc) => ChurchEvent.fromMap(doc.id, doc.data())).toList();
    }

    final raw = await rootBundle.loadString('assets/data/events.json');
    final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
    final events = decoded
        .cast<Map<String, dynamic>>()
        .toList()
        .asMap()
        .entries
        .map((entry) => ChurchEvent.fromMap('local-${entry.key}', entry.value))
        .toList();
    events.sort((a, b) => a.start.compareTo(b.start));
    return events;
  }
}
