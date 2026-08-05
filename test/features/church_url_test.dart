import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yoked_church_app/app/app.dart';
import 'package:yoked_church_app/app/router.dart';
import 'package:yoked_church_app/core/config/settings_providers.dart';
import 'package:yoked_church_app/core/config/tenant.dart';
import 'package:yoked_church_app/features/auth/domain/app_user.dart';

import '../fakes/fake_repositories.dart';

/// A church has an address now.
///
/// Before this, which church you were in lived in `shared_preferences`,
/// so there was no link anyone could send. These cover the shape that
/// makes true, and the failure it invites: a URL that is accepted while
/// the data layer is still pointing at somebody else's church.
void main() {
  Future<ProviderContainer> pumpAt(
    WidgetTester tester,
    String location, {
    String? churchId,
    AppUser? signedInAs,
  }) async {
    tester.view.physicalSize = const Size(1400, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final container = ProviderContainer(
      overrides: [
        ...fakeOverrides(churchId: churchId, signedInAs: signedInAs),
        // Church-aware settings, wired from `currentChurchIdProvider`
        // exactly as `localOverrides()` wires the real one.
        //
        // The default fake answers "Test Church" whichever church is
        // selected, so it cannot tell one from another - and a test that
        // cannot tell them apart cannot catch a URL that is accepted
        // while the data layer still points at the previous church,
        // which is the whole failure this file exists for.
        settingsRepositoryProvider.overrideWith(
          (ref) => FakeSettingsRepository(
            testSettings(churchName: 'Church of ${ref.watch(currentChurchIdProvider)}'),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    // Navigating before the first pump is as close as a widget test gets
    // to opening the app *at* an address rather than walking to it.
    container.read(routerProvider).go(location);

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const YokedChurchApp()),
    );
    await tester.pumpAndSettle();
    return container;
  }

  String pathOf(ProviderContainer c) =>
      c.read(routerProvider).routerDelegate.currentConfiguration.uri.path;

  group('reading a church out of a location', () {
    test('finds the one a church-scoped path names', () {
      expect(churchIdFromLocation('/c/riverside-fellowship/sermons'), 'riverside-fellowship');
      expect(churchIdFromLocation('/c/riverside-fellowship'), 'riverside-fellowship');
    });

    test('finds none in the product\'s own pages', () {
      for (final path in ['/', '/start', '/choose-church', '/sermons', '/c', '/c/']) {
        expect(churchIdFromLocation(path), isNull, reason: '$path names no church');
      }
    });

    test('leaves the path the guards were written against', () {
      // Every feature flag, role check and admin-only rule still reasons
      // about bare paths. Only this function knows about the prefix.
      expect(subPathOf('/c/riverside/admin/settings'), '/admin/settings');
      expect(subPathOf('/c/riverside'), '/');
      expect(subPathOf('/sermons'), '/sermons');
    });

    test('builds an address', () {
      expect(churchPath('riverside'), '/c/riverside');
      expect(churchPath('riverside', '/sermons'), '/c/riverside/sermons');
      expect(churchPath('riverside', '/'), '/c/riverside');
    });
  });

  group('a link to a church', () {
    testWidgets('opens that church, not the last one visited', (tester) async {
      // The whole point of the feature, and the assertion that matters:
      // not that the URL was accepted, but that the app *is* Riverside -
      // its settings, and therefore its content and its colours.
      final container = await pumpAt(
        tester,
        '/c/riverside-fellowship/sermons',
        churchId: demoChurchId,
      );

      expect(pathOf(container), '/c/riverside-fellowship/sermons');
      expect(container.read(selectedChurchIdProvider), 'riverside-fellowship');
      expect(container.read(settingsProvider).churchName, 'Church of riverside-fellowship');
    });

    testWidgets('works for someone who has never chosen a church', (tester) async {
      final container = await pumpAt(tester, '/c/st-augustine', churchId: null);

      expect(pathOf(container), '/c/st-augustine');
      expect(container.read(selectedChurchIdProvider), 'st-augustine');
    });

    testWidgets('every page of a church is addressable', (tester) async {
      final container = await pumpAt(tester, '/', churchId: demoChurchId);

      for (final page in ['/sermons', '/events', '/give', '/about']) {
        container.read(routerProvider).go(churchPath(demoChurchId, page));
        await tester.pumpAndSettle();
        expect(pathOf(container), '/c/$demoChurchId$page');
      }
    });
  });

  group('links written before churches had addresses', () {
    testWidgets('still work, and end up in the church you are in', (tester) async {
      // Sixty-six `context.go('/sermons')` call sites across thirty
      // files. Rewriting them all would have been the other way to do
      // this, and every missed one would have been a dead link.
      final container = await pumpAt(tester, '/', churchId: demoChurchId);

      container.read(routerProvider).go('/sermons');
      await tester.pumpAndSettle();

      expect(pathOf(container), '/c/$demoChurchId/sermons');
    });

    testWidgets('"home" means the church home', (tester) async {
      final container = await pumpAt(tester, '/c/$demoChurchId/events', churchId: demoChurchId);

      container.read(routerProvider).go('/');
      await tester.pumpAndSettle();

      expect(pathOf(container), '/c/$demoChurchId');
    });
  });

  group('the front door', () {
    testWidgets('a stranger gets the product, not a list of other churches', (tester) async {
      final container = await pumpAt(tester, '/', churchId: null);

      expect(pathOf(container), '/');
      expect(find.textContaining('Everything your church'), findsOneWidget);
      expect(find.text('Start your church site'), findsOneWidget);
      expect(find.text('Find your church'), findsOneWidget);
    });

    testWidgets('someone who has a church goes straight to it', (tester) async {
      final container = await pumpAt(tester, '/', churchId: demoChurchId);

      expect(pathOf(container), '/c/$demoChurchId');
    });

    testWidgets('the picker is still reachable, and still works', (tester) async {
      final container = await pumpAt(tester, '/choose-church', churchId: null);

      await tester.tap(find.text('Riverside Fellowship'));
      await tester.pumpAndSettle();

      expect(pathOf(container), '/c/riverside-fellowship');
      expect(container.read(settingsProvider).churchName, 'Church of riverside-fellowship');
    });
  });

  group('the front door renders its own words', () {
    testWidgets('no button label falls back to a font we do not ship', (tester) async {
      // This is not a nitpick. A `ButtonStyle.textStyle` *replaces* the
      // theme's rather than merging with it, so one written without a
      // `fontFamily` silently asks for a font this app does not bundle.
      // On a network that cannot reach Google's font CDN the glyphs
      // never arrive and the button renders as an empty pill - which is
      // exactly what the landing page did, and what no `find.text`
      // assertion can see, because the widget is there either way.
      await pumpAt(tester, '/', churchId: null);

      final buttons = find.byWidgetPredicate((w) => w is ButtonStyleButton);
      expect(buttons, findsWidgets, reason: 'nothing to check means the test proves nothing');

      for (final element in buttons.evaluate()) {
        final button = element.widget as ButtonStyleButton;
        final style = button.style?.textStyle?.resolve(const <WidgetState>{});
        if (style == null) continue;
        expect(
          style.fontFamily,
          isNotNull,
          reason: 'a button style that sets textStyle must name the family too',
        );
      }
    });
  });

  group('the guards still guard, one church down', () {
    testWidgets('a signed-out visitor is sent to that church\'s sign-in', (tester) async {
      final container = await pumpAt(tester, '/c/riverside-fellowship/admin', churchId: null);

      expect(
        pathOf(container),
        '/c/riverside-fellowship/sign-in',
        reason: 'bouncing to a church-less /sign-in would lose which church they were joining',
      );
    });

    testWidgets('a member cannot reach the dashboard', (tester) async {
      final container = await pumpAt(
        tester,
        '/c/$demoChurchId/admin',
        churchId: demoChurchId,
        signedInAs: testMember(),
      );

      expect(pathOf(container), '/c/$demoChurchId/account');
    });

    testWidgets('staff are kept out of the admin-only screens', (tester) async {
      final container = await pumpAt(
        tester,
        '/c/$demoChurchId/admin/settings',
        churchId: demoChurchId,
        signedInAs: testMember(role: UserRole.staff),
      );

      expect(pathOf(container), '/c/$demoChurchId/admin');
    });
  });
}
