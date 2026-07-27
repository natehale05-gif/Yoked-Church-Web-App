import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yoked_church_app/app/app.dart';
import 'package:yoked_church_app/app/router.dart';
import 'package:yoked_church_app/core/config/church_settings.dart';
import 'package:yoked_church_app/features/church_info/domain/church_info.dart';

import '../fakes/fake_repositories.dart';

/// Widget tests for the public site, running entirely on fake
/// repositories - no Firebase, no emulator, no network.
void main() {
  Future<void> pumpApp(WidgetTester tester, {List<Override>? overrides}) async {
    // Wide surface so the desktop nav renders rather than the hamburger.
    tester.view.physicalSize = const Size(1400, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(overrides: overrides ?? fakeOverrides(), child: const YokedChurchApp()),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('home renders the church name from settings', (tester) async {
    await pumpApp(tester, overrides: fakeOverrides(settings: testSettings(churchName: 'Grace Chapel')));

    expect(find.text('Grace Chapel'), findsWidgets);
    expect(find.text('Plan a Visit'), findsOneWidget);
  });

  testWidgets('nav reflects feature flags - disabled features are hidden', (tester) async {
    await pumpApp(
      tester,
      overrides: fakeOverrides(
        settings: testSettings(
          features: const FeatureFlags(sermons: false, events: false, giving: false),
        ),
      ),
    );

    expect(find.widgetWithText(TextButton, 'Sermons'), findsNothing);
    expect(find.widgetWithText(TextButton, 'Events'), findsNothing);
    expect(find.widgetWithText(ElevatedButton, 'Give'), findsNothing);
    // Always-on destinations remain.
    expect(find.widgetWithText(TextButton, 'About'), findsOneWidget);
  });

  testWidgets('sermons page lists published sermons and filters by search', (tester) async {
    await pumpApp(
      tester,
      overrides: fakeOverrides(
        sermons: [
          testSermon(id: 'a', title: 'Rest for the Weary'),
          testSermon(id: 'b', title: 'Faith Over Fear'),
          testSermon(id: 'c', title: 'Hidden Draft', published: false),
        ],
      ),
    );

    await tester.tap(find.widgetWithText(TextButton, 'Sermons'));
    await tester.pumpAndSettle();

    expect(find.text('Rest for the Weary'), findsOneWidget);
    expect(find.text('Faith Over Fear'), findsOneWidget);
    expect(find.text('Hidden Draft'), findsNothing);

    await tester.enterText(find.byType(TextField).first, 'fear');
    await tester.pumpAndSettle();

    expect(find.text('Faith Over Fear'), findsOneWidget);
    expect(find.text('Rest for the Weary'), findsNothing);
  });

  testWidgets('events page shows upcoming events and hides past ones', (tester) async {
    await pumpApp(
      tester,
      overrides: fakeOverrides(
        events: [
          testEvent(id: 'a', title: 'Future Picnic', start: DateTime.now().add(const Duration(days: 3))),
          testEvent(id: 'b', title: 'Last Year Retreat', start: DateTime.now().subtract(const Duration(days: 30))),
        ],
      ),
    );

    await tester.tap(find.widgetWithText(TextButton, 'Events'));
    await tester.pumpAndSettle();

    expect(find.text('Future Picnic'), findsOneWidget);
    expect(find.text('Last Year Retreat'), findsNothing);
  });

  testWidgets('about page renders staff bios from the repository', (tester) async {
    await pumpApp(
      tester,
      overrides: fakeOverrides(
        staff: const [
          StaffMember(id: '1', name: 'Jane Pastor', role: 'Lead Pastor', bio: 'Serving since 2014.'),
        ],
      ),
    );

    await tester.tap(find.widgetWithText(TextButton, 'About'));
    await tester.pumpAndSettle();

    expect(find.text('Jane Pastor'), findsOneWidget);
    expect(find.text('Lead Pastor'), findsOneWidget);
  });

  testWidgets('visit page renders service times, locations, and FAQs', (tester) async {
    await pumpApp(
      tester,
      overrides: fakeOverrides(
        locations: const [
          ChurchLocation(id: '1', name: 'Main Campus', address: '123 Faith Ave'),
        ],
        faqs: const [
          Faq(id: '1', question: 'What should I wear?', answer: 'Whatever you like.'),
        ],
      ),
    );

    await tester.tap(find.widgetWithText(TextButton, 'Visit'));
    await tester.pumpAndSettle();

    expect(find.text('Main Campus'), findsOneWidget);
    expect(find.text('What should I wear?'), findsOneWidget);
    expect(find.text('Sunday'), findsWidgets);
  });

  testWidgets('connect form validates and then submits to the repository', (tester) async {
    final connectRepo = FakeConnectRepository()..seedInMemory(const []);
    await pumpApp(tester, overrides: fakeOverrides(connect: connectRepo));

    await tester.tap(find.widgetWithText(TextButton, 'Connect'));
    await tester.pumpAndSettle();

    // Empty submit surfaces validation rather than writing anything.
    await tester.tap(find.widgetWithText(ElevatedButton, 'Submit'));
    await tester.pumpAndSettle();
    expect(find.text('Please enter your name'), findsOneWidget);
    expect(await connectRepo.fetchAll(), isEmpty);

    await tester.enterText(find.widgetWithText(TextFormField, 'Name'), 'Jane Visitor');
    await tester.enterText(find.widgetWithText(TextFormField, 'Email'), 'jane@example.com');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Submit'));
    await tester.pumpAndSettle();

    expect(find.text('Thank you!'), findsOneWidget);
    final stored = await connectRepo.fetchAll();
    expect(stored.single.name, 'Jane Visitor');
  });

  testWidgets('unknown route renders the not-found page, not a crash', (tester) async {
    tester.view.physicalSize = const Size(1400, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final container = ProviderContainer(overrides: fakeOverrides());
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const YokedChurchApp()),
    );
    await tester.pumpAndSettle();

    container.read(routerProvider).go('/definitely-not-a-page');
    await tester.pumpAndSettle();

    expect(find.text('Page not found'), findsOneWidget);
  });
}
