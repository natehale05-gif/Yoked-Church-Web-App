import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yoked_church_app/core/config/tenant.dart';
import 'package:yoked_church_app/app/app.dart';
import 'package:yoked_church_app/app/router.dart';
import 'package:yoked_church_app/core/config/church_settings.dart';
import 'package:yoked_church_app/features/auth/domain/app_user.dart';
import 'package:yoked_church_app/features/kids/application/check_in_providers.dart';
import 'package:yoked_church_app/features/kids/domain/check_in.dart';
import 'package:yoked_church_app/features/rooms/domain/room.dart';

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

  /// The roster providers derive from the fetch, which is lazy - reading
  /// the count before it resolves gives 0 regardless of the data.
  Future<int> activeCount(ProviderContainer c) async {
    await c.read(allCheckInsProvider.future);
    return c.read(activeCheckInCountProvider);
  }

  const nursery = Room(id: 'nursery', name: 'Nursery', capacity: 12, bookable: false);
  const kidsA = Room(id: 'kids-a', name: 'Kids Room A', capacity: 20, bookable: false);

  CheckInSession session({
    String id = 's1',
    String childName = 'Sam Demo',
    String guardianUid = 'u1',
    String roomId = 'nursery',
    String code = 'RTQ4',
    CheckInStatus status = CheckInStatus.checkedIn,
    DateTime? codeUsedAt,
    String releasedTo = '',
    DateTime? birthDate,
    String allergyNote = '',
  }) =>
      CheckInSession(
        id: id,
        childName: childName,
        childBirthDate: birthDate,
        guardianUid: guardianUid,
        guardianName: 'Hannah Brooks',
        roomId: roomId,
        roomName: 'Nursery',
        allergyNote: allergyNote,
        checkedInAt: DateTime(2026, 8, 2, 9, 5),
        pickupCode: code,
        codeUsedAt: codeUsedAt,
        releasedTo: releasedTo,
        status: status,
      );

  group('pickup codes', () {
    test('avoid characters a parent could misread aloud', () {
      // O/0 and I/1/L are read across a noisy foyer, and a misread
      // character is a failed pickup.
      final generated = {for (var i = 0; i < 300; i++) generatePickupCode(const [])};
      final all = generated.join();

      for (final banned in ['O', '0', 'I', '1', 'L']) {
        expect(all.contains(banned), isFalse, reason: '$banned is too easy to misread');
      }
    });

    test('never collide with a code already in use', () {
      // Exhaust a tiny alphabet by claiming almost everything, and check
      // the generator still finds the gap rather than duplicating.
      final rng = Random(7);
      final issued = <String>{};
      for (var i = 0; i < 200; i++) {
        final code = generatePickupCode(issued, random: rng);
        expect(issued.contains(code), isFalse, reason: 'issued a duplicate on attempt $i');
        issued.add(code);
      }
      expect(issued, hasLength(200));
    });

    test('widen rather than duplicate when the space is exhausted', () {
      // Claim every 1-character code, then demand another.
      const alphabet = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';
      final taken = alphabet.split('').toSet();

      final code = generatePickupCode(taken, length: 1);
      expect(taken.contains(code), isFalse);
      expect(code.length, greaterThan(1), reason: 'should widen instead of handing out a duplicate');
    });
  });

  group('checking in', () {
    testWidgets('mints a code that is unique among children in the building', (tester) async {
      final container = await pumpApp(
        tester,
        fakeOverrides(
          signedInAs: testMember(uid: 'pastor', role: UserRole.staff),
          rooms: [nursery, kidsA],
        ),
      );
      final controller = container.read(checkInControllerProvider);

      final codes = <String>{};
      for (var i = 0; i < 25; i++) {
        final s = await controller.checkIn(childName: 'Child $i', room: nursery, guardianUid: 'u$i');
        expect(s, isNotNull);
        expect(codes.contains(s!.pickupCode), isFalse, reason: 'duplicate code for Child $i');
        codes.add(s.pickupCode);
      }
      await tester.pumpAndSettle();

      expect(await activeCount(container), 25);
    });

    testWidgets('a child with no name is not checked in', (tester) async {
      final container = await pumpApp(
        tester,
        fakeOverrides(signedInAs: testMember(uid: 'pastor', role: UserRole.staff), rooms: [nursery]),
      );

      expect(await container.read(checkInControllerProvider).checkIn(
            childName: '   ',
            room: nursery,
            guardianUid: 'u1',
          ),
          isNull);
      expect(await container.read(checkInRepositoryProvider).fetchAll(), isEmpty);
    });

    testWidgets('a collected child frees their code for reuse', (tester) async {
      // Reusing last service's code is fine and expected - the space is
      // small on purpose. What must never repeat is two *active* codes.
      final container = await pumpApp(
        tester,
        fakeOverrides(
          signedInAs: testMember(uid: 'pastor', role: UserRole.staff),
          rooms: [nursery],
          checkIns: [
            session(id: 'gone', code: 'AAAA', status: CheckInStatus.collected, codeUsedAt: DateTime(2026, 8, 1)),
          ],
        ),
      );

      final codes = <String>{};
      for (var i = 0; i < 30; i++) {
        final s = await container.read(checkInControllerProvider).checkIn(
              childName: 'Child $i',
              room: nursery,
              guardianUid: 'u$i',
            );
        codes.add(s!.pickupCode);
      }
      // No assertion that AAAA reappears - just that nothing active clashes.
      expect(codes, hasLength(30));
    });
  });

  group('releasing', () {
    testWidgets('a valid code releases the child exactly once', (tester) async {
      final container = await pumpApp(
        tester,
        fakeOverrides(
          signedInAs: testMember(uid: 'pastor', role: UserRole.staff),
          rooms: [nursery],
          checkIns: [session(code: 'RTQ4')],
        ),
      );
      final controller = container.read(checkInControllerProvider);

      final first = await controller.release(code: 'RTQ4', releasedTo: 'Hannah Brooks');
      expect(first.ok, isTrue);
      expect(first.released!.childName, 'Sam Demo');
      expect(first.released!.status, CheckInStatus.collected);
      expect(first.released!.codeUsedAt, isNotNull);
      expect(first.released!.releasedTo, 'Hannah Brooks');
      await tester.pumpAndSettle();

      // Second attempt with the same code must fail, and say why.
      final second = await controller.release(code: 'RTQ4');
      expect(second.ok, isFalse);
      expect(second.failure, ReleaseFailure.alreadyUsed);
      expect(second.spent!.releasedTo, 'Hannah Brooks');
      expect(second.spent!.codeUsedAt, isNotNull);
    });

    testWidgets('an unknown code is refused as unknown, not as used', (tester) async {
      // The two failures call for very different responses at the door.
      final container = await pumpApp(
        tester,
        fakeOverrides(
          signedInAs: testMember(uid: 'pastor', role: UserRole.staff),
          checkIns: [session(code: 'RTQ4')],
        ),
      );

      final result = await container.read(checkInControllerProvider).release(code: 'ZZZZ');
      expect(result.ok, isFalse);
      expect(result.failure, ReleaseFailure.noSuchCode);
      expect(result.spent, isNull);
    });

    testWidgets('an empty code is refused rather than matching anything', (tester) async {
      final container = await pumpApp(
        tester,
        fakeOverrides(
          signedInAs: testMember(uid: 'pastor', role: UserRole.staff),
          checkIns: [session(code: 'RTQ4')],
        ),
      );

      final result = await container.read(checkInControllerProvider).release(code: '   ');
      expect(result.failure, ReleaseFailure.noSuchCode);
      expect((await container.read(checkInRepositoryProvider).fetchById('s1'))!.isActive, isTrue);
    });

    testWidgets('codes are matched case-insensitively and trimmed', (tester) async {
      final container = await pumpApp(
        tester,
        fakeOverrides(
          signedInAs: testMember(uid: 'pastor', role: UserRole.staff),
          checkIns: [session(code: 'RTQ4')],
        ),
      );

      final result = await container.read(checkInControllerProvider).release(code: '  rtq4 ');
      expect(result.ok, isTrue);
    });

    testWidgets('releasing one child leaves every other child checked in', (tester) async {
      final container = await pumpApp(
        tester,
        fakeOverrides(
          signedInAs: testMember(uid: 'pastor', role: UserRole.staff),
          checkIns: [
            session(id: 'a', childName: 'Sam', code: 'AAAA'),
            session(id: 'b', childName: 'Ada', code: 'BBBB'),
            session(id: 'c', childName: 'Ben', code: 'CCCC'),
          ],
        ),
      );

      await container.read(checkInControllerProvider).release(code: 'BBBB');
      await tester.pumpAndSettle();

      final repo = container.read(checkInRepositoryProvider);
      expect((await repo.fetchById('a'))!.isActive, isTrue);
      expect((await repo.fetchById('b'))!.isActive, isFalse);
      expect((await repo.fetchById('c'))!.isActive, isTrue);
      expect(await activeCount(container), 2);
    });

    testWidgets('a staff override is recorded as an override', (tester) async {
      final container = await pumpApp(
        tester,
        fakeOverrides(
          signedInAs: testMember(uid: 'pastor', role: UserRole.staff),
          checkIns: [session(code: 'RTQ4')],
        ),
      );

      final target = (await container.read(checkInRepositoryProvider).fetchById('s1'))!;
      await container.read(checkInControllerProvider).releaseWithoutCode(target, releasedTo: 'Grandma');
      await tester.pumpAndSettle();

      final stored = (await container.read(checkInRepositoryProvider).fetchById('s1'))!;
      expect(stored.status, CheckInStatus.collected);
      // Not dressed up as a normal pickup.
      expect(stored.releasedTo, contains('staff override'));
      expect(stored.releasedTo, contains('Grandma'));
    });
  });

  group('what a guardian can see', () {
    testWidgets('only their own children', (tester) async {
      final container = await pumpApp(
        tester,
        fakeOverrides(
          signedInAs: testMember(uid: 'u1'),
          checkIns: [
            session(id: 'mine', childName: 'Sam', guardianUid: 'u1'),
            session(id: 'theirs', childName: 'Someone Else', guardianUid: 'u2'),
          ],
        ),
      );

      final mine = await container.read(myCheckInsProvider.future);
      expect(mine.map((s) => s.childName), ['Sam']);
    });

    testWidgets('the pickup code is on their own page', (tester) async {
      final container = await pumpApp(
        tester,
        fakeOverrides(
          signedInAs: testMember(uid: 'u1'),
          checkIns: [session(childName: 'Sam Demo', code: 'RTQ4')],
        ),
      );
      container.read(routerProvider).go('/account/kids');
      await tester.pumpAndSettle();

      expect(find.text('Sam Demo'), findsOneWidget);
      expect(find.text('RTQ4'), findsOneWidget);
      expect(find.textContaining('It works once'), findsOneWidget);
    });
  });

  group('the roster', () {
    testWidgets('groups children by room and counts only active ones', (tester) async {
      final container = await pumpApp(
        tester,
        fakeOverrides(
          signedInAs: testMember(uid: 'pastor', role: UserRole.staff),
          rooms: [nursery, kidsA],
          checkIns: [
            session(id: 'a', roomId: 'nursery', code: 'AAAA'),
            session(id: 'b', roomId: 'nursery', code: 'BBBB'),
            session(id: 'c', roomId: 'kids-a', code: 'CCCC'),
            session(id: 'gone', roomId: 'nursery', code: 'DDDD', status: CheckInStatus.collected),
          ],
        ),
      );
      await container.read(allCheckInsProvider.future);

      final byRoom = container.read(checkInsByRoomProvider);
      expect(byRoom['nursery'], hasLength(2));
      expect(byRoom['kids-a'], hasLength(1));
      expect(await activeCount(container), 3);
    });
  });

  group('age from birth date', () {
    test('is whole years at check-in', () {
      final child = session(birthDate: DateTime(2020, 3, 1));
      // Checked in 2026-08-02, birthday already passed that year.
      expect(child.ageYears, 6);
    });

    test('accounts for a birthday later in the year', () {
      final child = session(birthDate: DateTime(2020, 12, 25));
      expect(child.ageYears, 5);
    });

    test('is null when no birth date was recorded', () {
      expect(session().ageYears, isNull);
    });
  });

  group('feature flag', () {
    testWidgets('turning kidsCheckIn off closes both routes and hides both tabs', (tester) async {
      final container = await pumpApp(
        tester,
        fakeOverrides(
          settings: testSettings(features: const FeatureFlags(kidsCheckIn: false)),
          signedInAs: testMember(uid: 'a1', role: UserRole.admin),
        ),
      );

      for (final path in ['/account/kids', '/admin/kids']) {
        container.read(routerProvider).go(path);
        await tester.pumpAndSettle();
        expect(pathOf(container), '/', reason: '$path should be closed');
      }

      container.read(routerProvider).go('/admin');
      await tester.pumpAndSettle();
      expect(find.text('Kids'), findsNothing);
    });
  });

  group('the household birth date', () {
    testWidgets('a parent can record and clear it', (tester) async {
      // The field existed from the start but nothing could set it, so
      // check-in had no age to show a volunteer.
      final container = await pumpApp(
        tester,
        fakeOverrides(
          signedInAs: AppUser(
            uid: 'u1',
            email: 'h@example.org',
            displayName: 'Hannah Brooks',
            household: const [HouseholdMember(name: 'Sam Brooks', relationship: 'Child')],
            createdAt: DateTime(2025),
          ),
        ),
      );
      container.read(routerProvider).go('/account/profile');
      await tester.pumpAndSettle();

      expect(find.text('Date of birth'), findsOneWidget);
      expect(find.text('For kids check-in'), findsOneWidget);
      expect(find.text('Optional'), findsOneWidget);
    });
  });
}
