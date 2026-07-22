import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/app_notification.dart';

/// In-app notification inbox. Only ever written by staff-initiated
/// actions (see `firestore.rules` - `allow create: if isStaff();`) -
/// members can read/mark-read/delete their own but never create one.
class NotificationService {
  CollectionReference<Map<String, dynamic>> get _notifications =>
      FirebaseFirestore.instance.collection('notifications');

  Future<void> create({required String uid, required String title, required String message, String linkPath = ''}) {
    final notification = AppNotification(
      id: '',
      uid: uid,
      title: title,
      message: message,
      linkPath: linkPath,
      createdAt: DateTime.now(),
    );
    return _notifications.add(notification.toMap());
  }

  Future<List<AppNotification>> fetchMyNotifications(String uid) async {
    final snapshot = await _notifications.where('uid', isEqualTo: uid).orderBy('createdAt', descending: true).get();
    return snapshot.docs.map((doc) => AppNotification.fromMap(doc.id, doc.data())).toList();
  }

  Stream<int> watchUnreadCount(String uid) {
    return _notifications
        .where('uid', isEqualTo: uid)
        .where('read', isEqualTo: false)
        .snapshots()
        .map((snap) => snap.docs.length);
  }

  Future<void> markRead(String id) {
    return _notifications.doc(id).update({'read': true});
  }
}
