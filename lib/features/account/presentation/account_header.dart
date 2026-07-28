import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/settings_providers.dart';
import '../../../core/widgets/section_container.dart';

/// Secondary nav shared by every `/account/*` screen, filtered by the
/// church's feature flags so a disabled feature never shows a tab.
class AccountHeader extends ConsumerWidget {
  final String title;
  final String subtitle;

  const AccountHeader({super.key, required this.title, this.subtitle = ''});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flags = ref.watch(featureFlagsProvider);
    final current = GoRouter.of(context).routerDelegate.currentConfiguration.uri.path;

    final tabs = <({String label, String path})>[
      (label: 'Overview', path: '/account'),
      (label: 'Profile', path: '/account/profile'),
      if (flags.groups) (label: 'Groups', path: '/account/groups'),
      if (flags.events) (label: 'My Events', path: '/account/events'),
      if (flags.volunteering) (label: 'Volunteering', path: '/account/volunteering'),
      if (flags.readingPlans) (label: 'Reading', path: '/account/reading'),
      if (flags.sermons) (label: 'My Notes', path: '/account/notes'),
      if (flags.prayerWall) (label: 'Prayer', path: '/account/prayer'),
      if (flags.roomBooking) (label: 'Bookings', path: '/account/bookings'),
      if (flags.kidsCheckIn) (label: 'Kids', path: '/account/kids'),
      (label: 'Directory', path: '/account/directory'),
      if (flags.giving) (label: 'Giving', path: '/account/giving'),
      (label: 'Notifications', path: '/account/notifications'),
    ];

    return PageBanner(
      eyebrow: 'My Account',
      title: title,
      subtitle: subtitle,
      below: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final tab in tabs)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _Tab(label: tab.label, path: tab.path, selected: current == tab.path),
              ),
          ],
        ),
      ),
    );
  }
}

class _Tab extends ConsumerWidget {
  final String label;
  final String path;
  final bool selected;

  const _Tab({required this.label, required this.path, required this.selected});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return TextButton(
      onPressed: () => context.go(path),
      style: TextButton.styleFrom(
        backgroundColor: selected ? Colors.white.withValues(alpha: 0.16) : null,
        foregroundColor: selected ? Colors.white : Colors.white70,
      ),
      child: Text(label, style: TextStyle(fontWeight: selected ? FontWeight.w700 : FontWeight.w500)),
    );
  }
}
