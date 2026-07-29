import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yoked_church_app/app/app.dart';
import 'package:yoked_church_app/app/router.dart';
import 'package:yoked_church_app/features/attendance/domain/attendance_record.dart';
import 'package:yoked_church_app/features/auth/domain/app_user.dart';
import 'package:yoked_church_app/features/church_info/domain/church_info.dart';
import 'package:yoked_church_app/features/connect/domain/connect_submission.dart';
import 'package:yoked_church_app/features/forms/domain/church_form.dart';
import 'package:yoked_church_app/features/forms/domain/form_submission.dart';
import 'package:yoked_church_app/features/giving/domain/giving_record.dart';
import 'package:yoked_church_app/features/groups/domain/group.dart';
import 'package:yoked_church_app/features/kids/domain/check_in.dart';
import 'package:yoked_church_app/features/notifications/domain/app_notification.dart';
import 'package:yoked_church_app/features/prayer_wall/domain/prayer_post.dart';
import 'package:yoked_church_app/features/rooms/domain/room.dart';
import 'package:yoked_church_app/features/sermon_notes/domain/sermon_note.dart';
import 'package:yoked_church_app/features/sermons/domain/sermon_series.dart';
import 'package:yoked_church_app/features/volunteering/domain/volunteering.dart';

import '../fakes/fake_repositories.dart';

/// Every screen, at the sizes people actually hold.
///
/// The app was built and verified at 1280px. The journeys that matter
/// most happen on a phone: service times on the way out the door, a
/// pickup code at the kids' desk, a group roster ticked off in someone's
/// living room. Nothing was checking that those fit.
///
/// A `RenderFlex` overflow during layout is reported as a test failure,
/// so pumping every route at phone width catches the whole class in one
/// pass - including on screens nobody thinks to open on a phone.
///
/// What this cannot catch is a layout that fits and is still unusable:
/// three text fields sharing ninety pixels throw nothing. That part is
/// verified with screenshots in a browser.
void main() {
  const phone = Size(390, 844);
  const tablet = Size(768, 1024);

  /// Seeded so lists render rows rather than empty states. An empty
  /// screen cannot overflow, and a suite that only ever sees empty
  /// states proves nothing.
  List<Override> seeded({AppUser? signedInAs}) {
    final now = DateTime.now();

    return fakeOverrides(
      signedInAs: signedInAs,
      members: [
        testMember(uid: 'u1', displayName: 'Hannah Brooks', directoryOptIn: true),
        testMember(uid: 'u2', displayName: 'Dev Patel', directoryOptIn: true),
        testMember(uid: 'staff1', displayName: 'Sarah Lee', role: UserRole.staff),
      ],
      sermons: [
        testSermon(id: 's1', title: 'The Longest Sermon Title We Could Reasonably Expect'),
        testSermon(id: 's2', title: 'Second Sermon', seriesId: 'series1', seriesName: 'A Series'),
      ],
      series: [
        SermonSeries(id: 'series1', name: 'A Series', description: 'Ten weeks', startDate: now),
      ],
      events: [
        testEvent(id: 'e1', title: 'Community Food Drive at the Fellowship Hall'),
        testEvent(id: 'e2', title: 'Youth Group Night'),
      ],
      staff: const [
        StaffMember(id: 'sm1', name: 'Pastor Test', role: 'Lead Pastor', bio: 'A bio.'),
      ],
      locations: const [
        ChurchLocation(id: 'l1', name: 'Main Campus', address: '1 Test St'),
      ],
      faqs: const [Faq(id: 'q1', question: 'Where do I park?', answer: 'Out front.')],
      groups: const [
        ChurchGroup(id: 'g1', name: 'Tuesday Morning Women', leaderName: 'Sarah Lee'),
        ChurchGroup(id: 'g2', name: 'Young Adults', leaderUid: 'u1', leaderName: 'Hannah Brooks'),
      ],
      memberships: [
        GroupMembership(
          groupId: 'g2',
          uid: 'u1',
          memberName: 'Hannah Brooks',
          status: MembershipStatus.approved,
          joinedAt: DateTime(2026),
        ),
        GroupMembership(groupId: 'g1', uid: 'u2', memberName: 'Dev Patel', joinedAt: DateTime(2026)),
      ],
      positions: [
        VolunteerPosition(
          id: 'vp1',
          title: 'Sunday Morning Greeter',
          date: now.add(const Duration(days: 7)),
          slotsNeeded: 3,
        ),
      ],
      assignments: [
        VolunteerAssignment(
          id: 'va1',
          positionId: 'vp1',
          uid: 'u1',
          memberName: 'Hannah Brooks',
          assignedAt: now,
        ),
      ],
      notifications: [
        AppNotification(
          id: 'n1',
          uid: 'u1',
          title: 'Your room booking is confirmed',
          message: '"Bible study" in the Fellowship Hall is booked.',
          createdAt: now,
        ),
      ],
      giving: [GivingRecord(uid: 'u1', amount: 120, date: now.subtract(const Duration(days: 5)))],
      devotionals: [testDevotional(id: 'd1')],
      readingPlans: [testPlan(id: 'p1')],
      sermonNotes: [
        SermonNote(
          id: 's1__u1',
          uid: 'u1',
          sermonId: 's1',
          sermonTitle: 'The Longest Sermon Title We Could Reasonably Expect',
          sermonDate: now,
          body: 'A note.',
          updatedAt: now,
        ),
      ],
      resources: [testResource(id: 'r1'), testResource(id: 'r2', membersOnly: true)],
      prayerPosts: [
        PrayerPost(
          id: 'pp1',
          uid: 'u1',
          authorName: 'Hannah Brooks',
          body: 'Please pray for my mother, who is having surgery on Thursday.',
          status: PrayerStatus.approved,
          createdAt: now,
        ),
        PrayerPost(id: 'pp2', uid: 'u2', body: 'Waiting on moderation', createdAt: now),
      ],
      rooms: const [
        Room(id: 'room1', name: 'Fellowship Hall', capacity: 120),
        Room(id: 'room2', name: 'Nursery', capacity: 12, bookable: false),
      ],
      bookings: [
        RoomBooking(
          id: 'rb1',
          roomId: 'room1',
          roomName: 'Fellowship Hall',
          requestedByUid: 'u1',
          requestedByName: 'Hannah Brooks',
          purpose: 'Tuesday morning Bible study',
          start: now.add(const Duration(days: 2)),
          end: now.add(const Duration(days: 2, hours: 2)),
        ),
      ],
      checkIns: [
        CheckInSession(
          id: 'ci1',
          childName: 'Sam Brooks',
          guardianUid: 'u1',
          guardianName: 'Hannah Brooks',
          guardianPhone: '(555) 010-2233',
          roomId: 'room2',
          roomName: 'Nursery',
          pickupCode: 'K4TP',
          allergyNote: 'Peanut allergy - epipen in her bag',
          checkedInAt: now,
        ),
      ],
      attendance: [
        AttendanceRecord(
          id: 'a1',
          gatheringType: GatheringType.service,
          gatheringId: 'Sunday 9:00 AM',
          gatheringName: 'Traditional Service (Sunday 9:00 AM)',
          date: now.subtract(const Duration(days: 3)),
          headcount: 118,
        ),
        AttendanceRecord(
          id: 'a2',
          gatheringType: GatheringType.group,
          gatheringId: 'g2',
          gatheringName: 'Young Adults',
          date: now.subtract(const Duration(days: 6)),
          presentUids: const ['u1', 'u2'],
        ),
      ],
      forms: [
        FormDefinition(
          id: 'f1',
          title: 'Summer Camp Registration',
          slug: 'summer-camp',
          description: 'Grades 6-12, August 10-14 at Lake Vernon.',
          published: true,
          closesAt: now.add(const Duration(days: 20)),
          fields: const [
            FormFieldDef(id: 'f1', label: "Camper's name", required: true),
            FormFieldDef(
              id: 'f2',
              label: 'Does your camper need transport from the church?',
              type: FormFieldType.radio,
              options: ['Yes', 'No'],
              required: true,
            ),
            FormFieldDef(id: 'f3', label: 'Allergies', type: FormFieldType.longText, page: 1),
          ],
        ),
      ],
      submissions: [
        FormSubmission(
          id: 'fs1',
          formId: 'f1',
          formTitle: 'Summer Camp Registration',
          submitterName: 'Maria Alvarez',
          submitterEmail: 'maria@example.org',
          answers: const {'f1': 'Ruth Alvarez', 'f2': 'No'},
          submittedAt: now,
        ),
      ],
      connect: FakeConnectRepository()
        ..seedInMemory([
          ConnectSubmission(
            id: 'c1',
            name: 'A Visitor',
            email: 'visitor@example.org',
            message: 'I would love to know more about the church.',
            type: ConnectType.prayerRequest,
            submittedAt: now,
          ),
        ]),
    );
  }

  /// Routes reachable without an account.
  const publicRoutes = [
    '/',
    '/sermons',
    '/sermons/s1',
    '/events',
    '/give',
    '/connect',
    '/about',
    '/visit',
    '/devotionals',
    '/devotionals/d1',
    '/resources',
    '/reading-plans',
    '/reading-plans/p1',
    '/forms',
    '/forms/summer-camp',
    '/sign-in',
    '/sign-up',
    '/forgot-password',
  ];

  const memberRoutes = [
    '/account',
    '/account/profile',
    '/account/groups',
    '/account/events',
    '/account/volunteering',
    '/account/reading',
    '/account/notes',
    '/account/prayer',
    '/account/bookings',
    '/account/kids',
    '/account/directory',
    '/account/giving',
    '/account/notifications',
  ];

  const adminRoutes = [
    '/admin',
    '/admin/sermons',
    '/admin/events',
    '/admin/groups',
    '/admin/volunteering',
    '/admin/devotionals',
    '/admin/reading-plans',
    '/admin/resources',
    '/admin/prayer',
    '/admin/rooms',
    '/admin/kids',
    '/admin/attendance',
    '/admin/forms',
    '/admin/forms/f1',
    '/admin/forms/f1/responses',
    '/admin/connect',
    '/admin/announcements',
    '/admin/members',
    '/admin/settings',
    '/admin/audit',
    '/admin/reports',
  ];

  Future<void> walk(
    WidgetTester tester,
    Size size,
    List<String> routes, {
    AppUser? signedInAs,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final container = ProviderContainer(overrides: seeded(signedInAs: signedInAs));
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const YokedChurchApp()),
    );
    await tester.pumpAndSettle();

    final router = container.read(routerProvider);
    final broken = <String>[];

    for (final route in routes) {
      router.go(route);

      // A screen that overflows re-throws every frame, which can also
      // stop `pumpAndSettle` ever settling. Catching that here keeps one
      // bad route from hiding every route after it - the whole point is
      // to come back with a work queue, not the first offender.
      var settled = true;
      try {
        await tester.pumpAndSettle(
          const Duration(milliseconds: 100),
          EnginePhase.sendSemanticsUpdate,
          const Duration(seconds: 5),
        );
      } catch (_) {
        settled = false;
        await tester.pump(const Duration(milliseconds: 100));
      }

      // Drain rather than take one: a layout error repeats per frame, and
      // a single leftover exception would be attributed to the next route.
      final messages = <String>{};
      for (var error = tester.takeException(); error != null; error = tester.takeException()) {
        messages.add(error.toString().split('\n').first);
      }

      if (messages.isNotEmpty || !settled) {
        broken.add([
          route,
          if (!settled) '      (never settled)',
          for (final message in messages.take(2)) '      $message',
        ].join('\n'));
      }
    }

    expect(
      broken,
      isEmpty,
      reason: 'these routes overflowed at ${size.width.toInt()}x${size.height.toInt()}:\n'
          '    ${broken.join('\n    ')}',
    );
  }

  group('phone (390x844)', () {
    testWidgets('public pages lay out', (tester) => walk(tester, phone, publicRoutes));

    testWidgets('the member portal lays out', (tester) async {
      await walk(tester, phone, memberRoutes, signedInAs: testMember(uid: 'u1'));
    });

    testWidgets('the staff dashboard lays out', (tester) async {
      await walk(tester, phone, adminRoutes, signedInAs: testMember(uid: 'a1', role: UserRole.admin));
    });
  });

  group('tablet (768x1024)', () {
    testWidgets('public pages lay out', (tester) => walk(tester, tablet, publicRoutes));

    testWidgets('the member portal lays out', (tester) async {
      await walk(tester, tablet, memberRoutes, signedInAs: testMember(uid: 'u1'));
    });

    testWidgets('the staff dashboard lays out', (tester) async {
      await walk(tester, tablet, adminRoutes, signedInAs: testMember(uid: 'a1', role: UserRole.admin));
    });
  });
}
