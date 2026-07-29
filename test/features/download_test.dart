import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yoked_church_app/app/app.dart';
import 'package:yoked_church_app/app/router.dart';
import 'package:yoked_church_app/core/config/church_settings.dart';
import 'package:yoked_church_app/core/widgets/app_shell.dart';
import 'package:yoked_church_app/features/downloads/domain/app_download.dart';

import '../fakes/fake_repositories.dart';

void main() {
  Future<ProviderContainer> pumpApp(WidgetTester tester, ChurchSettings settings) async {
    tester.view.physicalSize = const Size(1400, 3000);
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

  String pathOf(ProviderContainer c) =>
      c.read(routerProvider).routerDelegate.currentConfiguration.uri.path;

  /// The coupling this whole group exists for.
  ///
  /// The buttons link to `releases/latest/download/<asset>`, which is what
  /// lets one deploy of the site keep working across every future
  /// release - but it means the artifact names in the workflow are a
  /// contract with the Dart here. Rename one in `release.yml` and nothing
  /// fails until a member taps a button and gets a 404 from GitHub.
  group('the release workflow and the download buttons agree', () {
    final workflow = File('.github/workflows/release.yml').readAsStringSync();

    /// Names the workflow actually packages, e.g. `dist/foo.apk`.
    Set<String> packagedAssets() => RegExp(r'dist/([A-Za-z0-9._-]+\.(?:apk|zip|tar\.gz))')
        .allMatches(workflow)
        .map((m) => m.group(1)!)
        .toSet();

    /// Names the build matrix declares and uploads under.
    Set<String> matrixAssets() => RegExp(r'^\s*-?\s*asset:\s*(\S+)\s*$', multiLine: true)
        .allMatches(workflow)
        .map((m) => m.group(1)!)
        .toSet();

    test('every button links to an artifact the workflow produces', () {
      expect(appBuilds.map((b) => b.asset).toSet(), packagedAssets());
    });

    test('the matrix and the packaging steps use the same names', () {
      expect(matrixAssets(), packagedAssets());
    });

    test('there is a build for each of the four platforms asked for', () {
      expect(
        appBuilds.map((b) => b.platform).toSet(),
        {
          TargetPlatform.macOS,
          TargetPlatform.windows,
          TargetPlatform.linux,
          TargetPlatform.android,
        },
      );
    });

    test('the workflow publishes on a version tag', () {
      expect(workflow, contains("tags:"));
      expect(workflow, contains("'v*'"));
    });
  });

  group('download URLs', () {
    test('point at the latest release of the configured repo', () {
      const build = AppDownload(
        platform: TargetPlatform.linux,
        label: 'Linux',
        asset: 'app.tar.gz',
        fileHint: '',
        install: '',
        warning: '',
      );
      expect(
        build.urlFor('a-church/their-app'),
        'https://github.com/a-church/their-app/releases/latest/download/app.tar.gz',
      );
    });

    test('survive an admin pasting a slug with stray slashes', () {
      const build = AppDownload(
        platform: TargetPlatform.linux,
        label: 'Linux',
        asset: 'app.tar.gz',
        fileHint: '',
        install: '',
        warning: '',
      );
      expect(build.urlFor('  /a-church/their-app/  '), build.urlFor('a-church/their-app'));
    });
  });

  group('platform detection', () {
    test('finds the build for the platform it is given', () {
      expect(buildForCurrentPlatform(TargetPlatform.macOS)?.label, 'macOS');
      expect(buildForCurrentPlatform(TargetPlatform.android)?.label, 'Android');
    });

    test('has nothing to offer an iPhone, and says why elsewhere', () {
      // Apple has no sideloading: a download button could not work. The
      // page shows [iosExplanation] instead of a dead button.
      expect(buildForCurrentPlatform(TargetPlatform.iOS), isNull);
      expect(iosExplanation, contains('App Store'));
    });
  });

  group('the page', () {
    testWidgets('offers every platform, with the visitor\'s own first', (tester) async {
      // Cleared inside the test body, not in a tearDown: the binding
      // asserts every foundation debug var is unset the moment the body
      // returns, which is before tearDowns run.
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
      try {
        final container = await pumpApp(tester, testSettings());
        container.read(routerProvider).go('/download');
        await tester.pumpAndSettle();

        expect(find.text('Recommended for you'), findsOneWidget);
        for (final build in appBuilds) {
          expect(
            find.text('Download for ${build.label}'),
            findsOneWidget,
            reason: '${build.label} should still be reachable from any platform',
          );
        }
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });

    testWidgets('warns about the unsigned build before the download, not after', (tester) async {
      final container = await pumpApp(tester, testSettings());
      container.read(routerProvider).go('/download');
      await tester.pumpAndSettle();

      // A member who meets "the developer cannot be verified" with no
      // warning concludes the church sent them malware.
      expect(find.textContaining('cannot be opened because the developer'), findsOneWidget);
      expect(find.textContaining('Windows protected your PC'), findsOneWidget);
      expect(find.textContaining('install apps from this source'), findsOneWidget);
    });

    testWidgets('says the Linux build cannot sign in', (tester) async {
      // No Firebase plugin supports Linux desktop, so that build runs on
      // bundled content. Better said here than discovered.
      final container = await pumpApp(tester, testSettings());
      container.read(routerProvider).go('/download');
      await tester.pumpAndSettle();

      expect(find.textContaining('no Firebase support exists for Linux'), findsOneWidget);
    });
  });

  group('when there is nothing to download', () {
    testWidgets('a church with no releases repo cannot reach the page', (tester) async {
      final container = await pumpApp(tester, testSettings(releasesRepo: ''));
      container.read(routerProvider).go('/download');
      await tester.pumpAndSettle();

      expect(pathOf(container), '/');
    });

    testWidgets('and gets no footer link either', (tester) async {
      await pumpApp(tester, testSettings(releasesRepo: ''));
      expect(find.text('Get the app for your phone or computer'), findsNothing);
    });

    testWidgets('a configured church gets the footer link', (tester) async {
      await pumpApp(tester, testSettings(releasesRepo: 'a/b'));
      expect(find.text('Get the app for your phone or computer'), findsOneWidget);
    });

    test('the links appear once a repo is configured', () {
      expect(hasAppDownloads(testSettings(releasesRepo: 'a/b')), isTrue);
      expect(hasAppDownloads(testSettings(releasesRepo: '')), isFalse);
      expect(hasAppDownloads(testSettings(releasesRepo: '   ')), isFalse);
    });

    test('turning the feature off hides them even with a repo set', () {
      final off = testSettings(
        releasesRepo: 'a/b',
        features: const FeatureFlags(appDownloads: false),
      );
      expect(hasAppDownloads(off), isFalse);
    });

    test('the download page stays out of the top-level nav', () {
      // The bar is already at capacity - a church running every feature
      // has eight links, and a ninth pushes Sermons out of the scroller's
      // viewport on a 1366px laptop. These links live in the footer and
      // the mobile menu instead.
      expect(
        primaryNav(testSettings(releasesRepo: 'a/b')).map((d) => d.path),
        isNot(contains('/download')),
      );
    });
  });
}
