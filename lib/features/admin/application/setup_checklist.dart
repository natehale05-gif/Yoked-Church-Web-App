import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/church_settings.dart';
import '../../../core/config/settings_providers.dart';
import '../../auth/application/auth_providers.dart';
import '../../events/application/event_providers.dart';
import '../../sermons/application/sermon_providers.dart';

/// One thing a church still has to do before its site is worth showing
/// anyone.
class SetupStep {
  final String title;

  /// Why it matters, in terms of what a visitor sees - not "required
  /// field". Nobody fills in a form because it is incomplete.
  final String why;

  /// Where to go and do it.
  final String path;

  final bool done;

  const SetupStep({
    required this.title,
    required this.why,
    required this.path,
    required this.done,
  });
}

/// What a new church still has to do, worked out from what is actually
/// there.
///
/// Derived rather than stored, deliberately. A stored checklist is a
/// second copy of the truth that drifts: delete your last sermon and a
/// stored list still says you have one. This cannot be wrong, because it
/// is only ever a question asked of the real data.
///
/// Filtered by the church's feature flags for the same reason
/// [visibleAdminTabs] is: a church that has switched giving off should
/// not be nagged to add a giving link.
final setupChecklistProvider = Provider<List<SetupStep>>((ref) {
  final settings = ref.watch(settingsProvider);
  final flags = settings.features;

  // Counts, not contents - and `valueOrNull` because a checklist that
  // waits for every collection to load would flash empty on arrival and
  // tell a new church it had done nothing.
  final sermons = ref.watch(allSermonsProvider).valueOrNull?.length ?? 0;
  final events = ref.watch(allEventsProvider).valueOrNull?.length ?? 0;
  final leaders = (ref.watch(allMembersProvider).valueOrNull ?? const [])
      .where((m) => m.isStaff)
      .length;

  return [
    SetupStep(
      title: 'Add your service times',
      why: 'The first thing a visitor looks for, and the first thing on your home page.',
      path: '/admin/settings',
      done: settings.serviceTimes.isNotEmpty,
    ),
    SetupStep(
      title: 'Say where you meet',
      why: 'Your address puts you on the map and in search results.',
      path: '/admin/settings',
      done: settings.contact.address.trim().isNotEmpty,
    ),
    SetupStep(
      title: 'Write a welcome',
      why: 'Two or three sentences about who you are, for the About page.',
      path: '/admin/settings',
      done: settings.aboutBody.trim().length > 40,
    ),
    SetupStep(
      title: 'Choose your colours',
      why: 'Pick a look so the site is yours rather than the default.',
      path: '/admin/settings',
      done: !_isDefaultPalette(settings.colors),
    ),
    if (flags.sermons)
      SetupStep(
        title: 'Publish a sermon',
        why: 'Gives people a reason to come back between Sundays.',
        path: '/admin/sermons',
        done: sermons > 0,
      ),
    if (flags.events)
      SetupStep(
        title: 'Put something in the diary',
        why: "An empty events page reads as a church that isn't doing anything.",
        path: '/admin/events',
        done: events > 0,
      ),
    if (flags.giving)
      SetupStep(
        title: 'Add your giving link',
        why: 'The Give page has nowhere to send anyone until you do.',
        path: '/admin/settings',
        done: settings.social.givingUrl.trim().isNotEmpty,
      ),
    SetupStep(
      title: 'Invite your team',
      why: 'Staff can manage content; only admins can change settings.',
      path: '/admin/members',
      // More than one person who can run it. A church whose site only
      // one person can touch is one holiday from being stuck.
      done: leaders > 1,
    ),
  ];
});

/// Whether a church is still wearing the colours it was created with.
///
/// Only the primary and the background: an accent left at the default
/// while the other two have been chosen is a decision, not an omission.
bool _isDefaultPalette(BrandColors colors) {
  const fallback = BrandColors.fallback;
  return colors.primary.toARGB32() == fallback.primary.toARGB32() &&
      colors.background.toARGB32() == fallback.background.toARGB32();
}

/// How far along a church is, for the progress line.
final setupProgressProvider = Provider<({int done, int total})>((ref) {
  final steps = ref.watch(setupChecklistProvider);
  return (done: steps.where((s) => s.done).length, total: steps.length);
});
