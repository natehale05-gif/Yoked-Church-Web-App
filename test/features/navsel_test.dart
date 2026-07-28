import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yoked_church_app/app/app.dart';
import 'package:yoked_church_app/app/router.dart';
import 'package:yoked_church_app/core/config/church_settings.dart';

import '../fakes/fake_repositories.dart';

void main() {
  /// The nav bar is built as `const AppNavBar()`, so Dart canonicalises it
  /// to one instance and Flutter skips the subtree on rebuild. It has to
  /// listen to the router itself, or the highlight silently sticks on
  /// whichever page happened to be open first.
  testWidgets('the nav bar highlights the page you are actually on', (tester) async {
    tester.view.physicalSize = const Size(1400, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final container = ProviderContainer(overrides: fakeOverrides());
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const YokedChurchApp()),
    );
    await tester.pumpAndSettle();

    FontWeight? weightOf(String label) {
      final finder = find.descendant(of: find.byType(AppBar), matching: find.text(label));
      return tester.widget<Text>(finder.first).style?.fontWeight;
    }

    expect(weightOf('Home'), FontWeight.w700, reason: 'starts on the home page');

    for (final (path, label) in [
      ('/events', 'Events'),
      // Both live under the "Grow" menu, which highlights for either.
      ('/devotionals', 'Grow'),
      ('/reading-plans', 'Grow'),
      ('/sermons', 'Sermons'),
      ('/', 'Home'),
    ]) {
      container.read(routerProvider).go(path);
      await tester.pumpAndSettle();

      expect(weightOf(label), FontWeight.w700, reason: '$label should be selected on $path');
      for (final other in ['Home', 'Events', 'Grow', 'Sermons']) {
        if (other == label) continue;
        expect(weightOf(other), FontWeight.w500, reason: '$other should not be selected on $path');
      }
    }
  });

  testWidgets('the Grow menu disappears when its features are all off', (tester) async {
    tester.view.physicalSize = const Size(1400, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final container = ProviderContainer(
      overrides: fakeOverrides(
        settings: testSettings(
          features: const FeatureFlags(devotionals: false, readingPlans: false),
        ),
      ),
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const YokedChurchApp()),
    );
    await tester.pumpAndSettle();

    expect(find.descendant(of: find.byType(AppBar), matching: find.text('Grow')), findsNothing);
    expect(find.descendant(of: find.byType(AppBar), matching: find.text('Sermons')), findsOneWidget);
  });
}
