import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/church_settings.dart';
import '../../../core/config/settings_providers.dart';
import '../../../core/widgets/app_shell.dart';
import '../../../core/widgets/async_value_widget.dart';
import '../../../core/widgets/section_container.dart';
import '../../auth/application/auth_providers.dart';

/// Tabs for the staff dashboard. Content tools are open to staff; the
/// three that can reshape the church - members/roles, settings, and the
/// audit trail - are admin-only, matching the route guards.
///
/// Filtered by feature flags for the same reason [primaryNav] is: a
/// church that doesn't run devotionals has no use for the tab, and
/// without this the row would keep growing past what fits on screen.
typedef AdminTab = ({String label, String path, IconData icon, bool adminOnly});

List<AdminTab> adminTabs(FeatureFlags flags) => [
      (label: 'Overview', path: '/admin', icon: Icons.dashboard_outlined, adminOnly: false),
      if (flags.sermons)
        (label: 'Sermons', path: '/admin/sermons', icon: Icons.play_circle_outline, adminOnly: false),
      if (flags.events) (label: 'Events', path: '/admin/events', icon: Icons.event_outlined, adminOnly: false),
      if (flags.groups) (label: 'Groups', path: '/admin/groups', icon: Icons.groups_outlined, adminOnly: false),
      if (flags.volunteering)
        (
          label: 'Volunteering',
          path: '/admin/volunteering',
          icon: Icons.volunteer_activism_outlined,
          adminOnly: false
        ),
      if (flags.devotionals)
        (label: 'Devotionals', path: '/admin/devotionals', icon: Icons.auto_stories_outlined, adminOnly: false),
      if (flags.readingPlans)
        (
          label: 'Reading Plans',
          path: '/admin/reading-plans',
          icon: Icons.menu_book_outlined,
          adminOnly: false
        ),
      if (flags.resources)
        (label: 'Resources', path: '/admin/resources', icon: Icons.folder_outlined, adminOnly: false),
      if (flags.prayerWall)
        (
          label: 'Prayer',
          path: '/admin/prayer',
          icon: Icons.volunteer_activism_outlined,
          adminOnly: false
        ),
      if (flags.roomBooking)
        (label: 'Rooms', path: '/admin/rooms', icon: Icons.meeting_room_outlined, adminOnly: false),
      if (flags.kidsCheckIn)
        (label: 'Kids', path: '/admin/kids', icon: Icons.child_care_outlined, adminOnly: false),
      if (flags.connect) (label: 'Inbox', path: '/admin/connect', icon: Icons.inbox_outlined, adminOnly: false),
      (label: 'Announcements', path: '/admin/announcements', icon: Icons.campaign_outlined, adminOnly: false),
      (label: 'Members', path: '/admin/members', icon: Icons.people_alt_outlined, adminOnly: true),
      (label: 'Settings', path: '/admin/settings', icon: Icons.tune, adminOnly: true),
      (label: 'Audit Log', path: '/admin/audit', icon: Icons.history, adminOnly: true),
    ];

/// The tabs a given user should actually see. The header row and the
/// overview's "Manage" grid both read this, so the two can't drift apart
/// or disagree about which features are switched on.
List<AdminTab> visibleAdminTabs(FeatureFlags flags, {required bool isAdmin}) =>
    adminTabs(flags).where((t) => isAdmin || !t.adminOnly).toList();

/// Deliberately dark, unlike the member portal's brand-colored banner, so
/// staff always know at a glance they're in the management area rather
/// than looking at the public site.
class AdminHeader extends ConsumerWidget {
  final String title;
  final String subtitle;

  const AdminHeader({super.key, required this.title, this.subtitle = ''});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAdmin = ref.watch(isAdminProvider);
    final current = GoRouter.of(context).routerDelegate.currentConfiguration.uri.path;
    final tabs = visibleAdminTabs(ref.watch(featureFlagsProvider), isAdmin: isAdmin);

    return PageBanner(
      color: Colors.black87,
      eyebrow: 'Staff Dashboard',
      title: title,
      subtitle: subtitle,
      below: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final tab in tabs)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: TextButton(
                  onPressed: () => context.go(tab.path),
                  style: TextButton.styleFrom(
                    backgroundColor: current == tab.path
                        ? ref.watch(settingsProvider).colors.accent.withValues(alpha: 0.25)
                        : null,
                    foregroundColor:
                        current == tab.path ? ref.watch(settingsProvider).colors.accent : Colors.white70,
                  ),
                  child: Text(
                    tab.label,
                    style: TextStyle(fontWeight: current == tab.path ? FontWeight.w700 : FontWeight.w500),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Shared chrome for the admin list-and-edit screens: banner, an optional
/// "New" action, and a list that handles its own loading/error/empty
/// states. Without this each CMS screen is a near-identical 120 lines.
class AdminListScaffold<T> extends StatelessWidget {
  final String title;
  final String subtitle;
  final AsyncValue<List<T>> value;
  final String emptyMessage;
  final String? errorContext;
  final Widget Function(T item) itemBuilder;
  final String? newLabel;
  final VoidCallback? onNew;
  final Widget? aboveList;
  final double maxWidth;

  const AdminListScaffold({
    super.key,
    required this.title,
    this.subtitle = '',
    required this.value,
    required this.emptyMessage,
    required this.itemBuilder,
    this.errorContext,
    this.newLabel,
    this.onNew,
    this.aboveList,
    this.maxWidth = 900,
  });

  @override
  Widget build(BuildContext context) {
    return PageBody(
      children: [
        AdminHeader(title: title, subtitle: subtitle),
        SectionContainer(
          maxWidth: maxWidth,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (onNew != null)
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    onPressed: onNew,
                    icon: const Icon(Icons.add),
                    label: Text(newLabel ?? 'New'),
                  ),
                ),
              if (aboveList != null) ...[const SizedBox(height: 16), aboveList!],
              const SizedBox(height: 16),
              AsyncListWidget<T>(
                value: value,
                errorContext: errorContext,
                emptyMessage: emptyMessage,
                data: (items) => Column(children: [for (final item in items) itemBuilder(item)]),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Standard row for an admin list: title, subtitle, edit + delete.
/// Delete always confirms - these are destructive and unlogged otherwise.
class AdminListTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<Widget> actions;
  final VoidCallback? onEdit;
  final Future<void> Function()? onDelete;
  final String deleteLabel;

  const AdminListTile({
    super.key,
    required this.title,
    this.subtitle = '',
    this.actions = const [],
    this.onEdit,
    this.onDelete,
    this.deleteLabel = 'this item',
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: subtitle.isEmpty ? null : Text(subtitle),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ...actions,
            if (onEdit != null)
              IconButton(icon: const Icon(Icons.edit_outlined), tooltip: 'Edit', onPressed: onEdit),
            if (onDelete != null)
              IconButton(
                icon: const Icon(Icons.delete_outline),
                tooltip: 'Delete',
                onPressed: () async {
                  final confirmed = await confirmDelete(context, deleteLabel);
                  if (confirmed) await onDelete!();
                },
              ),
          ],
        ),
      ),
    );
  }
}

Future<bool> confirmDelete(BuildContext context, String label) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Delete?'),
      content: Text('This will permanently delete $label. This cannot be undone.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
  return result ?? false;
}

/// Wraps a dialog form body at a consistent width with scrolling, so a
/// long form doesn't overflow on a short viewport.
class AdminFormDialog extends StatelessWidget {
  final String title;
  final Widget child;
  final VoidCallback onSave;

  const AdminFormDialog({super.key, required this.title, required this.child, required this.onSave});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(child: child),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(onPressed: onSave, child: const Text('Save')),
      ],
    );
  }
}
