import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/live_status.dart';

/// Read-only from the app's point of view.
///
/// Nothing in the client may write this: whether a church is live is a
/// fact about YouTube, established server-side by a scheduled job holding
/// an API key. A staff member with a browser console must not be able to
/// announce a service that is not happening.
abstract interface class LiveRepository {
  Stream<LiveStatus> watch();
}

class FirestoreLiveRepository implements LiveRepository {
  FirestoreLiveRepository(this.churchId);

  final String churchId;

  DocumentReference<Map<String, dynamic>> get _doc =>
      FirebaseFirestore.instance.doc('churches/$churchId/live/current');

  @override
  Stream<LiveStatus> watch() => _doc.snapshots().map((snapshot) {
        final data = snapshot.data();
        // No document means the poller has never run for this church,
        // which is the same thing to a visitor as not being live.
        return data == null ? const LiveStatus() : LiveStatus.fromMap(data);
      });
}

/// Nobody is live in a demo.
///
/// Deliberately not seeded from an asset: a bundled "live now" would put a
/// permanent red banner on the sample site, which is exactly the lie this
/// feature exists to stop telling. The banner is proved by tests and by
/// writing the document by hand.
class LocalLiveRepository implements LiveRepository {
  @override
  Stream<LiveStatus> watch() => Stream.value(const LiveStatus());
}
