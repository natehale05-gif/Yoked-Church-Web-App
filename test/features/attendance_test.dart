import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yoked_church_app/app/app.dart';
import 'package:yoked_church_app/app/router.dart';
import 'package:yoked_church_app/core/config/church_settings.dart';
import 'package:yoked_church_app/features/attendance/application/attendance_providers.dart';
import 'package:yoked_church_app/features/attendance/domain/attendance_record.dart';
import 'package:yoked_church_app/features/auth/application/auth_providers.dart';
import 'package:yoked_church_app/features/auth/domain/app_user.dart';
import 'package:yoked_church_app/features/groups/application/group_providers.dart';
import 'package:yoked_church_app/features/groups/domain/group.dart';

import '../fakes/fake_repositories.dart';

/// Two ways of counting, one history. The tests that matter are the ones
/// about mixing them: a church's year is Sundays *and* small groups, and
/// a total that only understands one of them is wrong without saying so.
void main() {
  AttendanceRecord service(String id, DateTime date, int count) => AttendanceRecord(
        id: id,
        gatheringType: GatheringType.service,
        gatheringId: 'Sunday 9:00 AM',
        gatheringName: 'Morning',
        date: date,
        headcount: count,
      );

  AttendanceRecord groupMeeting(String id, DateTime date, List<String> uids) => AttendanceRecord(
        id: id,
        gatheringType: GatheringType.group,
        gatheringId: 'g1',
        gatheringName: 'Young Adults',
        date: date,
        presentUids: uids,
      );

  group('effectiveCount', () {
    test('a service counts its headcount', () {
      expect(service('a', DateTime(2026, 7, 26), 118).effectiveCount, 118);
    });

    test('a group counts the roster it ticked, not its headcount field', () {
      final record = groupMeeting('b', DateTime(2026, 7, 23), ['u1', 'u2', 'u3']);
      expect(record.effectiveCount, 3);
      expect(record.isPerPerson, isTrue);
    });

    test('an empty group meeting reads as zero rather than as untaken', () {
      final record = groupMeeting('c', DateTime(2026, 7, 23), const []);
      expect(record.effectiveCount, 0);
      expect(record.isPerPerson, isFalse);
    });

    test('a mixed history totals across both modes', () {
      final series = AttendanceSeries.group([
        service('a', DateTime(2026, 7, 26), 100),
        groupMeeting('b', DateTime(2026, 7, 23), ['u1', 'u2']),
      ]);
      expect(series.fold<int>(0, (sum, s) => sum + s.total), 102);
    });
  });

  group('AttendanceSeries', () {
    test('groups by gathering and orders newest first inside each', () {
      final series = AttendanceSeries.group([
        service('a', DateTime(2026, 7, 12), 96),
        service('b', DateTime(2026, 7, 26), 118),
        service('c', DateTime(2026, 7, 19), 104),
        groupMeeting('d', DateTime(2026, 7, 23), ['u1']),
      ]);

      expect(series.length, 2);
      final sundays = series.firstWhere((s) => s.type == GatheringType.service);
      expect(sundays.records.map((r) => r.date.day), [26, 19, 12]);
      expect(sundays.latest!.effectiveCount, 118);
    });

    test('averages the mixed total over the number of occasions', () {
      final series = AttendanceSeries.group([
        service('a', DateTime(2026, 7, 12), 96),
        service('b', DateTime(2026, 7, 19), 104),
        service('c', DateTime(2026, 7, 26), 118),
      ]).single;

      expect(series.total, 318);
      expect(series.occasions, 3);
      expect(series.average, 106);
    });

    test('an empty history has no averages to divide by', () {
      const series = AttendanceSeries(
        type: GatheringType.group,
        gatheringId: 'g1',
        gatheringName: 'Young Adults',
        records: [],
      );
      expect(series.average, 0);
      expect(series.latest, isNull);
    });
  });

  group('deterministic ids', () {
    test('the same gathering on the same day is one record', () {
      final morning = attendanceId(GatheringType.service, 'Sunday 9:00 AM', DateTime(2026, 7, 26, 9));
      final evening = attendanceId(GatheringType.service, 'Sunday 9:00 AM', DateTime(2026, 7, 26, 21));
      expect(morning, evening);
    });

    test('two services on one day stay separate', () {
      expect(
        attendanceId(GatheringType.service, 'Sunday 9:00 AM', DateTime(2026, 7, 26)),
        isNot(attendanceId(GatheringType.service, 'Sunday 11:00 AM', DateTime(2026, 7, 26))),
      );
    });

    test('a group and a service can never collide on the same id', () {
      expect(
        attendanceId(GatheringType.group, 'x', DateTime(2026, 7, 26)),
        isNot(attendanceId(GatheringType.service, 'x', DateTime(2026, 7, 26))),
      );
    });
  });

  group('the controller', () {
    // Controller-level, on a bare container: a real Future inside a
    // widget test's fake async never completes.
    // `currentUserProvider` reads the auth stream's latest value, which
    // is null until the stream's first emission - so the sign-in has to
    // settle before anything asks who is acting.
    Future<ProviderContainer> containerWith({List<AttendanceRecord> attendance = const []}) async {
      final container = ProviderContainer(
        overrides: fakeOverrides(
          attendance: attendance,
          signedInAs: testMember(displayName: 'Pastor Test'),
        ),
      );
      addTearDown(container.dispose);
      await container.read(authStateProvider.future);
      return container;
    }

    const gathering = (type: GatheringType.service, id: 'Sunday 9:00 AM', name: 'Morning');

    test('recording the same Sunday twice corrects it instead of doubling it', () async {
      final container = await containerWith();
      final controller = container.read(attendanceControllerProvider);

      await controller.recordHeadcount(
        gathering: gathering,
        date: DateTime(2026, 7, 26),
        headcount: 118,
      );
      // A volunteer miscounted; someone re-enters it later that day.
      await controller.recordHeadcount(
        gathering: gathering,
        date: DateTime(2026, 7, 26, 18),
        headcount: 121,
      );

      final all = await container.read(allAttendanceProvider.future);
      expect(all, hasLength(1));
      expect(all.single.effectiveCount, 121);
    });

    test('the time of day never splits one gathering into two records', () async {
      final container = await containerWith();
      final all = await container.read(attendanceRepositoryProvider).fetchAll();
      expect(all, isEmpty);

      await container.read(attendanceControllerProvider).recordHeadcount(
            gathering: gathering,
            date: DateTime(2026, 7, 26, 23, 59),
            headcount: 40,
          );
      final stored = await container.read(attendanceRepositoryProvider).fetchAll();
      expect(stored.single.date, DateTime(2026, 7, 26));
    });

    test('a roster record stores who was there, and stamps who took it', () async {
      final container = await containerWith();
      await container.read(attendanceControllerProvider).recordRoster(
            gathering: (type: GatheringType.group, id: 'g1', name: 'Young Adults'),
            date: DateTime(2026, 7, 23),
            presentUids: ['u1', 'u2'],
          );

      final record = (await container.read(allAttendanceProvider.future)).single;
      expect(record.presentUids, ['u1', 'u2']);
      expect(record.effectiveCount, 2);
      expect(record.wasPresent('u1'), isTrue);
      expect(record.wasPresent('u9'), isFalse);
      expect(record.recordedBy, 'Pastor Test');
    });

    test('a negative headcount is refused rather than stored', () async {
      final container = await containerWith();
      await container.read(attendanceControllerProvider).recordHeadcount(
            gathering: gathering,
            date: DateTime(2026, 7, 26),
            headcount: -3,
          );
      expect(await container.read(allAttendanceProvider.future), isEmpty);
    });

    test('history for one gathering excludes the others', () async {
      final container = await containerWith(attendance: [
        service('a', DateTime(2026, 7, 26), 118),
        service('b', DateTime(2026, 7, 19), 104),
        groupMeeting('c', DateTime(2026, 7, 23), ['u1']),
      ]);

      final sundays = await container.read(gatheringHistoryProvider('Sunday 9:00 AM').future);
      expect(sundays, hasLength(2));
      expect(sundays.first.date.day, 26, reason: 'newest first');
    });
  });

  group('groups a member leads', () {
    test('are matched by account, not by the name typed on the group', () async {
      final container = ProviderContainer(
        overrides: fakeOverrides(
          signedInAs: testMember(uid: 'leader-1', displayName: 'Sarah Lee'),
          groups: const [
            ChurchGroup(id: 'g1', name: 'Young Adults', leaderName: 'Sarah Lee', leaderUid: 'leader-1'),
            // Same display name, no linked account: a coincidence of
            // names must not hand over someone else's roster.
            ChurchGroup(id: 'g2', name: "Men's Breakfast", leaderName: 'Sarah Lee'),
          ],
        ),
      );
      addTearDown(container.dispose);

      // Both sources are lazy: the groups list and the sign-in itself.
      await container.read(authStateProvider.future);
      await container.read(groupsProvider.future);
      expect(container.read(myLedGroupsProvider).map((g) => g.id), ['g1']);
    });

    test('a signed-out visitor leads nothing', () async {
      final container = ProviderContainer(
        overrides: fakeOverrides(
          groups: const [ChurchGroup(id: 'g1', name: 'Young Adults', leaderUid: 'leader-1')],
        ),
      );
      addTearDown(container.dispose);

      await container.read(groupsProvider.future);
      expect(container.read(myLedGroupsProvider), isEmpty);
    });
  });

  group('the group leader panel', () {
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

    const youngAdults = ChurchGroup(id: 'g1', name: 'Young Adults', leaderUid: 'leader-1');

    List<Override> overridesFor(AppUser? user) => fakeOverrides(
          signedInAs: user,
          groups: const [youngAdults],
          memberships: [
            GroupMembership(
              groupId: 'g1',
              uid: 'u-away',
              memberName: 'Absent Alice',
              status: MembershipStatus.approved,
              joinedAt: DateTime(2026, 1, 1),
            ),
            GroupMembership(
              groupId: 'g1',
              uid: 'u-here',
              memberName: 'Present Pete',
              status: MembershipStatus.approved,
              joinedAt: DateTime(2026, 1, 1),
            ),
          ],
          attendance: [
            groupMeeting('r1', DateTime(2026, 7, 23), ['u-here']),
            groupMeeting('r2', DateTime(2026, 7, 16), ['u-here']),
            groupMeeting('r3', DateTime(2026, 7, 9), ['u-here', 'u-away']),
          ],
        );

    testWidgets('shows the leader who has stopped coming', (tester) async {
      final container = await pumpApp(
        tester,
        overridesFor(testMember(uid: 'leader-1', displayName: 'Sarah Lee')),
      );
      container.read(routerProvider).go('/account/groups');
      await tester.pumpAndSettle();

      expect(find.text('Groups you lead'), findsOneWidget);
      expect(find.text('Young Adults · attendance'), findsOneWidget);
      // Three meetings: two of one person, one of two.
      expect(find.text('Averaging 1 over 3 meetings.'), findsOneWidget);
      // Alice was last there on 9 July and has missed the two since.
      expect(find.text('Jul 9, 2026 · missed 2'), findsOneWidget);
      expect(find.text('last meeting'), findsOneWidget);
    });

    testWidgets('stays hidden from a member who leads nothing', (tester) async {
      final container = await pumpApp(tester, overridesFor(testMember(uid: 'u-here')));
      container.read(routerProvider).go('/account/groups');
      await tester.pumpAndSettle();

      expect(find.text('Groups you lead'), findsNothing);
      expect(find.text('Young Adults'), findsOneWidget, reason: 'the ordinary group list still renders');
    });

    testWidgets('turning attendance off hides it from the leader too', (tester) async {
      final container = await pumpApp(
        tester,
        fakeOverrides(
          settings: testSettings(features: const FeatureFlags(attendance: false)),
          signedInAs: testMember(uid: 'leader-1'),
          groups: const [youngAdults],
          attendance: [groupMeeting('r1', DateTime(2026, 7, 23), ['u-here'])],
        ),
      );
      container.read(routerProvider).go('/account/groups');
      await tester.pumpAndSettle();

      expect(find.text('Groups you lead'), findsNothing);
    });
  });

  test('leaderUid round-trips through the settings map', () {
    const group = ChurchGroup(id: 'g1', name: 'Young Adults', leaderUid: 'leader-1');
    expect(ChurchGroup.fromMap('g1', group.toMap()).leaderUid, 'leader-1');
  });

  test('a group document written before leaderUid existed still loads', () {
    final legacy = ChurchGroup.fromMap('g1', const {'name': 'Young Adults', 'leaderName': 'Sarah Lee'});
    expect(legacy.leaderUid, isEmpty);
    expect(legacy.leaderName, 'Sarah Lee');
  });
}
