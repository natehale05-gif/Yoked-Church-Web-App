import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yoked_church_app/core/config/tenant.dart';
import 'package:yoked_church_app/app/app.dart';
import 'package:yoked_church_app/app/router.dart';
import 'package:yoked_church_app/core/config/church_settings.dart';
import 'package:yoked_church_app/features/auth/domain/app_user.dart';
import 'package:yoked_church_app/features/notifications/application/notification_providers.dart';
import 'package:yoked_church_app/features/rooms/application/room_providers.dart';
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

  ProviderContainer plainContainer(List<Override> overrides) {
    final container = ProviderContainer(overrides: overrides);
    addTearDown(container.dispose);
    return container;
  }

  String pathOf(ProviderContainer c) =>
      subPathOf(c.read(routerProvider).routerDelegate.currentConfiguration.uri.path);

  const hall = Room(id: 'hall', name: 'Fellowship Hall', capacity: 120);
  const nursery = Room(id: 'nursery', name: 'Nursery', bookable: false);

  RoomBooking booking({
    String id = 'b1',
    String roomId = 'hall',
    String uid = 'u1',
    String purpose = 'Small group',
    int startHour = 19,
    int endHour = 20,
    int day = 4,
    BookingStatus status = BookingStatus.pending,
  }) =>
      RoomBooking(
        id: id,
        roomId: roomId,
        roomName: 'Fellowship Hall',
        requestedByUid: uid,
        requestedByName: 'Hannah Brooks',
        purpose: purpose,
        start: DateTime(2099, 8, day, startHour),
        end: DateTime(2099, 8, day, endHour),
        status: status,
      );

  group('overlap arithmetic', () {
    test('back-to-back bookings do not clash', () {
      // A church building runs meetings end to end. Treating 3:00-4:00
      // and 4:00-5:00 as a conflict would make the feature useless.
      final earlier = booking(id: 'a', startHour: 15, endHour: 16);
      final later = booking(id: 'b', startHour: 16, endHour: 17);

      expect(earlier.overlaps(later), isFalse);
      expect(later.overlaps(earlier), isFalse);
    });

    test('a partial overlap clashes in both directions', () {
      final earlier = booking(id: 'a', startHour: 15, endHour: 17);
      final later = booking(id: 'b', startHour: 16, endHour: 18);

      expect(earlier.overlaps(later), isTrue);
      expect(later.overlaps(earlier), isTrue);
    });

    test('a booking fully inside another clashes', () {
      final outer = booking(id: 'a', startHour: 9, endHour: 17);
      final inner = booking(id: 'b', startHour: 12, endHour: 13);

      expect(outer.overlaps(inner), isTrue);
      expect(inner.overlaps(outer), isTrue);
    });

    test('the same hours in different rooms never clash', () {
      final inHall = booking(id: 'a', roomId: 'hall');
      final inUpper = booking(id: 'b', roomId: 'upper');

      expect(inHall.overlaps(inUpper), isFalse);
    });

    test('the same hours on different days never clash', () {
      expect(booking(id: 'a', day: 4).overlaps(booking(id: 'b', day: 5)), isFalse);
    });

    test('a backwards booking is rejected rather than stored', () {
      // It would silently never overlap with anything, which is worse
      // than refusing it.
      expect(booking(startHour: 20, endHour: 19).isWellFormed, isFalse);
      expect(booking(startHour: 19, endHour: 20).isWellFormed, isTrue);
    });

    test('only an approved booking holds the room', () {
      expect(booking(status: BookingStatus.approved).holdsTheRoom, isTrue);
      for (final status in [BookingStatus.pending, BookingStatus.declined, BookingStatus.cancelled]) {
        expect(booking(status: status).holdsTheRoom, isFalse, reason: '$status must not hold the room');
      }
    });
  });

  group('approval is where conflicts are caught', () {
    testWidgets('two members may both request the same slot', (tester) async {
      final container = await pumpApp(
        tester,
        fakeOverrides(signedInAs: testMember(uid: 'u1'), rooms: [hall]),
      );
      final controller = container.read(roomControllerProvider);

      await controller.request(
        room: hall,
        purpose: 'Small group',
        start: DateTime(2099, 8, 4, 19),
        end: DateTime(2099, 8, 4, 20),
      );
      await controller.request(
        room: hall,
        purpose: 'Baby shower',
        start: DateTime(2099, 8, 4, 19),
        end: DateTime(2099, 8, 4, 20),
      );
      await tester.pumpAndSettle();

      // Both are legitimate questions. Neither holds the room.
      final all = await container.read(bookingRepositoryProvider).fetchAll();
      expect(all, hasLength(2));
      expect(all.every((b) => b.status == BookingStatus.pending), isTrue);
    });

    testWidgets('the second approval is refused and names the clash', (tester) async {
      final container = await pumpApp(
        tester,
        fakeOverrides(
          signedInAs: testMember(uid: 'pastor', displayName: 'Sarah Lee', role: UserRole.staff),
          rooms: [hall],
          bookings: [
            booking(id: 'first', purpose: 'Small group', startHour: 19, endHour: 20),
            booking(id: 'second', purpose: 'Baby shower', startHour: 19, endHour: 20),
          ],
        ),
      );
      final controller = container.read(roomControllerProvider);
      final repo = container.read(bookingRepositoryProvider);

      expect(await controller.approve((await repo.fetchById('first'))!), isNull);
      await tester.pumpAndSettle();

      final conflict = await controller.approve((await repo.fetchById('second'))!);
      expect(conflict, isNotNull);
      expect(conflict!.existing.id, 'first');
      expect(conflict.existing.purpose, 'Small group');

      // And the refused one is still pending, not silently approved.
      expect((await repo.fetchById('second'))!.status, BookingStatus.pending);
    });

    testWidgets('re-approving an already-approved booking does not clash with itself', (tester) async {
      final container = await pumpApp(
        tester,
        fakeOverrides(
          signedInAs: testMember(uid: 'pastor', role: UserRole.staff),
          rooms: [hall],
          bookings: [booking(id: 'only', status: BookingStatus.approved)],
        ),
      );

      final existing = (await container.read(bookingRepositoryProvider).fetchById('only'))!;
      expect(await container.read(roomControllerProvider).approve(existing), isNull);
    });

    testWidgets('releasing a room frees the slot for the other request', (tester) async {
      final container = await pumpApp(
        tester,
        fakeOverrides(
          signedInAs: testMember(uid: 'pastor', role: UserRole.staff),
          rooms: [hall],
          bookings: [
            booking(id: 'first', status: BookingStatus.approved),
            booking(id: 'second', purpose: 'Baby shower'),
          ],
        ),
      );
      final controller = container.read(roomControllerProvider);
      final repo = container.read(bookingRepositoryProvider);

      expect(await controller.approve((await repo.fetchById('second'))!), isNotNull);

      await controller.cancel((await repo.fetchById('first'))!);
      await tester.pumpAndSettle();

      expect(await controller.approve((await repo.fetchById('second'))!), isNull);
      expect((await repo.fetchById('second'))!.status, BookingStatus.approved);
    });

    testWidgets('a declined booking never blocks anything', (tester) async {
      final container = await pumpApp(
        tester,
        fakeOverrides(
          signedInAs: testMember(uid: 'pastor', role: UserRole.staff),
          rooms: [hall],
          bookings: [
            booking(id: 'dead', status: BookingStatus.declined),
            booking(id: 'live', purpose: 'Baby shower'),
          ],
        ),
      );

      final live = (await container.read(bookingRepositoryProvider).fetchById('live'))!;
      expect(await container.read(roomControllerProvider).approve(live), isNull);
    });

    testWidgets('approving notifies the member who asked', (tester) async {
      final container = await pumpApp(
        tester,
        fakeOverrides(
          signedInAs: testMember(uid: 'pastor', displayName: 'Sarah Lee', role: UserRole.staff),
          rooms: [hall],
          bookings: [booking(id: 'b1', uid: 'member-7')],
        ),
      );

      final target = (await container.read(bookingRepositoryProvider).fetchById('b1'))!;
      await container.read(roomControllerProvider).approve(target);
      await tester.pumpAndSettle();

      final notes = await container.read(notificationRepositoryProvider).fetchAll();
      expect(notes.single.uid, 'member-7');
      expect(notes.single.message, contains('Fellowship Hall'));
      expect((await container.read(bookingRepositoryProvider).fetchById('b1'))!.moderatedBy, 'Sarah Lee');
    });

    testWidgets('declining sends the reason to the member', (tester) async {
      final container = await pumpApp(
        tester,
        fakeOverrides(
          signedInAs: testMember(uid: 'pastor', role: UserRole.staff),
          rooms: [hall],
          bookings: [booking(id: 'b1', uid: 'member-7')],
        ),
      );

      final target = (await container.read(bookingRepositoryProvider).fetchById('b1'))!;
      await container.read(roomControllerProvider).decline(target, note: 'The hall is set up for the food drive.');
      await tester.pumpAndSettle();

      final stored = (await container.read(bookingRepositoryProvider).fetchById('b1'))!;
      expect(stored.status, BookingStatus.declined);
      expect(stored.staffNote, contains('food drive'));

      final notes = await container.read(notificationRepositoryProvider).fetchAll();
      expect(notes.single.message, contains('food drive'));
    });
  });

  group('requesting', () {
    testWidgets('a signed-out visitor cannot request a room', (tester) async {
      final container = await pumpApp(tester, fakeOverrides(rooms: [hall]));

      await container.read(roomControllerProvider).request(
            room: hall,
            purpose: 'Nope',
            start: DateTime(2099, 8, 4, 19),
            end: DateTime(2099, 8, 4, 20),
          );
      await tester.pumpAndSettle();

      expect(await container.read(bookingRepositoryProvider).fetchAll(), isEmpty);
    });

    testWidgets('a backwards time range is not stored', (tester) async {
      final container = await pumpApp(
        tester,
        fakeOverrides(signedInAs: testMember(uid: 'u1'), rooms: [hall]),
      );

      await container.read(roomControllerProvider).request(
            room: hall,
            purpose: 'Time travel',
            start: DateTime(2099, 8, 4, 20),
            end: DateTime(2099, 8, 4, 19),
          );
      await tester.pumpAndSettle();

      expect(await container.read(bookingRepositoryProvider).fetchAll(), isEmpty);
    });

    testWidgets('a member sees only their own requests', (tester) async {
      final container = await pumpApp(
        tester,
        fakeOverrides(
          signedInAs: testMember(uid: 'u1'),
          rooms: [hall],
          bookings: [
            booking(id: 'mine', uid: 'u1'),
            booking(id: 'theirs', uid: 'u2'),
          ],
        ),
      );

      final mine = await container.read(myBookingsProvider.future);
      expect(mine.map((b) => b.id), ['mine']);
    });
  });

  group('rooms', () {
    test('a non-bookable room never reaches the booking form', () {
      // A nursery exists for check-in. It is not a meeting space.
      final container = plainContainer(fakeOverrides(rooms: [hall, nursery]));
      // Force the stream to resolve before reading the derived list.
      return container.read(roomsProvider.future).then((_) {
        expect(container.read(bookableRoomsProvider).map((r) => r.id), ['hall']);
      });
    });
  });

  group('the pending count', () {
    testWidgets('counts only upcoming requests still waiting', (tester) async {
      final container = await pumpApp(
        tester,
        fakeOverrides(
          signedInAs: testMember(uid: 'pastor', role: UserRole.staff),
          rooms: [hall],
          bookings: [
            booking(id: 'waiting', status: BookingStatus.pending),
            booking(id: 'done', status: BookingStatus.approved),
            booking(id: 'refused', status: BookingStatus.declined),
            RoomBooking(
              id: 'stale',
              roomId: 'hall',
              requestedByUid: 'u1',
              purpose: 'Last year',
              start: DateTime(2020, 1, 1, 10),
              end: DateTime(2020, 1, 1, 11),
            ),
          ],
        ),
      );
      await container.read(allBookingsProvider.future);

      // A request for a date that has already passed is not work.
      expect(container.read(pendingBookingCountProvider), 1);
    });
  });

  group('feature flag', () {
    testWidgets('turning roomBooking off closes both routes and hides both tabs', (tester) async {
      final container = await pumpApp(
        tester,
        fakeOverrides(
          settings: testSettings(features: const FeatureFlags(roomBooking: false)),
          signedInAs: testMember(uid: 'a1', role: UserRole.admin),
        ),
      );

      for (final path in ['/account/bookings', '/admin/rooms']) {
        container.read(routerProvider).go(path);
        await tester.pumpAndSettle();
        expect(pathOf(container), '/', reason: '$path should be closed');
      }

      container.read(routerProvider).go('/admin');
      await tester.pumpAndSettle();
      expect(find.text('Rooms'), findsNothing);
      expect(find.text('Room requests'), findsNothing);
    });
  });
}
