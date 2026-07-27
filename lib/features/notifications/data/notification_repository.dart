import '../../../core/firestore/crud_repository.dart';
import '../domain/app_notification.dart';

abstract interface class NotificationRepository implements CrudRepository<AppNotification> {
  Stream<List<AppNotification>> watchForMember(String uid);
  Future<void> markRead(String id);
}

mixin _NotificationCodec implements EntityCodec<AppNotification> {
  @override
  AppNotification fromMap(String id, Map<String, dynamic> map) => AppNotification.fromMap(id, map);
  @override
  Map<String, dynamic> toMap(AppNotification entity) => entity.toMap();
  @override
  String idOf(AppNotification entity) => entity.id;
}

class FirestoreNotificationRepository extends FirestoreCrudRepository<AppNotification>
    with _NotificationCodec
    implements NotificationRepository {
  @override
  String get collectionPath => 'notifications';
  @override
  String? get orderByField => 'createdAt';
  @override
  bool get descending => true;

  @override
  Stream<List<AppNotification>> watchForMember(String uid) {
    return collection
        .where('uid', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => fromMap(d.id, d.data())).toList());
  }

  @override
  Future<void> markRead(String id) => collection.doc(id).update({'read': true});
}

class LocalNotificationRepository extends LocalCrudRepository<AppNotification>
    with _NotificationCodec
    implements NotificationRepository {
  @override
  int Function(AppNotification, AppNotification)? get sorter => (a, b) => b.createdAt.compareTo(a.createdAt);

  @override
  Stream<List<AppNotification>> watchForMember(String uid) async* {
    yield await fetchWhere((n) => n.uid == uid);
  }

  @override
  Future<void> markRead(String id) async {
    final existing = await fetchById(id);
    if (existing != null) await update(existing.copyWith(read: true));
  }
}
