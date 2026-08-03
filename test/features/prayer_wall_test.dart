import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yoked_church_app/app/app.dart';
import 'package:yoked_church_app/app/router.dart';
import 'package:yoked_church_app/core/config/church_settings.dart';
import 'package:yoked_church_app/features/auth/domain/app_user.dart';
import 'package:yoked_church_app/features/prayer_wall/application/prayer_providers.dart';
import 'package:yoked_church_app/features/prayer_wall/domain/prayer_post.dart';

import '../fakes/fake_repositories.dart';

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

  Future<List<PrayerPost>> wallOf(ProviderContainer c) async {
    await c.read(allPrayerPostsProvider.future);
    return c.read(prayerWallProvider).valueOrNull ?? const <PrayerPost>[];
  }

  /// The counts provider derives from the wall, which derives from the
  /// posts fetch - so the source has to have resolved first.
  Future<Map<String, int>> countsOf(ProviderContainer c) async {
    await c.read(allPrayerPostsProvider.future);
    return c.read(prayerCountsProvider.future);
  }

  PrayerPost post({
    String id = 'p1',
    String uid = 'u1',
    String authorName = 'Hannah Brooks',
    String body = 'Please pray for my family.',
    bool anonymous = false,
    PrayerStatus status = PrayerStatus.approved,
  }) =>
      PrayerPost(
        id: id,
        uid: uid,
        authorName: authorName,
        body: body,
        anonymous: anonymous,
        status: status,
        createdAt: DateTime(2026, 7, 20),
      );

  group('moderation', () {
    testWidgets('a submitted request starts pending and is not on the wall', (tester) async {
      final container = await pumpApp(tester, fakeOverrides(signedInAs: testMember(uid: 'u1')));

      await container.read(prayerControllerProvider).submit(body: 'Pray for me', anonymous: false);
      await tester.pumpAndSettle();

      expect(await wallOf(container), isEmpty);
      final all = await container.read(prayerPostRepositoryProvider).fetchAll();
      expect(all.single.status, PrayerStatus.pending);
    });

    testWidgets('approval is what puts it in front of the congregation', (tester) async {
      final container = await pumpApp(
        tester,
        fakeOverrides(
          signedInAs: testMember(uid: 'pastor', displayName: 'Sarah Lee', role: UserRole.staff),
          prayerPosts: [post(status: PrayerStatus.pending)],
        ),
      );

      expect(await wallOf(container), isEmpty);

      final pending = (await container.read(prayerPostRepositoryProvider).fetchById('p1'))!;
      await container.read(prayerControllerProvider).approve(pending);
      await tester.pumpAndSettle();

      final wall = await wallOf(container);
      expect(wall.single.id, 'p1');
      // Recorded so the queue shows who handled it without an audit lookup.
      expect(wall.single.moderatedBy, 'Sarah Lee');
    });

    testWidgets('taking a post down removes it from the wall again', (tester) async {
      final container = await pumpApp(
        tester,
        fakeOverrides(
          signedInAs: testMember(uid: 'pastor', role: UserRole.staff),
          prayerPosts: [post()],
        ),
      );
      expect(await wallOf(container), hasLength(1));

      final live = (await container.read(prayerPostRepositoryProvider).fetchById('p1'))!;
      await container.read(prayerControllerProvider).remove(live);
      await tester.pumpAndSettle();

      expect(await wallOf(container), isEmpty);
    });

    testWidgets('an empty request is not submitted at all', (tester) async {
      final container = await pumpApp(tester, fakeOverrides(signedInAs: testMember(uid: 'u1')));

      await container.read(prayerControllerProvider).submit(body: '   ', anonymous: false);
      await tester.pumpAndSettle();

      expect(await container.read(prayerPostRepositoryProvider).fetchAll(), isEmpty);
    });

    testWidgets('a signed-out visitor cannot submit', (tester) async {
      final container = await pumpApp(tester, fakeOverrides());

      await container.read(prayerControllerProvider).submit(body: 'Pray', anonymous: false);
      await tester.pumpAndSettle();

      expect(await container.read(prayerPostRepositoryProvider).fetchAll(), isEmpty);
    });

    testWidgets('the pending count drives the admin overview', (tester) async {
      final container = await pumpApp(
        tester,
        fakeOverrides(
          signedInAs: testMember(uid: 'pastor', role: UserRole.staff),
          prayerPosts: [
            post(id: 'a', status: PrayerStatus.pending),
            post(id: 'b', status: PrayerStatus.pending),
            post(id: 'c', status: PrayerStatus.approved),
            post(id: 'd', status: PrayerStatus.removed),
          ],
        ),
      );
      await container.read(allPrayerPostsProvider.future);

      expect(container.read(pendingPrayerCountProvider), 2);
    });
  });

  group('anonymity', () {
    test('an anonymous post never stores the name in the first place', () {
      final anonymous = post(anonymous: true, authorName: 'Hannah Brooks');
      // Storing it and hiding it in the UI would leave it one query away.
      expect(anonymous.toMap()['authorName'], '');
      expect(anonymous.displayName, 'Anonymous');
    });

    testWidgets('submitting anonymously does not persist the display name', (tester) async {
      final container = await pumpApp(
        tester,
        fakeOverrides(signedInAs: testMember(uid: 'u1', displayName: 'Hannah Brooks')),
      );

      await container.read(prayerControllerProvider).submit(body: 'Quietly', anonymous: true);
      await tester.pumpAndSettle();

      final stored = (await container.read(prayerPostRepositoryProvider).fetchAll()).single;
      expect(stored.authorName, isEmpty);
      expect(stored.displayName, 'Anonymous');
      // The uid is still there, so staff can follow up pastorally.
      expect(stored.uid, 'u1');
    });

    test('a named post shows its author', () {
      expect(post(anonymous: false, authorName: 'Dev Patel').displayName, 'Dev Patel');
    });

    test('a named post with no name falls back rather than showing blank', () {
      expect(post(anonymous: false, authorName: '').displayName, 'Anonymous');
    });
  });

  group('praying for a request', () {
    testWidgets('a second tap does not double-count', (tester) async {
      final container = await pumpApp(
        tester,
        fakeOverrides(signedInAs: testMember(uid: 'u1'), prayerPosts: [post()]),
      );
      final controller = container.read(prayerControllerProvider);

      await controller.togglePrayed('p1');
      await tester.pumpAndSettle();
      expect((await countsOf(container))['p1'], 1);

      // Toggling off, then on again, still lands on one record.
      await controller.togglePrayed('p1');
      await tester.pumpAndSettle();
      expect((await countsOf(container))['p1'], 0);

      await controller.togglePrayed('p1');
      await tester.pumpAndSettle();
      expect((await countsOf(container))['p1'], 1);
      expect(await container.read(intercessionRepositoryProvider).fetchAll(), hasLength(1));
    });

    testWidgets('two members each count once', (tester) async {
      final container = await pumpApp(
        tester,
        fakeOverrides(
          signedInAs: testMember(uid: 'u1'),
          prayerPosts: [post()],
          intercessions: [
            PrayerIntercession(
              id: intercessionId('p1', 'u2'),
              postId: 'p1',
              uid: 'u2',
              prayedAt: DateTime(2026),
            ),
          ],
        ),
      );

      await container.read(prayerControllerProvider).togglePrayed('p1');
      await tester.pumpAndSettle();

      expect((await countsOf(container))['p1'], 2);
    });

    testWidgets('the button reflects whether this member already prayed', (tester) async {
      final container = await pumpApp(
        tester,
        fakeOverrides(
          signedInAs: testMember(uid: 'u1'),
          prayerPosts: [post(id: 'a'), post(id: 'b')],
          intercessions: [
            PrayerIntercession(
              id: intercessionId('a', 'u1'),
              postId: 'a',
              uid: 'u1',
              prayedAt: DateTime(2026),
            ),
          ],
        ),
      );

      expect(await container.read(myIntercessionsProvider.future), {'a'});
    });

    testWidgets('a signed-out visitor cannot pray for a post', (tester) async {
      final container = await pumpApp(tester, fakeOverrides(prayerPosts: [post()]));

      await container.read(prayerControllerProvider).togglePrayed('p1');
      await tester.pumpAndSettle();

      expect(await container.read(intercessionRepositoryProvider).fetchAll(), isEmpty);
    });
  });

  group('an author seeing their own request', () {
    testWidgets('sees it waiting rather than silently gone', (tester) async {
      final container = await pumpApp(
        tester,
        fakeOverrides(
          signedInAs: testMember(uid: 'u1'),
          prayerPosts: [
            post(id: 'mine', uid: 'u1', status: PrayerStatus.pending),
            post(id: 'theirs', uid: 'u2', status: PrayerStatus.pending),
          ],
        ),
      );
      await container.read(allPrayerPostsProvider.future);

      final mine = container.read(myPrayerPostsProvider);
      expect(mine.map((p) => p.id), ['mine']);
    });

    testWidgets('an approved post drops off the pending list and onto the wall', (tester) async {
      final container = await pumpApp(
        tester,
        fakeOverrides(
          signedInAs: testMember(uid: 'u1'),
          prayerPosts: [post(id: 'mine', uid: 'u1', status: PrayerStatus.approved)],
        ),
      );
      await container.read(allPrayerPostsProvider.future);

      expect(container.read(myPrayerPostsProvider), isEmpty);
      expect((await wallOf(container)).map((p) => p.id), ['mine']);
    });

    testWidgets('the wall page renders the request form and the approved posts', (tester) async {
      final container = await pumpApp(
        tester,
        fakeOverrides(
          signedInAs: testMember(uid: 'u1'),
          prayerPosts: [post(body: 'Please pray for my family.')],
        ),
      );
      container.read(routerProvider).go('/account/prayer');
      await tester.pumpAndSettle();

      expect(find.text('Ask for prayer'), findsOneWidget);
      expect(find.text('Please pray for my family.'), findsOneWidget);
      expect(find.textContaining('nothing reaches the wall unreviewed'), findsOneWidget);
    });
  });

  group('feature flag', () {
    testWidgets('turning it off closes both routes and hides both tabs', (tester) async {
      final container = await pumpApp(
        tester,
        fakeOverrides(
          settings: testSettings(features: const FeatureFlags(prayerWall: false)),
          signedInAs: testMember(uid: 'a1', role: UserRole.admin),
        ),
      );

      container.read(routerProvider).go('/account/prayer');
      await tester.pumpAndSettle();
      expect(pathOf(container), '/');

      container.read(routerProvider).go('/admin/prayer');
      await tester.pumpAndSettle();
      expect(pathOf(container), '/');

      container.read(routerProvider).go('/admin');
      await tester.pumpAndSettle();
      expect(find.text('Prayer'), findsNothing);
      expect(find.text('Prayer requests'), findsNothing);
    });
  });
}
