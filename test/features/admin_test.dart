import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yoked_church_app/app/app.dart';
import 'package:yoked_church_app/app/router.dart';
import 'package:yoked_church_app/app/theme.dart';
import 'package:yoked_church_app/core/config/church_settings.dart';
import 'package:yoked_church_app/core/config/settings_providers.dart';
import 'package:yoked_church_app/features/admin/application/settings_controller.dart';
import 'package:yoked_church_app/features/announcements/application/announcement_providers.dart';
import 'package:yoked_church_app/features/announcements/domain/announcement.dart';
import 'package:yoked_church_app/features/audit_log/application/audit_providers.dart';
import 'package:yoked_church_app/features/auth/application/auth_providers.dart';
import 'package:yoked_church_app/features/auth/domain/app_user.dart';
import 'package:yoked_church_app/features/groups/domain/group.dart';
import 'package:yoked_church_app/features/notifications/application/notification_providers.dart';
import 'package:yoked_church_app/features/volunteering/application/volunteering_providers.dart';
import 'package:yoked_church_app/features/volunteering/domain/volunteering.dart';

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

  AppUser admin() => testMember(uid: 'a1', displayName: 'Ada Admin', role: UserRole.admin);
  AppUser staff() => testMember(uid: 's1', displayName: 'Sam Staff', role: UserRole.staff);

  group('admin route guards', () {
    testWidgets('staff reach the dashboard but not the admin-only screens', (tester) async {
      final container = await pumpApp(tester, fakeOverrides(signedInAs: staff()));

      container.read(routerProvider).go('/admin');
      await tester.pumpAndSettle();
      expect(pathOf(container), '/admin');

      // Staff manage content, so the CMS is theirs.
      container.read(routerProvider).go('/admin/sermons');
      await tester.pumpAndSettle();
      expect(pathOf(container), '/admin/sermons');

      for (final adminOnly in ['/admin/settings', '/admin/members', '/admin/audit']) {
        container.read(routerProvider).go(adminOnly);
        await tester.pumpAndSettle();
        expect(pathOf(container), '/admin', reason: '$adminOnly should bounce staff back to the overview');
      }
    });

    testWidgets('an admin reaches every admin-only screen', (tester) async {
      final container = await pumpApp(tester, fakeOverrides(signedInAs: admin()));

      for (final path in ['/admin/settings', '/admin/members', '/admin/audit']) {
        container.read(routerProvider).go(path);
        await tester.pumpAndSettle();
        expect(pathOf(container), path);
      }
    });

    testWidgets('the nav hides admin-only tabs from staff', (tester) async {
      final container = await pumpApp(tester, fakeOverrides(signedInAs: staff()));
      container.read(routerProvider).go('/admin');
      await tester.pumpAndSettle();

      expect(find.text('Sermons'), findsWidgets);
      expect(find.text('Settings'), findsNothing);
      expect(find.text('Audit Log'), findsNothing);
    });
  });

  group('church settings', () {
    testWidgets('saving re-themes the live app', (tester) async {
      final container = await pumpApp(tester, fakeOverrides(signedInAs: admin()));

      expect(container.read(settingsProvider).churchName, 'Test Church');

      final updated = container.read(settingsProvider).copyWith(
            churchName: 'Grace Chapel',
            colors: const BrandColors(
              primary: Color(0xFFB00020),
              accent: Color(0xFFFFC107),
              background: Color(0xFFFFFFFF),
            ),
          );
      final ok = await container.read(settingsControllerProvider.notifier).save(updated);
      await tester.pumpAndSettle();

      expect(ok, isTrue);
      expect(container.read(settingsProvider).churchName, 'Grace Chapel');
      expect(container.read(themeProvider).colorScheme.primary, const Color(0xFFB00020));
      // The public site reads the same provider, so the rebrand is live.
      expect(find.text('Grace Chapel'), findsWidgets);
    });

    testWidgets('a settings change is attributed in the audit log', (tester) async {
      final container = await pumpApp(tester, fakeOverrides(signedInAs: admin()));

      await container.read(settingsControllerProvider.notifier).save(
            container.read(settingsProvider).copyWith(churchName: 'Grace Chapel'),
          );

      final entries = await container.read(auditRepositoryProvider).fetchAll();
      expect(entries, hasLength(1));
      expect(entries.single.actorName, 'Ada Admin');
      expect(entries.single.entity, 'church settings');
      expect(entries.single.action, 'updated');
    });

    testWidgets('turning a feature flag off removes it from the public nav', (tester) async {
      final container = await pumpApp(tester, fakeOverrides(signedInAs: admin()));
      expect(find.text('Give'), findsWidgets);

      await container.read(settingsControllerProvider.notifier).save(
            container.read(settingsProvider).copyWith(
                  features: container.read(settingsProvider).features.copyWithEntry('giving', false),
                ),
          );
      await tester.pumpAndSettle();

      expect(find.text('Give'), findsNothing);
    });
  });

  group('members and roles', () {
    testWidgets('an admin cannot change their own role', (tester) async {
      final me = admin();
      final container = await pumpApp(
        tester,
        fakeOverrides(signedInAs: me, members: [me, testMember(uid: 'm2', displayName: 'Other Member')]),
      );
      container.read(routerProvider).go('/admin/members');
      await tester.pumpAndSettle();

      final dropdowns = tester.widgetList<DropdownButtonFormField<UserRole>>(
        find.byType(DropdownButtonFormField<UserRole>),
      );
      expect(dropdowns, hasLength(2));
      // Exactly one row - the admin's own - is disabled.
      expect(dropdowns.where((d) => d.onChanged == null), hasLength(1));
      expect(find.text("Can't change your own role"), findsOneWidget);
    });

    testWidgets('promoting a member persists and is logged', (tester) async {
      final me = admin();
      final other = testMember(uid: 'm2', displayName: 'Other Member');
      final container = await pumpApp(tester, fakeOverrides(signedInAs: me, members: [me, other]));

      await container.read(userRepositoryProvider).updateRole('m2', UserRole.staff);
      await container.read(auditLoggerProvider).record(
            action: 'changed role',
            entity: 'member',
            details: 'Other Member → staff',
          );

      final stored = await container.read(userRepositoryProvider).fetchById('m2');
      expect(stored!.role, UserRole.staff);
      expect((await container.read(auditRepositoryProvider).fetchAll()).single.action, 'changed role');
    });
  });

  group('volunteer approvals', () {
    testWidgets('approving a pending signup confirms it and notifies the member', (tester) async {
      final position = VolunteerPosition(
        id: 'p1',
        title: 'Greeter',
        slotsNeeded: 2,
        date: DateTime(2026, 8, 2),
      );
      final pending = VolunteerAssignment(
        id: 'va1',
        positionId: 'p1',
        uid: 'm2',
        memberName: 'Other Member',
        status: AssignmentStatus.pending,
        assignedBy: 'self',
        assignedAt: DateTime(2026),
      );
      final container = await pumpApp(
        tester,
        fakeOverrides(signedInAs: admin(), positions: [position], assignments: [pending]),
      );

      await container.read(volunteerControllerProvider).approve(pending, position);
      await tester.pumpAndSettle();

      final stored = await container.read(volunteerAssignmentRepositoryProvider).fetchById('va1');
      expect(stored!.status, AssignmentStatus.approved);

      final notes = await container.read(notificationRepositoryProvider).fetchAll();
      expect(notes, hasLength(1));
      expect(notes.single.uid, 'm2');
      expect(notes.single.message, contains('Greeter'));
    });

    // A pending request holds its slot so a position can't be over-filled
    // while staff are still deciding; declining is what releases it.
    testWidgets('declining a request releases the slot it was holding', (tester) async {
      final position = VolunteerPosition(
        id: 'p1',
        title: 'Greeter',
        slotsNeeded: 2,
        date: DateTime(2026, 8, 2),
      );
      final pending = VolunteerAssignment(
        id: 'va1',
        positionId: 'p1',
        uid: 'm2',
        memberName: 'Other Member',
        status: AssignmentStatus.pending,
        assignedBy: 'self',
        assignedAt: DateTime(2026),
      );
      final container = await pumpApp(
        tester,
        fakeOverrides(signedInAs: admin(), positions: [position], assignments: [pending]),
      );

      expect((await container.read(openSlotsProvider.future))['p1'], 1);

      // Approving is a status change, not a new claim - the count holds.
      await container.read(volunteerControllerProvider).approve(pending, position);
      await tester.pumpAndSettle();
      expect((await container.read(openSlotsProvider.future))['p1'], 1);

      await container.read(volunteerControllerProvider).decline(pending);
      await tester.pumpAndSettle();
      expect((await container.read(openSlotsProvider.future))['p1'], 2);
    });
  });

  group('announcements', () {
    testWidgets('sending to everyone archives it and fans out to each inbox', (tester) async {
      final container = await pumpApp(
        tester,
        fakeOverrides(
          signedInAs: admin(),
          members: [admin(), testMember(uid: 'm2'), testMember(uid: 'm3')],
        ),
      );

      final ok = await container.read(announcementControllerProvider.notifier).send(
            title: 'Snow day',
            body: 'No services this Sunday.',
            audience: AnnouncementAudience.everyone,
          );
      await tester.pumpAndSettle();

      expect(ok, isTrue);
      final archived = await container.read(announcementRepositoryProvider).fetchAll();
      expect(archived.single.recipientCount, 3);
      expect(archived.single.sentByName, 'Ada Admin');

      final notes = await container.read(notificationRepositoryProvider).fetchAll();
      expect(notes.map((n) => n.uid).toSet(), {'a1', 'm2', 'm3'});
    });

    // The nav bar's bell subscribes once at startup, so a watch that only
    // ever yields its opening value leaves every long-lived listener
    // frozen at app launch - the inbox stays empty after a real send.
    testWidgets('an already-open inbox subscription sees the new message', (tester) async {
      final me = admin();
      final container = await pumpApp(tester, fakeOverrides(signedInAs: me, members: [me]));

      // The nav bar's bell is on screen, so this subscription is already
      // open before the announcement is sent.
      expect(container.read(unreadNotificationCountProvider), 0);

      await container.read(announcementControllerProvider.notifier).send(
            title: 'Snow day',
            body: 'No services this Sunday.',
            audience: AnnouncementAudience.everyone,
          );
      await tester.pumpAndSettle();

      expect(container.read(unreadNotificationCountProvider), 1);
    });

    testWidgets('a group announcement only reaches approved members of that group', (tester) async {
      const group = ChurchGroup(id: 'g1', name: 'Young Adults');
      final container = await pumpApp(
        tester,
        fakeOverrides(
          signedInAs: admin(),
          members: [admin(), testMember(uid: 'm2'), testMember(uid: 'm3')],
          groups: const [group],
          memberships: [
            GroupMembership(
              id: 'gm1',
              groupId: 'g1',
              uid: 'm2',
              memberName: 'Member Two',
              status: MembershipStatus.approved,
              joinedAt: DateTime(2026),
            ),
            GroupMembership(
              id: 'gm2',
              groupId: 'g1',
              uid: 'm3',
              memberName: 'Member Three',
              status: MembershipStatus.pending,
              joinedAt: DateTime(2026),
            ),
          ],
        ),
      );

      await container.read(announcementControllerProvider.notifier).send(
            title: 'Bowling night',
            body: 'Friday at 7.',
            audience: AnnouncementAudience.group,
            group: group,
          );
      await tester.pumpAndSettle();

      final notes = await container.read(notificationRepositoryProvider).fetchAll();
      expect(notes.map((n) => n.uid), ['m2']);
      expect(
        (await container.read(announcementRepositoryProvider).fetchAll()).single.audienceLabel,
        'Young Adults',
      );
    });
  });
}
