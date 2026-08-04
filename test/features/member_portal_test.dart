import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yoked_church_app/app/app.dart';
import 'package:yoked_church_app/core/config/tenant.dart';
import 'package:yoked_church_app/app/router.dart';
import 'package:yoked_church_app/features/auth/application/auth_providers.dart';
import 'package:yoked_church_app/features/events/application/rsvp_providers.dart';
import 'package:yoked_church_app/features/groups/application/group_providers.dart';
import 'package:yoked_church_app/features/groups/domain/group.dart';
import 'package:yoked_church_app/features/notifications/domain/app_notification.dart';
import 'package:yoked_church_app/features/volunteering/application/volunteering_providers.dart';
import 'package:yoked_church_app/features/volunteering/domain/volunteering.dart';

import '../fakes/fake_repositories.dart';

void main() {
  /// Pumps the real app with fakes and returns the container so tests can
  /// drive navigation and read providers.
  Future<ProviderContainer> pumpApp(WidgetTester tester, List<Override> overrides) async {
    tester.view.physicalSize = const Size(1400, 2600);
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

  group('route guards', () {
    testWidgets('/account redirects an anonymous visitor to sign-in', (tester) async {
      final container = await pumpApp(tester, fakeOverrides());

      container.read(routerProvider).go('/account');
      await tester.pumpAndSettle();

      expect(find.text('Welcome back'), findsOneWidget);
      expect(find.text('Sign In'), findsWidgets);
    });

    testWidgets('/admin redirects a plain member to their account', (tester) async {
      final container = await pumpApp(tester, fakeOverrides(signedInAs: testMember()));

      container.read(routerProvider).go('/admin');
      await tester.pumpAndSettle();

      expect(
        subPathOf(container.read(routerProvider).routerDelegate.currentConfiguration.uri.path),
        '/account',
      );
    });

    testWidgets('a signed-in member reaches /account directly', (tester) async {
      final container = await pumpApp(
        tester,
        fakeOverrides(signedInAs: testMember(displayName: 'Hannah Brooks')),
      );

      container.read(routerProvider).go('/account');
      await tester.pumpAndSettle();

      expect(find.text('Hi, Hannah'), findsOneWidget);
    });
  });

  group('sign in', () {
    testWidgets('shows validation errors before attempting anything', (tester) async {
      final container = await pumpApp(tester, fakeOverrides());
      container.read(routerProvider).go('/sign-in');
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Sign In'));
      await tester.pumpAndSettle();

      expect(find.text('Enter your email'), findsOneWidget);
      expect(find.text('Enter your password'), findsOneWidget);
    });

    testWidgets('surfaces a failed sign-in as a readable message', (tester) async {
      final container = await pumpApp(tester, fakeOverrides());
      container.read(routerProvider).go('/sign-in');
      await tester.pumpAndSettle();

      await tester.enterText(find.widgetWithText(TextFormField, 'Email'), 'someone@example.org');
      await tester.enterText(find.widgetWithText(TextFormField, 'Password'), 'wrong');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Sign In'));
      await tester.pumpAndSettle();

      expect(find.textContaining("couldn't sign you in"), findsOneWidget);
      expect(container.read(isSignedInProvider), isFalse);
    });

    testWidgets('a successful sign-in lands on the account overview', (tester) async {
      final container = await pumpApp(tester, fakeOverrides());
      container.read(routerProvider).go('/sign-in');
      await tester.pumpAndSettle();

      await tester.enterText(find.widgetWithText(TextFormField, 'Email'), 'hannah@example.org');
      await tester.enterText(find.widgetWithText(TextFormField, 'Password'), 'correct-horse');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Sign In'));
      await tester.pumpAndSettle();

      expect(container.read(isSignedInProvider), isTrue);
      expect(find.textContaining('Hi,'), findsOneWidget);
    });
  });

  group('member actions', () {
    testWidgets('RSVP writes through the repository and updates the button', (tester) async {
      final container = await pumpApp(
        tester,
        fakeOverrides(
          signedInAs: testMember(),
          events: [testEvent(id: 'e1', title: 'Youth Night')],
        ),
      );

      container.read(routerProvider).go('/events');
      await tester.pumpAndSettle();
      expect(find.widgetWithText(OutlinedButton, 'RSVP'), findsOneWidget);

      await tester.tap(find.widgetWithText(OutlinedButton, 'RSVP'));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(OutlinedButton, "You're Going"), findsOneWidget);
      expect(container.read(myRsvpEventIdsProvider), contains('e1'));
    });

    testWidgets('anonymous visitors get no RSVP button at all', (tester) async {
      await pumpApp(tester, fakeOverrides(events: [testEvent(id: 'e1', title: 'Youth Night')]));

      expect(find.widgetWithText(OutlinedButton, 'RSVP'), findsNothing);
      expect(find.text('Youth Night'), findsWidgets);
    });

    testWidgets('joining a group creates a pending request, never an approved one', (tester) async {
      final container = await pumpApp(
        tester,
        fakeOverrides(
          signedInAs: testMember(),
          groups: [const ChurchGroup(id: 'g1', name: 'Young Adults', category: 'Fellowship')],
        ),
      );

      container.read(routerProvider).go('/account/groups');
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Request to Join'));
      await tester.pumpAndSettle();

      final memberships = await container.read(membershipRepositoryProvider).forMember('u1');
      expect(memberships.single.status, MembershipStatus.pending);
      expect(find.text('Pending'), findsOneWidget);
    });

    testWidgets('volunteer self-signup is pending and does not free a slot', (tester) async {
      final container = await pumpApp(
        tester,
        fakeOverrides(
          signedInAs: testMember(),
          positions: [
            VolunteerPosition(id: 'p1', title: 'Greeter', date: DateTime(2026, 8, 2), slotsNeeded: 2),
          ],
        ),
      );

      container.read(routerProvider).go('/account/volunteering');
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Sign Up'));
      await tester.pumpAndSettle();

      final mine = await container.read(myAssignmentsProvider.future);
      expect(mine.single.status, AssignmentStatus.pending);
      expect(mine.single.assignedBy, 'self');

      // Pending still counts against capacity, so it can't be double-filled.
      final slots = await container.read(openSlotsProvider.future);
      expect(slots['p1'], 1);
    });
  });

  group('notifications', () {
    testWidgets('unread count reflects only this member, and respects mute preferences',
        (tester) async {
      final container = await pumpApp(
        tester,
        fakeOverrides(
          signedInAs: testMember(uid: 'u1'),
          notifications: [
            AppNotification(
              id: 'n1',
              uid: 'u1',
              title: 'Mine',
              message: 'x',
              category: 'volunteering',
              createdAt: DateTime(2026, 7, 1),
            ),
            AppNotification(
              id: 'n2',
              uid: 'someone-else',
              title: 'Not mine',
              message: 'x',
              createdAt: DateTime(2026, 7, 1),
            ),
          ],
        ),
      );

      container.read(routerProvider).go('/account/notifications');
      await tester.pumpAndSettle();

      expect(find.text('Mine'), findsOneWidget);
      expect(find.text('Not mine'), findsNothing);
    });
  });

  group('directory', () {
    testWidgets('lists only members who opted in', (tester) async {
      final container = await pumpApp(
        tester,
        fakeOverrides(
          signedInAs: testMember(),
          members: [
            testMember(uid: 'a', displayName: 'Opted In', directoryOptIn: true),
            testMember(uid: 'b', displayName: 'Stayed Private', directoryOptIn: false),
          ],
        ),
      );

      container.read(routerProvider).go('/account/directory');
      await tester.pumpAndSettle();

      expect(find.text('Opted In'), findsOneWidget);
      expect(find.text('Stayed Private'), findsNothing);
    });
  });
}
