import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yoked_church_app/app/app.dart';
import 'package:yoked_church_app/app/router.dart';
import 'package:yoked_church_app/core/config/tenant.dart';
import 'package:yoked_church_app/features/churches/data/church_directory_repository.dart';
import 'package:yoked_church_app/features/churches/domain/church_summary.dart';

import '../fakes/fake_repositories.dart';

/// One app, many churches. These cover the two things that makes true:
/// nothing is reachable until a church is chosen, and choosing one
/// actually changes which church the app is.
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

  group('before a church is chosen', () {
    testWidgets('the app opens on the picker', (tester) async {
      final container = await pumpApp(tester, fakeOverrides(churchId: null));

      expect(pathOf(container), '/choose-church');
      expect(find.text('Find your church'), findsOneWidget);
    });

    testWidgets('every other route sends you there', (tester) async {
      // Not cosmetic: every screen reads its church's content and themes
      // itself from that church's settings. There is nothing to show.
      final container = await pumpApp(tester, fakeOverrides(churchId: null));

      for (final path in ['/sermons', '/events', '/give', '/account', '/admin']) {
        container.read(routerProvider).go(path);
        await tester.pumpAndSettle();
        expect(pathOf(container), '/choose-church', reason: '$path should need a church first');
      }
    });

    testWidgets('choosing one lets you in', (tester) async {
      final container = await pumpApp(tester, fakeOverrides(churchId: null));

      await tester.tap(find.text('Riverside Fellowship'));
      await tester.pumpAndSettle();

      expect(container.read(selectedChurchIdProvider), 'riverside-fellowship');
      expect(pathOf(container), '/');
    });
  });

  group('the picker', () {
    testWidgets('lists the bundled churches', (tester) async {
      await pumpApp(tester, fakeOverrides(churchId: null));

      expect(find.text('Yoked Church'), findsWidgets);
      expect(find.text('Riverside Fellowship'), findsOneWidget);
      expect(find.text("St Augustine's"), findsOneWidget);
    });

    testWidgets('filters as you type, and says so when nothing matches', (tester) async {
      await pumpApp(tester, fakeOverrides(churchId: null));

      await tester.enterText(find.byType(TextField).first, 'riverside');
      await tester.pumpAndSettle();
      expect(find.text('Riverside Fellowship'), findsOneWidget);
      expect(find.text("St Augustine's"), findsNothing);

      await tester.enterText(find.byType(TextField).first, 'zzzz');
      await tester.pumpAndSettle();
      expect(find.textContaining('No church matches'), findsOneWidget);
    });
  });

  group('the directory', () {
    test('reads the bundled churches', () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      final churches = await LocalChurchDirectoryRepository().fetchAll();

      expect(churches.map((c) => c.id), contains(demoChurchId));
      expect(churches.length, greaterThanOrEqualTo(3),
          reason: 'the demo needs more than one church for the picker to mean anything');
      for (final church in churches) {
        expect(church.id, isNotEmpty);
        expect(church.name, isNotEmpty);
      }
    });

    test('the demo churches are genuinely different, not renamed copies', () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      // If they shared a palette, switching church would look like
      // nothing happened, and the picker would demonstrate nothing.
      final raw = await LocalChurchDirectoryRepository.load();
      final primaries = raw.map((m) => (m['colors'] as Map)['primary']).toSet();
      expect(primaries.length, raw.length);
    });

    test('search covers name, town and tagline', () {
      const church = ChurchSummary(
        id: 'x',
        name: 'Riverside Fellowship',
        city: 'Riverside, OR',
        tagline: 'A place at the table for everyone.',
      );

      expect(church.matches('river'), isTrue);
      expect(church.matches('OR'), isTrue);
      expect(church.matches('table'), isTrue);
      expect(church.matches(''), isTrue, reason: 'an empty search shows everything');
      expect(church.matches('cathedral'), isFalse);
    });

    test('a town is pulled out of a postal address', () {
      final church = ChurchSummary.fromMap('x', const {
        'churchName': 'Somewhere',
        'contact': {'address': '123 Faith Ave, Hometown, ST 00000'},
      });
      expect(church.city, 'Hometown, ST');
    });

    test('an address that does not fit yields nothing rather than nonsense', () {
      final church = ChurchSummary.fromMap('x', const {
        'churchName': 'Somewhere',
        'contact': {'address': 'Behind the old mill'},
      });
      expect(church.city, isEmpty);
    });
  });
}
