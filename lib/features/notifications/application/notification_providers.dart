import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_providers.dart';
import '../data/notification_repository.dart';
import '../domain/app_notification.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  throw UnimplementedError('notificationRepositoryProvider must be overridden in ProviderScope');
});

final myNotificationsProvider = StreamProvider<List<AppNotification>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value(const []);

  return ref.watch(notificationRepositoryProvider).watchForMember(user.uid).map(
        // Honour the member's per-category mute settings client-side; the
        // notification is still stored, just not surfaced.
        (all) => all.where((n) => user.notificationPreferences.allows(n.category)).toList(),
      );
});

final unreadNotificationCountProvider = Provider<int>((ref) {
  return ref.watch(myNotificationsProvider).valueOrNull?.where((n) => !n.read).length ?? 0;
});

final notificationSenderProvider = Provider<NotificationSender>((ref) => NotificationSender(ref));

/// Creating notifications is a staff-side action (enforced by Firestore
/// rules), so this is used by admin flows - assigning a volunteer,
/// approving a signup, sending an announcement.
class NotificationSender {
  final Ref _ref;

  NotificationSender(this._ref);

  Future<void> send({
    required String uid,
    required String title,
    required String message,
    String linkPath = '',
    String category = 'announcements',
  }) {
    return _ref.read(notificationRepositoryProvider).create(
          AppNotification(
            uid: uid,
            title: title,
            message: message,
            linkPath: linkPath,
            category: category,
            createdAt: DateTime.now(),
          ),
        );
  }

  Future<void> sendToMany({
    required Iterable<String> uids,
    required String title,
    required String message,
    String linkPath = '',
    String category = 'announcements',
  }) async {
    for (final uid in uids) {
      await send(uid: uid, title: title, message: message, linkPath: linkPath, category: category);
    }
  }

  Future<void> markRead(String id) => _ref.read(notificationRepositoryProvider).markRead(id);
}
