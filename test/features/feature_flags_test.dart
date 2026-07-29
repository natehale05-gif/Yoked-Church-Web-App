import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yoked_church_app/app/app.dart';
import 'package:yoked_church_app/app/router.dart';
import 'package:yoked_church_app/core/config/church_settings.dart';
import 'package:yoked_church_app/features/admin/presentation/admin_header.dart';
import 'package:yoked_church_app/features/auth/domain/app_user.dart';

import '../fakes/fake_repositories.dart';

/// Every switch on the church settings screen has to control something.
/// M4 existed because four of them controlled nothing at all - an admin
/// could flip them and watch the site not change. These tests are what
/// stops that regressing as more flags arrive.
void main() {
  Future<ProviderContainer> pumpApp(WidgetTester tester, List<Override> overrides) async {
    tester.view.physicalSize = const Size(1400, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final container = ProviderContainer(overrides: overrides);
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const YokedChurchApp()),
    );
    await tester.pumpAndSettle();
    return container;
  }

  String pathOf(ProviderContainer c) =>
      c.read(routerProvider).routerDelegate.currentConfiguration.uri.path;

  /// Every flag key the settings screen renders a switch for, paired with
  /// the routes it owns. A flag with no routes here would be a switch
  /// that does nothing.
  const ownedRoutes = <String, List<String>>{
    'sermons': ['/sermons', '/sermons/s1', '/admin/sermons', '/account/notes'],
    'events': ['/events', '/admin/events'],
    'giving': ['/give'],
    'connect': ['/connect', '/admin/connect'],
    'devotionals': ['/devotionals', '/devotionals/d1', '/admin/devotionals'],
    'readingPlans': ['/reading-plans', '/reading-plans/p1', '/admin/reading-plans', '/account/reading'],
    'resources': ['/resources', '/admin/resources'],
    'prayerWall': ['/account/prayer', '/admin/prayer'],
    'kidsCheckIn': ['/account/kids', '/admin/kids'],
    'roomBooking': ['/account/bookings', '/admin/rooms'],
    'attendance': ['/admin/attendance'],
    'forms': ['/forms', '/forms/summer-camp', '/admin/forms'],
  };

  test('every flag in the settings screen is covered by this test', () {
    // groups and volunteering gate tabs and sections rather than whole
    // routes; they are asserted separately below and in their own
    // feature tests.
    const gatedElsewhere = {'groups', 'volunteering'};
    final allKeys = const FeatureFlags().toMap().keys.toSet();

    expect(
      allKeys.difference(ownedRoutes.keys.toSet()).difference(gatedElsewhere),
      isEmpty,
      reason: 'a new flag needs either a route guard or an explicit exemption',
    );
  });

  group('turning a flag off closes its routes', () {
    for (final entry in ownedRoutes.entries) {
      testWidgets('${entry.key} closes ${entry.value.length} route(s)', (tester) async {
        final container = await pumpApp(
          tester,
          fakeOverrides(
            settings: testSettings(
              features: FeatureFlags.fromMap({...const FeatureFlags().toMap(), entry.key: false}),
            ),
            // Signed in as admin so admin routes aren't bounced for the
            // wrong reason.
            signedInAs: testMember(uid: 'a1', role: UserRole.admin),
          ),
        );

        for (final path in entry.value) {
          container.read(routerProvider).go(path);
          await tester.pumpAndSettle();
          expect(
            pathOf(container),
            isNot(path),
            reason: '$path should be closed when ${entry.key} is off',
          );
        }
      });
    }
  });

  group('the staff dashboard reflects the flags', () {
    test('a church running nothing sees only the always-on tools', () {
      final tabs = adminTabs(FeatureFlags.fromMap({
        for (final key in const FeatureFlags().toMap().keys) key: false,
      }));

      expect(
        tabs.map((t) => t.path),
        [
          '/admin',
          '/admin/announcements',
          '/admin/reports',
          '/admin/members',
          '/admin/settings',
          '/admin/audit',
        ],
      );
    });

    test('a church running everything sees every tool', () {
      final tabs = adminTabs(const FeatureFlags());
      expect(tabs.map((t) => t.path), contains('/admin/devotionals'));
      expect(tabs.map((t) => t.path), contains('/admin/reading-plans'));
      expect(tabs.map((t) => t.path), contains('/admin/resources'));
      expect(tabs.map((t) => t.path), contains('/admin/prayer'));
    });

    test('admin-only tools are filtered out for plain staff', () {
      final staffTabs = visibleAdminTabs(const FeatureFlags(), isAdmin: false).map((t) => t.path);
      expect(staffTabs, isNot(contains('/admin/settings')));
      expect(staffTabs, isNot(contains('/admin/members')));
      expect(staffTabs, isNot(contains('/admin/audit')));
      expect(staffTabs, isNot(contains('/admin/reports')));
      expect(staffTabs, contains('/admin/prayer'));
    });
  });

  group('podcast link', () {
    testWidgets('appears on the sermons page when configured', (tester) async {
      final base = testSettings();
      final container = await pumpApp(
        tester,
        fakeOverrides(
          settings: base.copyWith(
            social: const SocialLinks(
              facebook: '',
              instagram: '',
              youtube: '',
              givingUrl: '',
              liveStreamUrl: '',
              podcastUrl: 'https://podcasts.example.org/feed.xml',
            ),
          ),
        ),
      );
      container.read(routerProvider).go('/sermons');
      await tester.pumpAndSettle();

      expect(find.text('Listen on your podcast app'), findsOneWidget);
    });

    testWidgets('is absent when the church has no podcast', (tester) async {
      final container = await pumpApp(tester, fakeOverrides(settings: testSettings()));
      container.read(routerProvider).go('/sermons');
      await tester.pumpAndSettle();

      expect(find.text('Listen on your podcast app'), findsNothing);
    });

    test('round-trips through the settings map', () {
      const links = SocialLinks(
        facebook: 'f',
        instagram: 'i',
        youtube: 'y',
        givingUrl: 'g',
        liveStreamUrl: 'l',
        podcastUrl: 'https://podcasts.example.org/feed.xml',
      );
      expect(SocialLinks.fromMap(links.toMap()).podcastUrl, links.podcastUrl);
    });

    test('an older settings document with no podcastUrl still loads', () {
      final legacy = SocialLinks.fromMap(const {
        'facebook': 'f',
        'instagram': 'i',
        'youtube': 'y',
        'givingUrl': 'g',
        'liveStreamUrl': 'l',
      });
      expect(legacy.podcastUrl, isEmpty);
      expect(legacy.givingUrl, 'g');
    });
  });
}
