import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yoked_church_app/app/app.dart';
import 'package:yoked_church_app/app/router.dart';
import 'package:yoked_church_app/core/config/church_settings.dart';
import 'package:yoked_church_app/core/widgets/app_shell.dart';

import '../fakes/fake_repositories.dart';

/// A phone should get app navigation, not a website with a hamburger.
/// These fix the shape of that: a bar at the bottom, within a thumb's
/// reach, that survives moving between pages.
void main() {
  Future<ProviderContainer> pumpAt(
    WidgetTester tester,
    Size size, {
    ChurchSettings? settings,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final container = ProviderContainer(overrides: fakeOverrides(settings: settings));
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const YokedChurchApp()),
    );
    await tester.pumpAndSettle();
    return container;
  }

  const phone = Size(390, 844);
  const desktop = Size(1400, 1000);

  group('on a phone', () {
    testWidgets('navigation is a bottom bar, not a hamburger', (tester) async {
      await pumpAt(tester, phone);

      expect(find.byType(NavigationBar), findsOneWidget);
      expect(
        find.byTooltip('Menu'),
        findsNothing,
        reason: 'two navigations is one too many; the bar replaces the hamburger',
      );
    });

    testWidgets('the bar stays put while moving between pages', (tester) async {
      final container = await pumpAt(tester, phone);

      for (final path in ['/sermons', '/events', '/give', '/about']) {
        container.read(routerProvider).go(path);
        await tester.pumpAndSettle();
        expect(find.byType(NavigationBar), findsOneWidget, reason: 'lost the bar on $path');
      }
    });

    testWidgets('the bar follows where you are', (tester) async {
      final container = await pumpAt(tester, phone);

      NavigationBar bar() => tester.widget<NavigationBar>(find.byType(NavigationBar));
      expect(bar().selectedIndex, 0);

      container.read(routerProvider).go('/events');
      await tester.pumpAndSettle();
      expect(bar().selectedIndex, bottomNav(testSettings()).indexWhere((d) => d.path == '/events'));
    });

    testWidgets('a page reached from More keeps More lit, not Home', (tester) async {
      // Otherwise the bar tells a member they are on the home page while
      // they are reading a devotional.
      final container = await pumpAt(tester, phone);

      container.read(routerProvider).go('/devotionals');
      await tester.pumpAndSettle();

      final bar = tester.widget<NavigationBar>(find.byType(NavigationBar));
      expect(bar.selectedIndex, bottomNav(testSettings()).length - 1);
    });
  });

  group('on a desktop', () {
    testWidgets('there is no bottom bar', (tester) async {
      await pumpAt(tester, desktop);
      expect(find.byType(NavigationBar), findsNothing);
    });
  });

  group('the destinations', () {
    test('never exceed what a bar can hold', () {
      // Material stops making them tappable past five, and a person
      // scanning a bar cannot hold more than that either.
      expect(bottomNav(testSettings()).length, lessThanOrEqualTo(5));
    });

    test('a church that runs nothing still gets Home and More', () {
      final bare = testSettings(
        features: FeatureFlags.fromMap({
          for (final key in const FeatureFlags().toMap().keys) key: false,
        }),
      );
      final destinations = bottomNav(bare);

      expect(destinations.first.path, '/');
      expect(destinations.last.path, isEmpty, reason: 'the last entry is always More');
      expect(destinations.length, 2);
    });

    test('a switched-off feature loses its tab', () {
      final noGiving = testSettings(features: const FeatureFlags(giving: false));
      expect(bottomNav(noGiving).map((d) => d.path), isNot(contains('/give')));
      expect(bottomNav(testSettings()).map((d) => d.path), contains('/give'));
    });
  });
}
