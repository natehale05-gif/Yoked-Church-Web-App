import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/tenant.dart';
import '../../../core/config/settings_providers.dart';
import '../../../core/widgets/section_container.dart';
import '../../../core/widgets/section_picker.dart';

/// Secondary nav shared by every `/account/*` screen, filtered by the
/// church's feature flags so a disabled feature never shows a tab.
class AccountHeader extends ConsumerWidget {
  final String title;
  final String subtitle;

  const AccountHeader({super.key, required this.title, this.subtitle = ''});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flags = ref.watch(featureFlagsProvider);
    // Stripped of the church prefix: every destination below is a
    // bare path, and the location is now `/c/{church}/...`.
    final current =
        subPathOf(GoRouter.of(context).routerDelegate.currentConfiguration.uri.path);

    // Icons because the phone sheet is a list, and thirteen rows of bare
    // text is a worse thing to scan than thirteen rows with a picture.
    final tabs = <Section>[
      (label: 'Overview', path: '/account', icon: Icons.dashboard_outlined),
      (label: 'Profile', path: '/account/profile', icon: Icons.person_outline),
      if (flags.groups) (label: 'Groups', path: '/account/groups', icon: Icons.groups_outlined),
      if (flags.events)
        (label: 'My Events', path: '/account/events', icon: Icons.event_outlined),
      if (flags.volunteering)
        (
          label: 'Volunteering',
          path: '/account/volunteering',
          icon: Icons.volunteer_activism_outlined
        ),
      if (flags.readingPlans)
        (label: 'Reading', path: '/account/reading', icon: Icons.menu_book_outlined),
      if (flags.sermons) (label: 'My Notes', path: '/account/notes', icon: Icons.edit_note),
      if (flags.prayerWall)
        (label: 'Prayer', path: '/account/prayer', icon: Icons.favorite_outline),
      if (flags.roomBooking)
        (label: 'Bookings', path: '/account/bookings', icon: Icons.meeting_room_outlined),
      if (flags.kidsCheckIn)
        (label: 'Kids', path: '/account/kids', icon: Icons.child_care_outlined),
      (label: 'Directory', path: '/account/directory', icon: Icons.contacts_outlined),
      if (flags.giving) (label: 'Giving', path: '/account/giving', icon: Icons.payments_outlined),
      (
        label: 'Notifications',
        path: '/account/notifications',
        icon: Icons.notifications_outlined
      ),
    ];

    return PageBanner(
      eyebrow: 'My Account',
      title: title,
      subtitle: subtitle,
      // Thirteen sections, four of which fit on a phone. Same control
      // the staff dashboard uses, for the same reason.
      below: SectionPicker(
        sections: tabs,
        current: current,
        selectedColor: ref.watch(settingsProvider).colors.accent,
      ),
    );
  }
}
