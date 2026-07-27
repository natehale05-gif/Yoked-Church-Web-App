import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/config/settings_providers.dart';
import '../../../core/widgets/app_shell.dart';
import '../../../core/widgets/async_value_widget.dart';
import '../../../core/widgets/section_container.dart';
import '../../notifications/application/notification_providers.dart';
import '../../notifications/domain/app_notification.dart';
import 'account_header.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PageBody(
      children: [
        const AccountHeader(title: 'Notifications', subtitle: 'Updates from the church.'),
        SectionContainer(
          maxWidth: 720,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => context.go('/account/profile'),
                  icon: const Icon(Icons.tune, size: 16),
                  label: const Text('Preferences'),
                ),
              ),
              const SizedBox(height: 8),
              AsyncListWidget<AppNotification>(
                value: ref.watch(myNotificationsProvider),
                errorContext: 'your notifications',
                emptyMessage: "You're all caught up.",
                data: (notifications) => Column(
                  children: [for (final n in notifications) _NotificationTile(notification: n)],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _NotificationTile extends ConsumerWidget {
  final AppNotification notification;

  const _NotificationTile({required this.notification});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brand = ref.watch(settingsProvider).colors;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          width: 10,
          height: 10,
          margin: const EdgeInsets.only(top: 6),
          decoration: BoxDecoration(
            color: notification.read ? Colors.transparent : brand.accent,
            shape: BoxShape.circle,
          ),
        ),
        title: Text(
          notification.title,
          style: TextStyle(fontWeight: notification.read ? FontWeight.w500 : FontWeight.w700),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(notification.message),
            const SizedBox(height: 4),
            Text(
              DateFormat.yMMMd().add_jm().format(notification.createdAt),
              style: const TextStyle(fontSize: 11, color: Colors.black45),
            ),
          ],
        ),
        onTap: () async {
          if (!notification.read) {
            await ref.read(notificationSenderProvider).markRead(notification.id);
          }
          if (context.mounted && notification.linkPath.isNotEmpty) {
            context.go(notification.linkPath);
          }
        },
      ),
    );
  }
}
