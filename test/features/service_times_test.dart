import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yoked_church_app/app/app.dart';
import 'package:yoked_church_app/app/router.dart';
import 'package:yoked_church_app/core/config/church_settings.dart';
import 'package:yoked_church_app/core/config/tenant.dart';

import '../fakes/fake_repositories.dart';

/// When a church meets is shown in two places, and used to be two copies
/// of one card. That duplication is why the same unreadable colour lived
/// in both of them, so the card is now one widget.
///
/// The two pages do differ in what they do with a church that has none
/// listed, and that difference is deliberate. The home page is a montage
/// whose sections all vanish when they are empty - sermons, events,
/// quick links, the welcome. Plan a Visit is *about* when to come, so a
/// page that quietly omitted the times would be the least useful version
/// of itself.
void main() {
  Future<void> pumpAt(WidgetTester tester, String route, ChurchSettings settings) async {
    tester.view.physicalSize = const Size(1400, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final container = ProviderContainer(overrides: fakeOverrides(settings: settings));
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const YokedChurchApp()),
    );
    await tester.pumpAndSettle();
    container.read(routerProvider).go(churchPath(demoChurchId, route));
    await tester.pumpAndSettle();
  }

  const listed = [
    ServiceTime(day: 'Sunday', time: '9:00 AM', label: 'Traditional'),
    ServiceTime(day: 'Sunday', time: '11:00 AM', label: 'Contemporary'),
  ];

  group('one card, both pages', () {
    testWidgets('the home page lists the times', (tester) async {
      await pumpAt(tester, '/', testSettings(serviceTimes: listed));

      expect(find.text('Join Us'), findsOneWidget);
      expect(find.text('9:00 AM'), findsOneWidget);
      expect(find.text('11:00 AM'), findsOneWidget);
    });

    testWidgets('and so does Plan a Visit', (tester) async {
      await pumpAt(tester, '/visit', testSettings(serviceTimes: listed));

      expect(find.text('Service Times'), findsOneWidget);
      expect(find.text('9:00 AM'), findsOneWidget);
    });
  });

  group('a church with none listed', () {
    testWidgets('drops the section from the home page entirely', (tester) async {
      // Not an empty state here. Every section of this page disappears
      // when it has nothing to show, and a heading over a shrug would be
      // the only one that did not.
      await pumpAt(tester, '/', testSettings(serviceTimes: const []));

      expect(find.text('Join Us'), findsNothing);
    });

    testWidgets('but says so on Plan a Visit', (tester) async {
      await pumpAt(tester, '/visit', testSettings(serviceTimes: const []));

      expect(find.text('Service Times'), findsOneWidget);
      expect(
        find.textContaining('not listed yet'),
        findsOneWidget,
        reason: 'the page exists to answer this question; silence is not an answer',
      );
    });

    testWidgets('without implying there used to be some', (tester) async {
      // The old wording was "Service times are being updated", which is
      // fine for an established church between timetables and wrong on
      // the day a church signs up - which is the day it is most likely
      // to hand its address out.
      await pumpAt(tester, '/visit', testSettings(serviceTimes: const []));

      expect(find.textContaining('being updated'), findsNothing);
    });
  });
}
