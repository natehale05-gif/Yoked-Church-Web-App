import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yoked_church_app/core/config/tenant.dart';
import 'package:yoked_church_app/app/app.dart';
import 'package:yoked_church_app/app/router.dart';
import 'package:yoked_church_app/core/config/church_settings.dart';
import 'package:yoked_church_app/features/reading_plans/application/reading_plan_providers.dart';
import 'package:yoked_church_app/features/reading_plans/domain/reading_plan.dart';

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
      subPathOf(c.read(routerProvider).routerDelegate.currentConfiguration.uri.path);

  /// Awaits the in-flight fetch before reading the derived provider.
  /// `progressForPlanProvider` reads `myProgressProvider.valueOrNull`,
  /// which is null until that future first resolves.
  Future<PlanProgress?> progressOf(ProviderContainer c, String planId) async {
    await c.read(myProgressProvider.future);
    return c.read(progressForPlanProvider(planId));
  }

  group('progress arithmetic', () {
    test('completed days are stored as day numbers, not positions', () {
      final plan = testPlan(days: 3);
      final progress = PlanProgress(
        uid: 'u1',
        planId: 'p1',
        completedDays: const {2},
        startedAt: DateTime(2026),
        lastReadAt: DateTime(2026),
      );

      // Renumbering the plan must not silently re-point history: day 2
      // is day 2 whatever order the list is in.
      expect(progress.isDone(2), isTrue);
      expect(progress.isDone(1), isFalse);
      expect(progress.nextDay(plan)?.dayNumber, 1);
    });

    test('removing a day from the plan cannot push someone over 100%', () {
      final shortened = testPlan(days: 2);
      final progress = PlanProgress(
        uid: 'u1',
        planId: 'p1',
        // Day 3 was completed before staff deleted it from the plan.
        completedDays: const {1, 2, 3},
        startedAt: DateTime(2026),
        lastReadAt: DateTime(2026),
      );

      expect(progress.fractionOf(shortened), 1.0);
    });

    test('an empty plan reports zero rather than dividing by zero', () {
      final empty = ReadingPlan(id: 'p1', title: 'Empty');
      final progress = PlanProgress(
        uid: 'u1',
        planId: 'p1',
        startedAt: DateTime(2026),
        lastReadAt: DateTime(2026),
      );
      expect(progress.fractionOf(empty), 0);
      expect(progress.nextDay(empty), isNull);
    });

    test('a finished plan has no next day', () {
      final plan = testPlan(days: 2);
      final progress = PlanProgress(
        uid: 'u1',
        planId: 'p1',
        completedDays: const {1, 2},
        startedAt: DateTime(2026),
        lastReadAt: DateTime(2026),
      );
      expect(progress.nextDay(plan), isNull);
      expect(progress.fractionOf(plan), 1.0);
    });

    test('days round-trip through the map in numeric order', () {
      final plan = ReadingPlan.fromMap('p1', {
        'title': 'Out of order',
        'days': [
          {'dayNumber': 3, 'reference': 'C'},
          {'dayNumber': 1, 'reference': 'A'},
          {'dayNumber': 2, 'reference': 'B'},
        ],
      });
      expect(plan.days.map((d) => d.reference), ['A', 'B', 'C']);
    });
  });

  group('tracking', () {
    testWidgets('checking a day persists and survives a reread', (tester) async {
      final container = await pumpApp(
        tester,
        fakeOverrides(signedInAs: testMember(uid: 'u1'), readingPlans: [testPlan(days: 3)]),
      );

      await container.read(readingPlanControllerProvider).setDayComplete('p1', 1, true);
      await tester.pumpAndSettle();

      expect((await progressOf(container, 'p1'))?.completedDays, {1});

      final stored = await container.read(planProgressRepositoryProvider).forMember('u1');
      expect(stored.single.completedDays, {1});
      expect(stored.single.planId, 'p1');
    });

    testWidgets('unchecking a day removes it again', (tester) async {
      final container = await pumpApp(
        tester,
        fakeOverrides(signedInAs: testMember(uid: 'u1'), readingPlans: [testPlan(days: 3)]),
      );
      final controller = container.read(readingPlanControllerProvider);

      await controller.setDayComplete('p1', 1, true);
      await controller.setDayComplete('p1', 2, true);
      await tester.pumpAndSettle();
      expect((await progressOf(container, 'p1'))?.completedDays, {1, 2});

      await controller.setDayComplete('p1', 1, false);
      await tester.pumpAndSettle();
      expect((await progressOf(container, 'p1'))?.completedDays, {2});
    });

    testWidgets('starting a plan twice does not wipe existing progress', (tester) async {
      final container = await pumpApp(
        tester,
        fakeOverrides(signedInAs: testMember(uid: 'u1'), readingPlans: [testPlan(days: 3)]),
      );
      final controller = container.read(readingPlanControllerProvider);

      await controller.start('p1');
      await controller.setDayComplete('p1', 1, true);
      await controller.setDayComplete('p1', 2, true);
      await tester.pumpAndSettle();

      await controller.start('p1');
      await tester.pumpAndSettle();

      expect((await progressOf(container, 'p1'))?.completedDays, {1, 2});
      // And exactly one record, not two.
      expect(await container.read(planProgressRepositoryProvider).forMember('u1'), hasLength(1));
    });

    testWidgets('checking a day starts the plan implicitly', (tester) async {
      final container = await pumpApp(
        tester,
        fakeOverrides(signedInAs: testMember(uid: 'u1'), readingPlans: [testPlan(days: 3)]),
      );

      expect(await progressOf(container, 'p1'), isNull);

      await container.read(readingPlanControllerProvider).setDayComplete('p1', 2, true);
      await tester.pumpAndSettle();

      expect((await progressOf(container, 'p1'))?.completedDays, {2});
    });

    testWidgets('leaving a plan forgets the progress', (tester) async {
      final container = await pumpApp(
        tester,
        fakeOverrides(signedInAs: testMember(uid: 'u1'), readingPlans: [testPlan(days: 3)]),
      );
      final controller = container.read(readingPlanControllerProvider);

      await controller.setDayComplete('p1', 1, true);
      await tester.pumpAndSettle();
      expect(await progressOf(container, 'p1'), isNotNull);

      await controller.leave('p1');
      await tester.pumpAndSettle();

      expect(await progressOf(container, 'p1'), isNull);
      expect(await container.read(planProgressRepositoryProvider).forMember('u1'), isEmpty);
    });

    testWidgets('a signed-out visitor cannot record progress', (tester) async {
      final container = await pumpApp(tester, fakeOverrides(readingPlans: [testPlan(days: 3)]));

      await container.read(readingPlanControllerProvider).setDayComplete('p1', 1, true);
      await tester.pumpAndSettle();

      expect(await progressOf(container, 'p1'), isNull);
    });
  });

  group('privacy', () {
    testWidgets("one member's progress is not visible to another", (tester) async {
      final container = await pumpApp(
        tester,
        fakeOverrides(
          signedInAs: testMember(uid: 'u1'),
          readingPlans: [testPlan(days: 3)],
          planProgress: [
            PlanProgress(
              id: 'p1__u2',
              uid: 'u2',
              planId: 'p1',
              completedDays: const {1, 2, 3},
              startedAt: DateTime(2026),
              lastReadAt: DateTime(2026),
            ),
          ],
        ),
      );

      // u2 has finished the plan; u1 must see none of it.
      expect(await progressOf(container, 'p1'), isNull);
      expect(container.read(myProgressProvider).valueOrNull, isEmpty);
      expect(container.read(plansInProgressProvider), isEmpty);
    });
  });

  group('my reading', () {
    testWidgets('lists started plans, most recent activity first', (tester) async {
      final container = await pumpApp(
        tester,
        fakeOverrides(
          signedInAs: testMember(uid: 'u1'),
          readingPlans: [
            testPlan(id: 'a', title: 'Plan A', days: 3),
            testPlan(id: 'b', title: 'Plan B', days: 3),
            testPlan(id: 'c', title: 'Untouched', days: 3),
          ],
        ),
      );
      final controller = container.read(readingPlanControllerProvider);

      await controller.setDayComplete('a', 1, true);
      await controller.setDayComplete('b', 1, true);
      await tester.pumpAndSettle();

      // This provider joins two async sources; both must have resolved.
      await container.read(allReadingPlansProvider.future);
      await container.read(myProgressProvider.future);
      final rows = container.read(plansInProgressProvider);
      expect(rows.map((r) => r.plan.id), ['b', 'a'], reason: 'b was read most recently');
      expect(rows.map((r) => r.plan.id), isNot(contains('c')));
    });

    testWidgets('the account tab shows the next unread day', (tester) async {
      final container = await pumpApp(
        tester,
        fakeOverrides(signedInAs: testMember(uid: 'u1'), readingPlans: [testPlan(days: 3)]),
      );

      await container.read(readingPlanControllerProvider).setDayComplete('p1', 1, true);
      container.read(routerProvider).go('/account/reading');
      await tester.pumpAndSettle();

      expect(find.textContaining('Up next · Day 2'), findsOneWidget);
      expect(find.textContaining('1 of 3 days'), findsOneWidget);
    });

    testWidgets('a finished plan reads as complete rather than showing a next day', (tester) async {
      final container = await pumpApp(
        tester,
        fakeOverrides(signedInAs: testMember(uid: 'u1'), readingPlans: [testPlan(days: 2)]),
      );
      final controller = container.read(readingPlanControllerProvider);

      await controller.setDayComplete('p1', 1, true);
      await controller.setDayComplete('p1', 2, true);
      container.read(routerProvider).go('/account/reading');
      await tester.pumpAndSettle();

      expect(find.text('Plan complete'), findsOneWidget);
      expect(find.textContaining('Up next'), findsNothing);
    });
  });

  group('publishing and flags', () {
    testWidgets('a draft plan is hidden from members and from direct links', (tester) async {
      final container = await pumpApp(
        tester,
        fakeOverrides(readingPlans: [testPlan(id: 'd', title: 'Draft Plan', published: false)]),
      );

      container.read(routerProvider).go('/reading-plans');
      await tester.pumpAndSettle();
      expect(find.text('Draft Plan'), findsNothing);

      container.read(routerProvider).go('/reading-plans/d');
      await tester.pumpAndSettle();
      expect(find.text('Reading plan not found.'), findsOneWidget);
    });

    testWidgets('turning the flag off closes every reading route', (tester) async {
      final container = await pumpApp(
        tester,
        fakeOverrides(
          settings: testSettings(features: const FeatureFlags(readingPlans: false)),
          signedInAs: testMember(uid: 'u1'),
          readingPlans: [testPlan()],
        ),
      );

      for (final path in ['/reading-plans', '/reading-plans/p1', '/account/reading']) {
        container.read(routerProvider).go(path);
        await tester.pumpAndSettle();
        expect(pathOf(container), '/', reason: '$path should be closed');
      }
    });

    testWidgets('turning the flag off removes the account tab', (tester) async {
      final container = await pumpApp(
        tester,
        fakeOverrides(
          settings: testSettings(features: const FeatureFlags(readingPlans: false)),
          signedInAs: testMember(uid: 'u1'),
        ),
      );
      container.read(routerProvider).go('/account');
      await tester.pumpAndSettle();

      expect(find.text('Reading'), findsNothing);
    });
  });
}
