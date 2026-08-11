import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yoked_church_app/core/config/tenant.dart';
import 'package:yoked_church_app/app/app.dart';
import 'package:yoked_church_app/app/router.dart';
import 'package:yoked_church_app/core/config/church_settings.dart';
import 'package:yoked_church_app/core/config/settings_providers.dart';
import 'package:yoked_church_app/core/config/settings_repository.dart';
import 'package:yoked_church_app/core/widgets/app_shell.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:yoked_church_app/features/downloads/application/release_providers.dart';
import 'package:yoked_church_app/features/downloads/domain/app_download.dart';
import 'package:yoked_church_app/features/downloads/domain/release_check.dart';

import '../fakes/fake_repositories.dart';

void main() {
  Future<ProviderContainer> pumpApp(
    WidgetTester tester,
    ChurchSettings settings, {
    ReleaseCheck release = ReleaseCheck.unknown,
  }) async {
    tester.view.physicalSize = const Size(1400, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final container = ProviderContainer(
      overrides: fakeOverrides(settings: settings, release: release),
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const YokedChurchApp()),
    );
    await tester.pumpAndSettle();
    return container;
  }

  String pathOf(ProviderContainer c) =>
      subPathOf(c.read(routerProvider).routerDelegate.currentConfiguration.uri.path);

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

  /// The buttons link to `releases/latest/download/<asset>`, so a
  /// repository with no release at all - a fresh fork of this template,
  /// or a church that filled its releases repo in before publishing -
  /// shows four confident buttons that every one of them 404s, and a
  /// member cannot tell that from the app being broken.
  group('asking whether there is anything to download', () {
    /// A stand-in for GitHub that answers however the test needs.
    http.Client answering(int status, String body) =>
        MockClient((_) async => http.Response(body, status));

    String releaseJson({String tag = 'v1.0.0', List<String> assets = const ['a.zip']}) =>
        jsonEncode({
          'tag_name': tag,
          'assets': [for (final name in assets) {'name': name, 'size': 1},],
        });

    test('a repository with no release says so', () async {
      final check = await fetchReleaseCheck(answering(404, '{"message":"Not Found"}'), 'a/b');
      expect(check.state, ReleaseState.none);
    });

    test('a published release is read down to its asset names', () async {
      final check = await fetchReleaseCheck(
        answering(200, releaseJson(tag: 'v2.1.0', assets: ['x.apk', 'y.zip'])),
        'a/b',
      );

      expect(check.state, ReleaseState.published);
      expect(check.tag, 'v2.1.0');
      expect(check.assets, {'x.apk', 'y.zip'});
    });

    test('it asks GitHub for exactly the configured repository', () async {
      late Uri asked;
      final client = MockClient((request) async {
        asked = request.url;
        return http.Response(releaseJson(), 200);
      });

      // Stray slashes because an admin pasting from a browser bar will
      // include them, the same tolerance urlFor already has.
      await fetchReleaseCheck(client, '  /a-church/their-app/ ');
      expect(asked, Uri.parse('https://api.github.com/repos/a-church/their-app/releases/latest'));
    });

    /// The asymmetry that is the whole design of this: everything except
    /// a confident "there is nothing there" keeps the buttons. A working
    /// download hidden behind a check that failed is worse than the dead
    /// button the check exists to prevent.
    group('and degrading towards showing the buttons', () {
      test('a rate limit does not hide a release that exists', () async {
        final check = await fetchReleaseCheck(
          answering(403, '{"message":"API rate limit exceeded"}'),
          'a/b',
        );

        expect(check.state, ReleaseState.unknown);
        expect(check.offers('anything.zip'), isTrue);
      });

      test('so does a server error, and so does being offline', () async {
        expect((await fetchReleaseCheck(answering(500, ''), 'a/b')).state, ReleaseState.unknown);

        final broken = MockClient((_) async => throw const SocketException('no route to host'));
        expect((await fetchReleaseCheck(broken, 'a/b')).state, ReleaseState.unknown);
      });

      test('a slow answer is abandoned rather than waited on', () {
        // The check only ever removes buttons, so somebody on a bad
        // connection should get the download page, not a spinner. A
        // timeout lands in the same catch as any other failure, so what
        // is worth pinning here is that the wait is short.
        expect(releaseCheckTimeout, lessThanOrEqualTo(const Duration(seconds: 10)));
      });

      test('a body we cannot parse is not read as an empty repository', () async {
        expect(
          (await fetchReleaseCheck(answering(200, '<html>proxy sign-in</html>'), 'a/b')).state,
          ReleaseState.unknown,
        );
        expect(ReleaseCheck.fromResponseBody('[]').state, ReleaseState.unknown);
      });

      test('a release with nothing attached is a shape we misread, not a fact', () async {
        // Publishing a release with no assets is possible but vanishingly
        // rare; misreading the JSON is the likelier explanation, and only
        // one of the two guesses hides working downloads.
        final check = await fetchReleaseCheck(answering(200, releaseJson(assets: [])), 'a/b');
        expect(check.state, ReleaseState.unknown);
      });

      test('no repository configured is not a claim either way', () async {
        // /download is unreachable without one, so there is nothing to
        // say - and nothing to ask GitHub about.
        final check = await fetchReleaseCheck(
          MockClient((_) async => fail('should not have asked GitHub anything')),
          '   ',
        );
        expect(check.state, ReleaseState.unknown);
      });
    });

    test('offers a build only when it is known to be missing', () {
      final published = ReleaseCheck.fromResponseBody(releaseJson(assets: ['there.zip']));

      expect(published.offers('there.zip'), isTrue);
      expect(published.offers('missing.zip'), isFalse);
      expect(ReleaseCheck.none.offers('there.zip'), isFalse);
      expect(ReleaseCheck.unknown.offers('anything.zip'), isTrue);
    });
  });

  group('the download page with nothing published', () {
    testWidgets('says so instead of showing four buttons that 404', (tester) async {
      final container = await pumpApp(
        tester,
        testSettings(releasesRepo: 'a/b'),
        release: ReleaseCheck.none,
      );
      container.read(routerProvider).go('/download');
      await tester.pumpAndSettle();

      expect(find.textContaining('no installable build published yet'), findsOneWidget);
      for (final build in appBuilds) {
        expect(
          find.text('Download for ${build.label}'),
          findsNothing,
          reason: 'every one of these would 404',
        );
      }
    });

    testWidgets('tells whoever runs the site the one thing that fixes it', (tester) async {
      // The person most likely to meet this screen is not a member: it is
      // whoever forked the template and has not tagged a version yet.
      final container = await pumpApp(
        tester,
        testSettings(releasesRepo: 'a-church/their-app'),
        release: ReleaseCheck.none,
      );
      container.read(routerProvider).go('/download');
      await tester.pumpAndSettle();

      expect(find.textContaining('a-church/their-app'), findsOneWidget);
      expect(find.textContaining('tagged'), findsOneWidget);
    });

    testWidgets('still points at the website, which does work', (tester) async {
      final container = await pumpApp(
        tester,
        testSettings(releasesRepo: 'a/b'),
        release: ReleaseCheck.none,
      );
      container.read(routerProvider).go('/download');
      await tester.pumpAndSettle();

      expect(find.textContaining('The website works everywhere'), findsOneWidget);
    });

    testWidgets('a platform missing from a real release is disabled, not dead', (tester) async {
      // One platform failing in CI while the other three publish. The
      // button would 404 for exactly the people who own that platform,
      // and they have no way to tell that from the app being broken.
      final withoutAndroid = ReleaseCheck.fromResponseBody(
        jsonEncode({
          'tag_name': 'v1.0.0',
          'assets': [
            for (final build in appBuilds)
              if (build.platform != TargetPlatform.android) {'name': build.asset},
          ],
        }),
      );

      final container = await pumpApp(
        tester,
        testSettings(releasesRepo: 'a/b'),
        release: withoutAndroid,
      );
      container.read(routerProvider).go('/download');
      await tester.pumpAndSettle();

      expect(find.text('Download for Android'), findsNothing);
      expect(find.text('Android not in this release'), findsOneWidget);
      expect(find.text('Download for Windows'), findsOneWidget);
      expect(find.text('Download for macOS'), findsOneWidget);
    });

    /// A link to `/download` sent to somebody who does not have the site
    /// open yet - which is every link to it that is worth sending.
    ///
    /// The guard reads the church's settings to decide whether this page
    /// exists, and those settings arrive over a stream. Answering before
    /// the first emission means answering against
    /// [ChurchSettings.fallback], which names no releases repository - so
    /// the page closed, and "install the app: <link>" landed on the
    /// church home with nothing said.
    group('opened cold, before the church settings have arrived', () {
      Future<ProviderContainer> pumpColdAt(
        WidgetTester tester,
        String location,
        ChurchSettings settings,
      ) async {
        tester.view.physicalSize = const Size(1400, 3000);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final container = ProviderContainer(
          overrides: [
            ...fakeOverrides(settings: settings),
            settingsRepositoryProvider.overrideWithValue(_SettingsThatTakeAMoment(settings)),
          ],
        );
        addTearDown(container.dispose);

        // Before the first pump, which is as close as a widget test gets
        // to opening the app *at* an address rather than walking to it.
        container.read(routerProvider).go(location);

        await tester.pumpWidget(
          UncontrolledProviderScope(container: container, child: const YokedChurchApp()),
        );
        await tester.pumpAndSettle();
        return container;
      }

      testWidgets('the link still opens the download page', (tester) async {
        final container = await pumpColdAt(
          tester,
          churchPath(demoChurchId, '/download'),
          testSettings(releasesRepo: 'a/b'),
        );

        expect(pathOf(container), '/download');
        expect(find.text('Download for Windows'), findsOneWidget);
      });

      testWidgets('a church that has switched the page off still closes it', (tester) async {
        // The other half of waiting: nothing gated may stay open on the
        // strength of an answer given before the settings existed.
        final container = await pumpColdAt(
          tester,
          churchPath(demoChurchId, '/download'),
          testSettings(
            releasesRepo: 'a/b',
            features: const FeatureFlags(appDownloads: false),
          ),
        );

        expect(pathOf(container), '/');
      });

      testWidgets('and so does a church with no releases repository', (tester) async {
        final container = await pumpColdAt(
          tester,
          churchPath(demoChurchId, '/download'),
          testSettings(releasesRepo: ''),
        );

        expect(pathOf(container), '/');
      });
    });

    testWidgets('a check that failed changes nothing on the page', (tester) async {
      final container = await pumpApp(
        tester,
        testSettings(releasesRepo: 'a/b'),
        release: ReleaseCheck.unknown,
      );
      container.read(routerProvider).go('/download');
      await tester.pumpAndSettle();

      for (final build in appBuilds) {
        expect(find.text('Download for ${build.label}'), findsOneWidget);
      }
      expect(find.textContaining('no installable build published yet'), findsNothing);
    });
  });
}

/// Settings that arrive a beat after the app starts, like a real church's
/// do.
///
/// The default fake answers from a `Stream.value`, which is close enough
/// to instant that a guard reading settings too early looks correct. This
/// one puts a real gap where the network is.
class _SettingsThatTakeAMoment implements SettingsRepository {
  final ChurchSettings settings;

  _SettingsThatTakeAMoment(this.settings);

  @override
  Future<ChurchSettings> fetch() async => settings;

  @override
  Stream<ChurchSettings> watch() => Stream.fromFuture(
        Future.delayed(const Duration(milliseconds: 50), () => settings),
      );

  @override
  Future<void> save(ChurchSettings value) async {}
}
