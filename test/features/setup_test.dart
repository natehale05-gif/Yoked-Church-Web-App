import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yoked_church_app/app/app.dart';
import 'package:yoked_church_app/app/router.dart';
import 'package:yoked_church_app/core/config/church_settings.dart';
import 'package:yoked_church_app/core/config/settings_providers.dart';
import 'package:yoked_church_app/core/config/tenant.dart';
import 'package:yoked_church_app/core/config/themes.dart';
import 'package:yoked_church_app/features/admin/application/setup_checklist.dart';
import 'package:yoked_church_app/features/auth/application/auth_providers.dart';
import 'package:yoked_church_app/features/auth/domain/app_user.dart';
import 'package:yoked_church_app/features/events/application/event_providers.dart';
import 'package:yoked_church_app/features/sermons/application/sermon_providers.dart';
import 'package:yoked_church_app/features/events/domain/church_event.dart';
import 'package:yoked_church_app/features/sermons/domain/sermon.dart';

import '../fakes/fake_repositories.dart';

/// The two things that turn an empty dashboard into somewhere to start:
/// a look you can pick rather than compute, and a list of what is still
/// missing.
void main() {
  ProviderContainer containerWith({
    ChurchSettings? settings,
    List<Sermon> sermons = const [],
    List<ChurchEvent> events = const [],
    List<AppUser> members = const [],
  }) {
    final container = ProviderContainer(
      overrides: fakeOverrides(
        settings: settings,
        sermons: sermons,
        events: events,
        members: members,
        signedInAs: testMember(role: UserRole.admin),
      ),
    );
    addTearDown(container.dispose);
    return container;
  }

  /// A church exactly as `createChurch` leaves it.
  ChurchSettings brandNew() => testSettings(
        churchName: 'Grace Chapel',
        aboutBody: '',
        colors: BrandColors.fallback,
        serviceTimes: const [],
        contact: const ContactInfo(address: '', phone: '', email: '', mapUrl: ''),
        social: const SocialLinks(
          facebook: '',
          instagram: '',
          youtube: '',
          givingUrl: '',
          liveStreamUrl: '',
        ),
      );

  /// The checklist counts sermons, events and leaders, which arrive on
  /// streams. Read without waiting, they are all still loading and every
  /// step reports undone - which would make these tests agree with a
  /// checklist that had stopped working.
  Future<List<SetupStep>> checklistOf(ProviderContainer c) async {
    // Settings included: `settingsProvider` falls back to the bundled
    // defaults until its stream emits, so a checklist read too early is
    // answering questions about a church that is not the one under test.
    await c.read(churchSettingsProvider.future);
    await c.read(allSermonsProvider.future);
    await c.read(allEventsProvider.future);
    await c.read(allMembersProvider.future);
    return c.read(setupChecklistProvider);
  }

  group('the checklist', () {
    test('a church created a minute ago has everything still to do', () async {
      final c = containerWith(settings: brandNew());
      final steps = await checklistOf(c);

      expect(steps, isNotEmpty);
      expect(steps.every((s) => !s.done), isTrue, reason: 'nothing has been filled in yet');
      expect(c.read(setupProgressProvider).done, 0);
    });

    test('each step says why it matters, and where to go', () async {
      final steps = await checklistOf(containerWith(settings: brandNew()));

      for (final step in steps) {
        expect(step.title, isNotEmpty);
        expect(step.why, isNotEmpty, reason: 'nobody fills in a form because it is incomplete');
        expect(step.path, startsWith('/admin'));
      }
    });

    test('doing something ticks it off', () async {
      final done = await checklistOf(containerWith(
        settings: testSettings(
          serviceTimes: const [ServiceTime(day: 'Sunday', time: '10:00 AM', label: 'Morning')],
        ),
      ));

      final step = done.firstWhere((s) => s.title.contains('service times'));
      expect(step.done, isTrue);
    });

    test('is derived, so deleting the last sermon un-ticks it', () async {
      // The reason this is computed rather than stored: a stored
      // checklist would still claim a sermon exists after the only one
      // was removed.
      final withSermon = containerWith(sermons: [testSermon(id: 's1')]);
      final without = containerWith();

      Future<bool> published(ProviderContainer c) async =>
          (await checklistOf(c)).firstWhere((s) => s.title.contains('sermon')).done;

      expect(await published(withSermon), isTrue);
      expect(await published(without), isFalse);
    });

    test('a church that has switched giving off is not nagged about it', () async {
      final steps = await checklistOf(containerWith(
        settings: testSettings(features: const FeatureFlags(giving: false)),
      ));

      expect(steps.map((s) => s.title), isNot(contains('Add your giving link')));
    });

    test('it can actually be finished', () async {
      // A checklist that cannot reach the end is furniture. "Invite your
      // team" used to be hardcoded unfinished, which would have left
      // every church at n-1 forever.
      final steps = await checklistOf(containerWith(
        settings: testSettings(
          aboutBody: 'A' * 60,
          serviceTimes: const [ServiceTime(day: 'Sunday', time: '10:00 AM', label: 'Morning')],
          colors: churchThemes[2].colors,
          contact: const ContactInfo(
            address: '1 Test St, Hometown, ST',
            phone: '',
            email: '',
            mapUrl: '',
          ),
        ),
        sermons: [testSermon(id: 's1')],
        events: [testEvent(id: 'e1')],
        members: [
          testMember(uid: 'a', role: UserRole.admin),
          testMember(uid: 'b', role: UserRole.staff),
        ],
      ));

      expect(steps.where((s) => !s.done), isEmpty, reason: steps.where((s) => !s.done).map((s) => s.title).join(', '));
    });
  });

  group('on the dashboard', () {
    Future<void> pumpAdmin(WidgetTester tester, ProviderContainer container) async {
      tester.view.physicalSize = const Size(1400, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        UncontrolledProviderScope(container: container, child: const YokedChurchApp()),
      );
      await tester.pumpAndSettle();
      container.read(routerProvider).go(churchPath(demoChurchId, '/admin'));
      await tester.pumpAndSettle();
    }

    testWidgets('a new church is told what to do first', (tester) async {
      await pumpAdmin(tester, containerWith(settings: brandNew()));

      expect(find.text('Finish setting up'), findsOneWidget);
      expect(find.text('Add your service times'), findsOneWidget);
    });

    testWidgets('and the list goes away once there is nothing left', (tester) async {
      // A permanent "8 of 8" is clutter on every visit forever after.
      await pumpAdmin(
        tester,
        containerWith(
          settings: testSettings(
            aboutBody: 'A' * 60,
            serviceTimes: const [ServiceTime(day: 'Sunday', time: '10:00 AM', label: 'Morning')],
            colors: churchThemes[2].colors,
            contact: const ContactInfo(
              address: '1 Test St, Hometown, ST',
              phone: '',
              email: '',
              mapUrl: '',
            ),
          ),
          sermons: [testSermon(id: 's1')],
          events: [testEvent(id: 'e1')],
          members: [
            testMember(uid: 'a', role: UserRole.admin),
            testMember(uid: 'b', role: UserRole.staff),
          ],
        ),
      );

      expect(find.text('Finish setting up'), findsNothing);
    });
  });

  group('the themes', () {
    test('are genuinely different from each other', () {
      // Nine near-identical blues is a harder choice than four obviously
      // different ones.
      final primaries = churchThemes.map((t) => t.colors.primary.toARGB32()).toSet();
      expect(primaries.length, churchThemes.length);
    });

    test('each says what it is for, not just what it is called', () {
      for (final theme in churchThemes) {
        expect(theme.name, isNotEmpty);
        expect(theme.description.length, greaterThan(20), reason: '"Slate" tells nobody anything');
      }
    });

    test('the one a new church starts as is in the gallery', () {
      // Otherwise the first thing the settings screen says to a brand-new
      // church is that its colours are not one of the options.
      expect(
        churchThemes.any((t) => t.matches(BrandColors.fallback)),
        isTrue,
      );
    });

    testWidgets('picking one fills in the hex fields', (tester) async {
      tester.view.physicalSize = const Size(1400, 4000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final container = containerWith(settings: brandNew());
      await tester.pumpWidget(
        UncontrolledProviderScope(container: container, child: const YokedChurchApp()),
      );
      await tester.pumpAndSettle();
      container.read(routerProvider).go(churchPath(demoChurchId, '/admin/settings'));
      await tester.pumpAndSettle();

      final meadow = churchThemes.firstWhere((t) => t.name == 'Meadow');
      final swatch = find.text('Meadow');
      await tester.ensureVisible(swatch);
      await tester.pumpAndSettle();
      await tester.tap(swatch);
      await tester.pumpAndSettle();

      // The hex codes stay the record; a theme is a shortcut into them,
      // so the field has to actually change or the two would disagree at
      // the moment of saving.
      final hex = '#${(meadow.colors.primary.toARGB32() & 0xFFFFFF).toRadixString(16).toUpperCase()}';
      expect(find.widgetWithText(TextField, hex), findsOneWidget);
    });
  });
}
