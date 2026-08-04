import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yoked_church_app/app/app.dart';
import 'package:yoked_church_app/app/router.dart';
import 'package:yoked_church_app/core/config/church_settings.dart';
import 'package:yoked_church_app/core/config/settings_providers.dart';
import 'package:yoked_church_app/core/config/tenant.dart';
import 'package:yoked_church_app/features/auth/domain/app_user.dart';
import 'package:yoked_church_app/features/live/domain/live_status.dart';

import '../fakes/fake_repositories.dart';

/// The home page used to offer "Watch Live" whenever a stream URL was
/// configured, which is to say every day of the week. These fix the
/// difference between a link to where a church streams and a claim that
/// something is happening now.
void main() {
  Future<ProviderContainer> pumpHome(
    WidgetTester tester, {
    LiveStatus live = const LiveStatus(),
    ChurchSettings? settings,
  }) async {
    tester.view.physicalSize = const Size(1400, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final container = ProviderContainer(overrides: fakeOverrides(live: live, settings: settings));
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const YokedChurchApp()),
    );
    await tester.pumpAndSettle();
    return container;
  }

  ChurchSettings withStream(String url) => testSettings(
        social: SocialLinks(
          facebook: '',
          instagram: '',
          youtube: '',
          givingUrl: '',
          liveStreamUrl: url,
        ),
      );

  group('the home page', () {
    testWidgets('says nothing about being live when nobody is', (tester) async {
      await pumpHome(tester, settings: withStream('https://example.org/live'));

      expect(find.text('LIVE NOW'), findsNothing);
      expect(
        find.text('Watch Online'),
        findsOneWidget,
        reason: 'the link to where they stream is still useful; the claim is what was wrong',
      );
      expect(find.text('Watch Live'), findsNothing);
    });

    testWidgets('raises a banner while a stream is running', (tester) async {
      await pumpHome(
        tester,
        live: const LiveStatus(live: true, videoId: 'abc123', title: 'Sunday Morning'),
      );

      expect(find.text('LIVE NOW'), findsOneWidget);
      expect(find.text('Sunday Morning'), findsOneWidget);
    });

    testWidgets('stays quiet when the poller has nowhere to send anyone', (tester) async {
      // `live: true` with no video id is a half-written document. Linking
      // to youtube.com/watch?v= would be worse than saying nothing.
      await pumpHome(tester, live: const LiveStatus(live: true));

      expect(find.text('LIVE NOW'), findsNothing);
    });

    testWidgets('a church with no stream link at all gets neither', (tester) async {
      await pumpHome(tester, settings: withStream(''));

      expect(find.text('Watch Online'), findsNothing);
      expect(find.text('LIVE NOW'), findsNothing);
    });
  });

  group('the sermons page', () {
    testWidgets('offers a link to watch, not a claim that something is on', (tester) async {
      final container = ProviderContainer(
        overrides: fakeOverrides(settings: withStream('https://example.org/live')),
      );
      addTearDown(container.dispose);

      tester.view.physicalSize = const Size(1400, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        UncontrolledProviderScope(container: container, child: const YokedChurchApp()),
      );
      await tester.pumpAndSettle();
      container.read(routerProvider).go(churchPath(demoChurchId, '/sermons'));
      await tester.pumpAndSettle();

      expect(find.text('Watch Online'), findsOneWidget);
      expect(find.text('Watch Live'), findsNothing);
    });
  });

  group('the live document', () {
    test('is read whether the time came from Firestore or a JSON string', () {
      final fromJson = LiveStatus.fromMap(const {
        'live': true,
        'videoId': 'abc123',
        'title': 'Sunday Morning',
        'startedAt': '2026-08-02T14:00:00.000Z',
        'checkedAt': '2026-08-02T14:05:00.000Z',
      });

      expect(fromJson.live, isTrue);
      expect(fromJson.startedAt, DateTime.utc(2026, 8, 2, 14));
      expect(fromJson.watchUrl, 'https://www.youtube.com/watch?v=abc123');
    });

    test('an empty document is simply not live', () {
      final empty = LiveStatus.fromMap(const {});

      expect(empty.live, isFalse);
      expect(empty.isWatchable, isFalse);
      expect(empty.watchUrl, isEmpty, reason: 'never link to a video that does not exist');
      expect(empty.checkedAt, isNull, reason: 'null is how the settings page knows nothing has run');
    });

    test('a nonsense timestamp is dropped rather than crashing the page', () {
      final odd = LiveStatus.fromMap(const {'live': true, 'checkedAt': 'not a date'});
      expect(odd.checkedAt, isNull);
    });
  });

  group('the channel setting', () {
    testWidgets('an admin can save a channel id', (tester) async {
      tester.view.physicalSize = const Size(1400, 4000);
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
      container.read(routerProvider).go('/admin/settings');
      await tester.pumpAndSettle();

      final field = find.widgetWithText(TextField, 'YouTube channel ID');
      await tester.ensureVisible(field);
      await tester.pumpAndSettle();
      await tester.enterText(field, 'UC_test_channel');

      final save = find.widgetWithText(ElevatedButton, 'Save Settings');
      await tester.ensureVisible(save);
      await tester.pumpAndSettle();
      await tester.tap(save);
      await tester.pumpAndSettle();

      final saved = await container.read(settingsRepositoryProvider).fetch();
      expect(saved.social.youtubeChannelId, 'UC_test_channel');
    });

    test('survives a round trip through the document', () {
      const links = SocialLinks(
        facebook: '',
        instagram: '',
        youtube: '',
        givingUrl: '',
        liveStreamUrl: '',
        youtubeChannelId: 'UC_test_channel',
      );

      expect(SocialLinks.fromMap(links.toMap()).youtubeChannelId, 'UC_test_channel');
      expect(
        SocialLinks.fromMap(const {}).youtubeChannelId,
        isEmpty,
        reason: 'a church configured before this feature existed is simply not polled',
      );
    });
  });
}
