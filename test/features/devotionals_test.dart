import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yoked_church_app/app/app.dart';
import 'package:yoked_church_app/app/router.dart';
import 'package:yoked_church_app/core/config/church_settings.dart';
import 'package:yoked_church_app/features/auth/domain/app_user.dart';
import 'package:yoked_church_app/features/devotionals/application/devotional_providers.dart';
import 'package:yoked_church_app/features/devotionals/domain/devotional.dart';

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

  group('publishing', () {
    test('a draft is never live, whatever its date', () {
      final draft = testDevotional(published: false, publishDate: DateTime(2020));
      expect(draft.isLiveAt(DateTime(2026)), isFalse);
    });

    test('a published entry dated in the future is not live yet', () {
      final scheduled = testDevotional(publishDate: DateTime(2026, 8, 15));
      expect(scheduled.isLiveAt(DateTime(2026, 7, 28)), isFalse);
      expect(scheduled.isLiveAt(DateTime(2026, 8, 15)), isTrue);
      expect(scheduled.isLiveAt(DateTime(2026, 9, 1)), isTrue);
    });

    testWidgets('the public list shows only what is live', (tester) async {
      final container = await pumpApp(
        tester,
        fakeOverrides(
          devotionals: [
            testDevotional(id: 'live', title: 'Live One', publishDate: DateTime(2026, 7, 1)),
            testDevotional(id: 'draft', title: 'Draft One', published: false),
            testDevotional(id: 'later', title: 'Scheduled One', publishDate: DateTime(2099)),
          ],
        ),
      );
      container.read(routerProvider).go('/devotionals');
      await tester.pumpAndSettle();

      expect(find.text('Live One'), findsOneWidget);
      expect(find.text('Draft One'), findsNothing);
      expect(find.text('Scheduled One'), findsNothing);
    });

    testWidgets('a draft is not reachable by direct link either', (tester) async {
      final container = await pumpApp(
        tester,
        fakeOverrides(devotionals: [testDevotional(id: 'draft', title: 'Draft One', published: false)]),
      );
      container.read(routerProvider).go('/devotionals/draft');
      await tester.pumpAndSettle();

      expect(find.text('Draft One'), findsNothing);
      expect(find.text('Devotional not found.'), findsOneWidget);
    });
  });

  group('reading', () {
    testWidgets('the detail page renders the full body, not the excerpt', (tester) async {
      final long = ('word ' * 100).trim();
      final container = await pumpApp(
        tester,
        fakeOverrides(devotionals: [testDevotional(id: 'd1', title: 'Rest', body: long)]),
      );
      container.read(routerProvider).go('/devotionals/d1');
      await tester.pumpAndSettle();

      expect(find.text('Rest'), findsWidgets);
      expect(find.text(long), findsOneWidget);
    });

    test('the excerpt cuts on a word boundary and marks the elision', () {
      final devotional = testDevotional(body: 'alpha ' * 60);
      expect(devotional.excerpt.length, lessThanOrEqualTo(161));
      expect(devotional.excerpt, endsWith('…'));
      expect(devotional.excerpt, isNot(contains('alp…')));
    });

    testWidgets("the home page surfaces today's devotional", (tester) async {
      await pumpApp(
        tester,
        fakeOverrides(
          devotionals: [
            testDevotional(id: 'old', title: 'Older One', publishDate: DateTime(2026, 1, 1)),
            testDevotional(id: 'new', title: 'Newest One', publishDate: DateTime(2026, 7, 1)),
          ],
        ),
      );

      expect(find.text("TODAY'S DEVOTIONAL"), findsOneWidget);
      expect(find.text('Newest One'), findsOneWidget);
      expect(find.text('Older One'), findsNothing);
    });
  });

  group('feature flag', () {
    List<Override> withDevotionalsOff() => fakeOverrides(
          settings: testSettings(features: const FeatureFlags(devotionals: false)),
          devotionals: [testDevotional(title: 'Hidden One')],
        );

    testWidgets('turning it off removes the nav link and the home card', (tester) async {
      await pumpApp(tester, withDevotionalsOff());

      expect(find.text('Devotionals'), findsNothing);
      expect(find.text("TODAY'S DEVOTIONAL"), findsNothing);
    });

    testWidgets('turning it off closes the route to anyone with the URL', (tester) async {
      final container = await pumpApp(tester, withDevotionalsOff());

      container.read(routerProvider).go('/devotionals');
      await tester.pumpAndSettle();
      expect(pathOf(container), '/');

      container.read(routerProvider).go('/devotionals/d1');
      await tester.pumpAndSettle();
      expect(pathOf(container), '/');
    });

    testWidgets('turning it off removes the staff tab and its admin route', (tester) async {
      final container = await pumpApp(
        tester,
        fakeOverrides(
          settings: testSettings(features: const FeatureFlags(devotionals: false)),
          signedInAs: testMember(uid: 'a1', displayName: 'Ada Admin', role: UserRole.admin),
        ),
      );

      container.read(routerProvider).go('/admin');
      await tester.pumpAndSettle();
      expect(find.text('Devotionals'), findsNothing);

      container.read(routerProvider).go('/admin/devotionals');
      await tester.pumpAndSettle();
      expect(pathOf(container), '/');
    });
  });

  group('staff CMS', () {
    testWidgets('the staff list shows drafts and scheduled entries the public cannot see', (tester) async {
      final container = await pumpApp(
        tester,
        fakeOverrides(
          signedInAs: testMember(uid: 'a1', displayName: 'Ada Admin', role: UserRole.admin),
          devotionals: [
            testDevotional(id: 'live', title: 'Live One', publishDate: DateTime(2026, 7, 1)),
            testDevotional(id: 'draft', title: 'Draft One', published: false),
            testDevotional(id: 'later', title: 'Scheduled One', publishDate: DateTime(2099)),
          ],
        ),
      );
      container.read(routerProvider).go('/admin/devotionals');
      await tester.pumpAndSettle();

      expect(find.text('Live One'), findsOneWidget);
      expect(find.text('Draft One'), findsOneWidget);
      expect(find.text('Scheduled One'), findsOneWidget);

      // Scheduled is its own state - staff would otherwise read a
      // future-dated entry as already live.
      expect(find.text('Live'), findsOneWidget);
      expect(find.text('Draft'), findsOneWidget);
      expect(find.text('Scheduled'), findsOneWidget);
    });

    testWidgets('publishing a draft puts it on the public list', (tester) async {
      final container = await pumpApp(
        tester,
        fakeOverrides(
          devotionals: [
            testDevotional(id: 'draft', title: 'Draft One', published: false, publishDate: DateTime(2026, 7, 1)),
          ],
        ),
      );

      expect(container.read(publishedDevotionalsProvider).valueOrNull, isEmpty);

      final repo = container.read(devotionalRepositoryProvider);
      final draft = (await repo.fetchById('draft'))!;
      await repo.update(draft.copyWith(published: true));
      await tester.pumpAndSettle();

      expect(
        container.read(publishedDevotionalsProvider).valueOrNull?.map((d) => d.title),
        ['Draft One'],
      );
    });
  });

  group('search', () {
    testWidgets('narrows by title, scripture, author, and body', (tester) async {
      final container = await pumpApp(
        tester,
        fakeOverrides(
          devotionals: [
            testDevotional(id: '1', title: 'The Anchor', scripture: 'Hebrews 6:19', author: 'Sarah Lee', body: 'x'),
            testDevotional(id: '2', title: 'Small Things', scripture: 'Luke 16:10', author: 'John Miller', body: 'y'),
          ],
        ),
      );

      void search(String q) => container.read(devotionalSearchQueryProvider.notifier).state = q;
      List<String> titles() =>
          (container.read(filteredDevotionalsProvider).valueOrNull ?? const <Devotional>[])
              .map((d) => d.title)
              .toList();

      search('anchor');
      expect(titles(), ['The Anchor']);

      search('luke');
      expect(titles(), ['Small Things']);

      search('sarah');
      expect(titles(), ['The Anchor']);

      search('');
      expect(titles(), hasLength(2));
    });
  });
}
