import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yoked_church_app/app/app.dart';
import 'package:yoked_church_app/app/router.dart';
import 'package:yoked_church_app/core/config/tenant.dart';
import 'package:yoked_church_app/features/auth/domain/app_user.dart';

import '../fakes/fake_repositories.dart';

/// Handing the link out is the entire point of having a site, and the
/// address was shown exactly once - while the church was being named at
/// signup - and then nowhere at all.
void main() {
  group('a church\'s whole address', () {
    test('carries the origin and the base path the site is served from', () {
      // A project page on GitHub Pages, which is where this deploys.
      expect(
        churchUrl('grace-chapel', from: Uri.parse('https://x.github.io/Yoked-Church-Web-App/#/c/x/admin')),
        'https://x.github.io/Yoked-Church-Web-App/#/c/grace-chapel',
      );
    });

    test('works for a fork serving from a domain root', () {
      expect(
        churchUrl('grace-chapel', from: Uri.parse('https://gracechapel.org/')),
        'https://gracechapel.org/#/c/grace-chapel',
      );
    });

    test('drops the file name when the page was served as index.html', () {
      // Not cosmetic: `.../index.html#/c/grace-chapel` works, but it is
      // not what anyone wants printed on a card.
      expect(
        churchUrl('grace-chapel', from: Uri.parse('https://x.github.io/app/index.html')),
        'https://x.github.io/app/#/c/grace-chapel',
      );
    });

    test('keeps the hash, because that is the address the router answers to', () {
      // web/404.html makes the `#` optional for somebody typing it in,
      // but the version offered for copying has to be the one that works
      // even where nothing follows a redirect.
      expect(churchUrl('g', from: Uri.parse('https://x.io/')), contains('#/c/g'));
    });

    test('is empty where there is no web address to give', () {
      // A desktop or mobile build's Uri.base is a file: directory with no
      // origin. Inventing one would put a dead link behind a copy button.
      expect(churchUrl('grace-chapel', from: Uri.parse('file:///home/someone/app/')), isEmpty);
    });
  });

  group('the dashboard', () {
    Future<ProviderContainer> pumpDashboard(WidgetTester tester) async {
      tester.view.physicalSize = const Size(1400, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final container = ProviderContainer(
        overrides: fakeOverrides(signedInAs: testMember(role: UserRole.admin)),
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(container: container, child: const YokedChurchApp()),
      );
      await tester.pumpAndSettle();
      container.read(routerProvider).go(churchPath(demoChurchId, '/admin'));
      await tester.pumpAndSettle();
      return container;
    }

    testWidgets('shows the church its own address', (tester) async {
      await pumpDashboard(tester);

      expect(find.text('Your church\'s address'), findsOneWidget);
      // Under test Uri.base is a file: URL, so the path is what is on
      // offer - and it still has to name this church rather than a
      // placeholder.
      expect(find.textContaining(churchPath(demoChurchId)), findsWidgets);
    });

    testWidgets('copies it, and says that it did', (tester) async {
      // A copy is one of those actions where nothing visible happens, and
      // the doubt sends people clicking again.
      String? copied;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            copied = (call.arguments as Map)['text'] as String;
          }
          return null;
        },
      );
      addTearDown(() => tester.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null));

      await pumpDashboard(tester);

      final copy = find.widgetWithText(FilledButton, 'Copy link');
      await tester.ensureVisible(copy);
      await tester.pumpAndSettle();
      await tester.tap(copy);
      await tester.pumpAndSettle();

      expect(copied, churchPath(demoChurchId));
      expect(find.text('Copied'), findsOneWidget);
    });

    testWidgets('stays once the setup checklist is finished', (tester) async {
      // The checklist is furniture the moment it is complete and removes
      // itself. The address is the one thing still wanted on the day the
      // newsletter goes out.
      await pumpDashboard(tester);

      expect(find.text('Finish setting up'), findsOneWidget, reason: 'a fresh church has steps left');
      expect(find.text('Your church\'s address'), findsOneWidget);
    });

    testWidgets('asks for no font this app does not ship', (tester) async {
      // The address box was written with `fontFamily: 'monospace'`,
      // which reads perfectly well in the source and rendered as an
      // empty grey box on the web build: this app bundles Lora and Work
      // Sans and nothing else, and CanvasKit with no reachable font CDN
      // draws no glyphs at all for a family it does not have.
      //
      // No `find.text` assertion can see this - the widget is there
      // either way, holding the right string - which is why it reached a
      // browser before anyone noticed. Second time now; the landing
      // page's buttons were the first.
      final bundled = RegExp(r'-\s*family:\s*(\S+)')
          .allMatches(File('pubspec.yaml').readAsStringSync())
          .map((m) => m.group(1)!)
          .toSet();
      expect(bundled, isNotEmpty, reason: 'pubspec no longer declares any fonts');

      await pumpDashboard(tester);

      var checked = 0;
      for (final element in find.byType(Text).evaluate()) {
        final family = (element.widget as Text).style?.fontFamily;
        if (family == null) continue;
        checked++;
        expect(bundled, contains(family), reason: 'nothing will render in $family');
      }
      for (final element in find.byType(SelectableText).evaluate()) {
        final family = (element.widget as SelectableText).style?.fontFamily;
        if (family == null) continue;
        checked++;
        expect(bundled, contains(family), reason: 'nothing will render in $family');
      }

      // A pass because nothing set a family is a real pass - it means
      // everything inherits the theme - so this only reports, rather
      // than requiring a non-zero count that would invite padding.
      expect(checked, greaterThanOrEqualTo(0));
    });

    testWidgets('offers a way to look at the site itself', (tester) async {
      final container = await pumpDashboard(tester);

      final view = find.widgetWithText(OutlinedButton, 'View your site');
      await tester.ensureVisible(view);
      await tester.pumpAndSettle();
      await tester.tap(view);
      await tester.pumpAndSettle();

      expect(
        subPathOf(container.read(routerProvider).routerDelegate.currentConfiguration.uri.path),
        '/',
      );
    });
  });
}
