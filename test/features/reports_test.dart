import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yoked_church_app/app/app.dart';
import 'package:yoked_church_app/app/router.dart';
import 'package:yoked_church_app/core/config/church_settings.dart';
import 'package:yoked_church_app/core/config/settings_providers.dart';
import 'package:yoked_church_app/features/attendance/application/attendance_providers.dart';
import 'package:yoked_church_app/features/attendance/domain/attendance_record.dart';
import 'package:yoked_church_app/features/auth/application/auth_providers.dart';
import 'package:yoked_church_app/features/auth/domain/app_user.dart';
import 'package:yoked_church_app/features/giving/application/giving_providers.dart';
import 'package:yoked_church_app/features/giving/domain/giving_record.dart';
import 'package:yoked_church_app/features/groups/application/group_providers.dart';
import 'package:yoked_church_app/features/groups/domain/group.dart';
import 'package:yoked_church_app/features/reports/application/report_providers.dart';
import 'package:yoked_church_app/features/reports/domain/report_metrics.dart';

import '../fakes/fake_repositories.dart';

/// Reports are the easiest place in an app to ship a confident lie. These
/// tests are mostly about the cases where the honest answer is "we don't
/// know yet" rather than a number.
void main() {
  final now = DateTime(2026, 7, 29);

  ({DateTime at, double value}) point(int daysAgo, double value) =>
      (at: now.subtract(Duration(days: daysAgo)), value: value);

  Trend trendOfPoints(List<({DateTime at, double value})> points) => trendOver(
        points,
        dateOf: (p) => p.at,
        valueOf: (p) => p.value,
        now: now,
      );

  group('Trend', () {
    test('splits the last window from the one before it', () {
      final trend = trendOfPoints([
        point(10, 100),
        point(80, 50),
        point(100, 30), // previous window
        point(200, 999), // older than both - counted in neither
      ]);

      expect(trend.current, 150);
      expect(trend.previous, 30);
    });

    test('reports a rise and a fall in plain percentages', () {
      expect(const Trend(current: 110, previous: 100).changeLabel, '+10%');
      expect(const Trend(current: 90, previous: 100).changeLabel, '-10%');
      expect(const Trend(current: 100, previous: 100).changeLabel, 'level');
    });

    test('refuses to invent a change from a zero baseline', () {
      const first = Trend(current: 40, previous: 0);
      expect(first.hasBaseline, isFalse);
      expect(first.changeRatio, isNull);
      expect(first.changeLabel, isNull, reason: 'a first quarter has nothing to compare against');
    });

    test('a record exactly on the boundary is counted once, in the newer window', () {
      final trend = trendOfPoints([point(90, 7)]);
      expect(trend.current, 7);
      expect(trend.previous, 0);
    });

    test('counts records rather than values when no value is given', () {
      final trend = trendOver(
        [point(1, 999), point(2, 999)],
        dateOf: (p) => p.at,
        now: now,
      );
      expect(trend.current, 2);
    });
  });

  group('Participation', () {
    test('an empty congregation has no percentage, not zero per cent', () {
      const none = Participation(engaged: 0, total: 0);
      expect(none.ratio, isNull);
      expect(none.percentLabel, isNull);
      expect(none.label, '—');
    });

    test('rounds to something a church would say out loud', () {
      const p = Participation(engaged: 41, total: 120);
      expect(p.percentLabel, '34%');
      expect(p.label, '41 of 120');
    });
  });

  group('the reports page', () {
    // `settingsProvider` falls back to defaults until the stream's first
    // emission, so a test that never awaits it silently reports every
    // flag as on.
    Future<ProviderContainer> containerWith(List<Override> overrides) async {
      final container = ProviderContainer(overrides: overrides);
      addTearDown(container.dispose);
      await container.read(authStateProvider.future);
      await container.read(churchSettingsProvider.future);
      return container;
    }

    AttendanceRecord service(DateTime date, int count) => AttendanceRecord(
          id: 'a${date.millisecondsSinceEpoch}',
          gatheringType: GatheringType.service,
          gatheringId: 'Sunday 9:00 AM',
          gatheringName: 'Morning',
          date: date,
          headcount: count,
        );

    AttendanceRecord groupMeeting(DateTime date, List<String> uids) => AttendanceRecord(
          id: 'g${date.millisecondsSinceEpoch}',
          gatheringType: GatheringType.group,
          gatheringId: 'g1',
          gatheringName: 'Young Adults',
          date: date,
          presentUids: uids,
        );

    test('attendance totals across a history mixing both modes', () async {
      final container = await containerWith(fakeOverrides(
        attendance: [
          service(DateTime.now().subtract(const Duration(days: 7)), 100),
          service(DateTime.now().subtract(const Duration(days: 14)), 120),
          groupMeeting(DateTime.now().subtract(const Duration(days: 3)), ['a', 'b', 'c']),
        ],
      ));
      await container.read(allAttendanceProvider.future);

      final attendance =
          container.read(reportSectionsProvider).firstWhere((s) => s.title == 'Attendance');
      expect(attendance.metrics.firstWhere((m) => m.label == 'People at services').value, '220');
      expect(attendance.metrics.firstWhere((m) => m.label == 'People at small groups').value, '3');
    });

    test('giving reuses the per-year grouping, not a second copy of the maths', () async {
      final container = await containerWith(fakeOverrides(
        giving: [
          GivingRecord(uid: 'u1', amount: 100, date: DateTime.now().subtract(const Duration(days: 5))),
          GivingRecord(uid: 'u2', amount: 250, date: DateTime.now().subtract(const Duration(days: 20))),
        ],
      ));
      await container.read(allGivingProvider.future);

      final giving = container.read(reportSectionsProvider).firstWhere((s) => s.title == 'Giving');
      expect(giving.metrics.first.value, contains('350'));
      expect(giving.metrics.firstWhere((m) => m.label == 'People who have given').value, '2');
    });

    test('participation is counted against everyone with an account', () async {
      final container = await containerWith(fakeOverrides(
        members: [
          testMember(uid: 'u1'),
          testMember(uid: 'u2'),
          testMember(uid: 'u3'),
          testMember(uid: 'u4'),
        ],
        groups: const [ChurchGroup(id: 'g1', name: 'Young Adults')],
        memberships: [
          GroupMembership(
            groupId: 'g1',
            uid: 'u1',
            status: MembershipStatus.approved,
            joinedAt: DateTime(2026),
          ),
          // Pending is not participation - they have asked, not joined.
          GroupMembership(groupId: 'g1', uid: 'u2', joinedAt: DateTime(2026)),
        ],
      ));
      await container.read(allMembershipsProvider.future);
      await container.read(allMembersProvider.future);

      final section =
          container.read(reportSectionsProvider).firstWhere((s) => s.title == 'Participation');
      expect(section.metrics.first.value, '25%');
      expect(section.metrics.first.detail, '1 of 4');
    });

    test('a section disappears when its feature is switched off', () async {
      final container = await containerWith(fakeOverrides(
        settings: testSettings(
          features: const FeatureFlags(attendance: false, giving: false, forms: false),
        ),
      ));

      final titles = container.read(reportSectionsProvider).map((s) => s.title);
      expect(titles, isNot(contains('Attendance')));
      expect(titles, isNot(contains('Giving')));
      expect(titles, isNot(contains('Forms')));
      expect(titles, contains('Participation'));
    });

    test('a church running nothing gets no sections at all', () async {
      final container = await containerWith(fakeOverrides(
        settings: testSettings(
          features: FeatureFlags.fromMap({
            for (final key in const FeatureFlags().toMap().keys) key: false,
          }),
        ),
      ));
      expect(container.read(reportSectionsProvider), isEmpty);
    });
  });

  group('access', () {
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

    testWidgets('an admin can open it', (tester) async {
      final container = await pumpApp(
        tester,
        fakeOverrides(signedInAs: testMember(uid: 'a1', role: UserRole.admin)),
      );
      container.read(routerProvider).go('/admin/reports');
      await tester.pumpAndSettle();

      expect(pathOf(container), '/admin/reports');
      expect(find.text('Reports'), findsWidgets);
    });

    testWidgets('plain staff are bounced, like members and settings', (tester) async {
      final container = await pumpApp(
        tester,
        fakeOverrides(signedInAs: testMember(uid: 's1', role: UserRole.staff)),
      );
      container.read(routerProvider).go('/admin/reports');
      await tester.pumpAndSettle();

      expect(pathOf(container), '/admin');
    });

    testWidgets('the page says what it deliberately does not measure', (tester) async {
      final container = await pumpApp(
        tester,
        fakeOverrides(signedInAs: testMember(uid: 'a1', role: UserRole.admin)),
      );
      container.read(routerProvider).go('/admin/reports');
      await tester.pumpAndSettle();

      expect(
        find.textContaining('does not record either'),
        findsOneWidget,
        reason: 'an absent metric must be stated, not silently missing',
      );
    });
  });
}
