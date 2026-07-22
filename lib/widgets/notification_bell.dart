import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../config/church_config.dart';
import '../models/app_notification.dart';
import '../services/notification_service.dart';

/// Bell icon + unread-count badge shown next to the account avatar for
/// signed-in members. Tapping opens a menu of recent notifications;
/// tapping one marks it read and navigates to its `linkPath`.
class NotificationBell extends StatefulWidget {
  final String uid;

  const NotificationBell({super.key, required this.uid});

  @override
  State<NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends State<NotificationBell> {
  final NotificationService _service = NotificationService();
  final GlobalKey _anchorKey = GlobalKey();

  Future<void> _open(BuildContext context) async {
    final notifications = await _service.fetchMyNotifications(widget.uid);
    if (!context.mounted) return;

    final box = _anchorKey.currentContext?.findRenderObject() as RenderBox?;
    final position = box != null
        ? RelativeRect.fromLTRB(
            box.localToGlobal(Offset.zero).dx,
            box.localToGlobal(Offset(0, box.size.height)).dy,
            0,
            0,
          )
        : const RelativeRect.fromLTRB(100, 80, 0, 0);

    final selected = await showMenu<AppNotification>(
      context: context,
      position: position,
      constraints: const BoxConstraints(minWidth: 320, maxWidth: 360),
      items: notifications.isEmpty
          ? [const PopupMenuItem<AppNotification>(enabled: false, child: Text('No notifications yet.'))]
          : notifications
              .map(
                (n) => PopupMenuItem<AppNotification>(
                  value: n,
                  child: _NotificationRow(notification: n),
                ),
              )
              .toList(),
    );

    if (selected != null) {
      if (!selected.read) await _service.markRead(selected.id);
      if (context.mounted && selected.linkPath.isNotEmpty) context.go(selected.linkPath);
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: _service.watchUnreadCount(widget.uid),
      builder: (context, snapshot) {
        final unread = snapshot.data ?? 0;
        return IconButton(
          key: _anchorKey,
          tooltip: 'Notifications',
          onPressed: () => _open(context),
          icon: Badge(
            isLabelVisible: unread > 0,
            label: Text('$unread'),
            child: const Icon(Icons.notifications_outlined),
          ),
        );
      },
    );
  }
}

class _NotificationRow extends StatelessWidget {
  final AppNotification notification;

  const _NotificationRow({required this.notification});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            if (!notification.read)
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(color: ChurchConfig.accentColor, shape: BoxShape.circle),
              ),
            Expanded(
              child: Text(
                notification.title,
                style: TextStyle(fontWeight: notification.read ? FontWeight.w500 : FontWeight.w700),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(notification.message, style: const TextStyle(fontSize: 12, color: Colors.black54)),
        Text(DateFormat.yMMMd().add_jm().format(notification.createdAt),
            style: const TextStyle(fontSize: 11, color: Colors.black38)),
      ],
    );
  }
}
