import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/event_rsvp.dart';

class RsvpService {
  CollectionReference<Map<String, dynamic>> get _rsvps => FirebaseFirestore.instance.collection('eventRsvps');

  Future<List<EventRsvp>> fetchMyRsvps(String uid) async {
    final snapshot = await _rsvps.where('uid', isEqualTo: uid).get();
    return snapshot.docs.map((doc) => EventRsvp.fromMap(doc.id, doc.data())).toList();
  }

  Future<void> rsvp({required String eventId, required String uid}) {
    final rsvp = EventRsvp(id: '', eventId: eventId, uid: uid, respondedAt: DateTime.now());
    return _rsvps.doc('${eventId}_$uid').set(rsvp.toMap());
  }

  Future<void> cancelRsvp({required String eventId, required String uid}) {
    return _rsvps.doc('${eventId}_$uid').delete();
  }
}
