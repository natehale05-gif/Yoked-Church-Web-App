import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/config/settings_providers.dart';
import '../core/config/tenant.dart';
import '../core/config/settings_repository.dart';
import '../core/storage/file_storage.dart';
import '../features/announcements/application/announcement_providers.dart';
import '../features/announcements/data/announcement_repository.dart';
import '../features/attendance/application/attendance_providers.dart';
import '../features/attendance/data/attendance_repository.dart';
import '../features/audit_log/application/audit_providers.dart';
import '../features/audit_log/data/audit_repository.dart';
import '../features/auth/application/auth_providers.dart';
import '../features/auth/data/auth_repository.dart';
import '../features/auth/data/user_repository.dart';
import '../features/church_info/application/church_info_providers.dart';
import '../features/churches/application/church_providers.dart';
import '../features/churches/data/church_directory_repository.dart';
import '../features/church_info/data/church_info_repository.dart';
import '../features/connect/application/connect_providers.dart';
import '../features/connect/data/connect_repository.dart';
import '../features/devotionals/application/devotional_providers.dart';
import '../features/devotionals/data/devotional_repository.dart';
import '../features/events/application/event_providers.dart';
import '../features/events/application/rsvp_providers.dart';
import '../features/events/data/event_repository.dart';
import '../features/events/data/rsvp_repository.dart';
import '../features/forms/application/form_providers.dart';
import '../features/forms/data/form_repository.dart';
import '../features/giving/application/giving_providers.dart';
import '../features/giving/data/giving_repository.dart';
import '../features/groups/application/group_providers.dart';
import '../features/groups/data/group_repository.dart';
import '../features/kids/application/check_in_providers.dart';
import '../features/live/application/live_providers.dart';
import '../features/live/data/live_repository.dart';
import '../features/kids/data/check_in_repository.dart';
import '../features/notifications/application/notification_providers.dart';
import '../features/notifications/data/notification_repository.dart';
import '../features/prayer_wall/application/prayer_providers.dart';
import '../features/prayer_wall/data/prayer_repository.dart';
import '../features/reading_plans/application/reading_plan_providers.dart';
import '../features/reading_plans/data/reading_plan_repository.dart';
import '../features/rooms/application/room_providers.dart';
import '../features/rooms/data/room_repository.dart';
import '../features/resources/application/resource_providers.dart';
import '../features/resources/data/resource_repository.dart';
import '../features/sermon_notes/application/sermon_note_providers.dart';
import '../features/sermon_notes/data/sermon_note_repository.dart';
import '../features/sermons/application/sermon_providers.dart';
import '../features/sermons/data/sermon_repository.dart';
import '../features/volunteering/application/volunteering_providers.dart';
import '../features/volunteering/data/volunteering_repository.dart';

/// Which data source the app is running against.
///
/// This is the *only* place that decision is made. Everything downstream
/// depends on repository interfaces and is oblivious to the backend -
/// which is what makes the app testable and lets one build serve both a
/// live church and a zero-backend preview.
enum Backend { local, firestore }

/// Bundled-content mode: reads come from `assets/data/*.json`, writes are
/// held in memory for the session, and auth is a demo that can preview any
/// role. The entire app - including staff screens - is usable this way,
/// which is what makes the template demo-able before a customer sets up
/// Firebase.
List<Override> localOverrides() {
  // Shared across churches, unlike every other collection below.
  //
  // A demo sign-in has to enrol into the same congregation the screens
  // read from, and the demo session is held by the auth repository
  // itself - so making this per-church would sign the founder out at
  // the moment they were sent to the church they had just created.
  // The cost is that a brand-new church's Members list shows the sample
  // congregation; the content that matters - sermons, events, the
  // inbox - is properly its own.
  final users = LocalUserRepository();

  return [
      churchDirectoryProvider.overrideWithValue(LocalChurchDirectoryRepository()),
      settingsRepositoryProvider
          .overrideWith((ref) => LocalSettingsRepository(ref.watch(currentChurchIdProvider))),
      authRepositoryProvider.overrideWithValue(LocalAuthRepository(users)),
      userRepositoryProvider.overrideWithValue(users),
      liveRepositoryProvider.overrideWithValue(LocalLiveRepository()),
      sermonRepositoryProvider.overrideWith((ref) => LocalSermonRepository(ref.watch(currentChurchIdProvider))),
      sermonSeriesRepositoryProvider.overrideWith((ref) => LocalSermonSeriesRepository(ref.watch(currentChurchIdProvider))),
      eventRepositoryProvider.overrideWith((ref) => LocalEventRepository(ref.watch(currentChurchIdProvider))),
      rsvpRepositoryProvider.overrideWith((ref) => LocalRsvpRepository(ref.watch(currentChurchIdProvider))),
      connectRepositoryProvider.overrideWith((ref) => LocalConnectRepository(ref.watch(currentChurchIdProvider))),
      staffRepositoryProvider.overrideWith((ref) => LocalStaffRepository(ref.watch(currentChurchIdProvider))),
      locationRepositoryProvider.overrideWith((ref) => LocalLocationRepository(ref.watch(currentChurchIdProvider))),
      faqRepositoryProvider.overrideWith((ref) => LocalFaqRepository(ref.watch(currentChurchIdProvider))),
      groupRepositoryProvider.overrideWith((ref) => LocalGroupRepository(ref.watch(currentChurchIdProvider))),
      membershipRepositoryProvider.overrideWith((ref) => LocalMembershipRepository(ref.watch(currentChurchIdProvider))),
      volunteerPositionRepositoryProvider.overrideWith((ref) => LocalVolunteerPositionRepository(ref.watch(currentChurchIdProvider))),
      volunteerAssignmentRepositoryProvider.overrideWith((ref) => LocalVolunteerAssignmentRepository(ref.watch(currentChurchIdProvider))),
      notificationRepositoryProvider.overrideWith((ref) => LocalNotificationRepository(ref.watch(currentChurchIdProvider))),
      givingRepositoryProvider.overrideWith((ref) => LocalGivingRepository(ref.watch(currentChurchIdProvider))),
      announcementRepositoryProvider.overrideWith((ref) => LocalAnnouncementRepository(ref.watch(currentChurchIdProvider))),
      auditRepositoryProvider.overrideWith((ref) => LocalAuditRepository(ref.watch(currentChurchIdProvider))),
      devotionalRepositoryProvider.overrideWith((ref) => LocalDevotionalRepository(ref.watch(currentChurchIdProvider))),
      readingPlanRepositoryProvider.overrideWith((ref) => LocalReadingPlanRepository(ref.watch(currentChurchIdProvider))),
      planProgressRepositoryProvider.overrideWith((ref) => LocalPlanProgressRepository(ref.watch(currentChurchIdProvider))),
      sermonNoteRepositoryProvider.overrideWith((ref) => LocalSermonNoteRepository(ref.watch(currentChurchIdProvider))),
      resourceRepositoryProvider.overrideWith((ref) => LocalResourceRepository(ref.watch(currentChurchIdProvider))),
      fileStorageProvider.overrideWithValue(const UnavailableFileStorage()),
      roomRepositoryProvider.overrideWith((ref) => LocalRoomRepository(ref.watch(currentChurchIdProvider))),
      checkInRepositoryProvider.overrideWith((ref) => LocalCheckInRepository(ref.watch(currentChurchIdProvider))),
      bookingRepositoryProvider.overrideWith((ref) => LocalBookingRepository(ref.watch(currentChurchIdProvider))),
      prayerPostRepositoryProvider.overrideWith((ref) => LocalPrayerPostRepository(ref.watch(currentChurchIdProvider))),
      intercessionRepositoryProvider.overrideWith((ref) => LocalIntercessionRepository(ref.watch(currentChurchIdProvider))),
      attendanceRepositoryProvider.overrideWith((ref) => LocalAttendanceRepository(ref.watch(currentChurchIdProvider))),
      formRepositoryProvider.overrideWith((ref) => LocalFormRepository(ref.watch(currentChurchIdProvider))),
      submissionRepositoryProvider.overrideWith((ref) => LocalSubmissionRepository(ref.watch(currentChurchIdProvider))),
    ];
}

/// Live mode against a configured Firebase project.
///
/// Every repository is built from [currentChurchIdProvider] rather than
/// constructed once, so selecting a different church tears down and
/// rebuilds the entire data layer. That is what makes switching church
/// a re-render instead of a restart.
List<Override> firestoreOverrides() => [
      churchDirectoryProvider.overrideWithValue(FirestoreChurchDirectoryRepository()),
      settingsRepositoryProvider
          .overrideWith((ref) => FirestoreSettingsRepository(ref.watch(currentChurchIdProvider))),
      authRepositoryProvider.overrideWith((ref) => FirebaseAuthRepository(ref.watch(currentChurchIdProvider))),
      userRepositoryProvider.overrideWith((ref) => FirestoreUserRepository(ref.watch(currentChurchIdProvider))),
      liveRepositoryProvider.overrideWith((ref) => FirestoreLiveRepository(ref.watch(currentChurchIdProvider))),
      sermonRepositoryProvider.overrideWith((ref) => FirestoreSermonRepository(ref.watch(currentChurchIdProvider))),
      sermonSeriesRepositoryProvider.overrideWith((ref) => FirestoreSermonSeriesRepository(ref.watch(currentChurchIdProvider))),
      eventRepositoryProvider.overrideWith((ref) => FirestoreEventRepository(ref.watch(currentChurchIdProvider))),
      rsvpRepositoryProvider.overrideWith((ref) => FirestoreRsvpRepository(ref.watch(currentChurchIdProvider))),
      connectRepositoryProvider.overrideWith((ref) => FirestoreConnectRepository(ref.watch(currentChurchIdProvider))),
      staffRepositoryProvider.overrideWith((ref) => FirestoreStaffRepository(ref.watch(currentChurchIdProvider))),
      locationRepositoryProvider.overrideWith((ref) => FirestoreLocationRepository(ref.watch(currentChurchIdProvider))),
      faqRepositoryProvider.overrideWith((ref) => FirestoreFaqRepository(ref.watch(currentChurchIdProvider))),
      groupRepositoryProvider.overrideWith((ref) => FirestoreGroupRepository(ref.watch(currentChurchIdProvider))),
      membershipRepositoryProvider.overrideWith((ref) => FirestoreMembershipRepository(ref.watch(currentChurchIdProvider))),
      volunteerPositionRepositoryProvider.overrideWith((ref) => FirestoreVolunteerPositionRepository(ref.watch(currentChurchIdProvider))),
      volunteerAssignmentRepositoryProvider.overrideWith((ref) => FirestoreVolunteerAssignmentRepository(ref.watch(currentChurchIdProvider))),
      notificationRepositoryProvider.overrideWith((ref) => FirestoreNotificationRepository(ref.watch(currentChurchIdProvider))),
      givingRepositoryProvider.overrideWith((ref) => FirestoreGivingRepository(ref.watch(currentChurchIdProvider))),
      announcementRepositoryProvider.overrideWith((ref) => FirestoreAnnouncementRepository(ref.watch(currentChurchIdProvider))),
      auditRepositoryProvider.overrideWith((ref) => FirestoreAuditRepository(ref.watch(currentChurchIdProvider))),
      devotionalRepositoryProvider.overrideWith((ref) => FirestoreDevotionalRepository(ref.watch(currentChurchIdProvider))),
      readingPlanRepositoryProvider.overrideWith((ref) => FirestoreReadingPlanRepository(ref.watch(currentChurchIdProvider))),
      planProgressRepositoryProvider.overrideWith((ref) => FirestorePlanProgressRepository(ref.watch(currentChurchIdProvider))),
      sermonNoteRepositoryProvider.overrideWith((ref) => FirestoreSermonNoteRepository(ref.watch(currentChurchIdProvider))),
      resourceRepositoryProvider.overrideWith((ref) => FirestoreResourceRepository(ref.watch(currentChurchIdProvider))),
      fileStorageProvider.overrideWith((ref) => FirebaseFileStorage(ref.watch(currentChurchIdProvider))),
      roomRepositoryProvider.overrideWith((ref) => FirestoreRoomRepository(ref.watch(currentChurchIdProvider))),
      checkInRepositoryProvider.overrideWith((ref) => FirestoreCheckInRepository(ref.watch(currentChurchIdProvider))),
      bookingRepositoryProvider.overrideWith((ref) => FirestoreBookingRepository(ref.watch(currentChurchIdProvider))),
      prayerPostRepositoryProvider.overrideWith((ref) => FirestorePrayerPostRepository(ref.watch(currentChurchIdProvider))),
      intercessionRepositoryProvider.overrideWith((ref) => FirestoreIntercessionRepository(ref.watch(currentChurchIdProvider))),
      attendanceRepositoryProvider.overrideWith((ref) => FirestoreAttendanceRepository(ref.watch(currentChurchIdProvider))),
      formRepositoryProvider.overrideWith((ref) => FirestoreFormRepository(ref.watch(currentChurchIdProvider))),
      submissionRepositoryProvider.overrideWith((ref) => FirestoreSubmissionRepository(ref.watch(currentChurchIdProvider))),
    ];

List<Override> overridesFor(Backend backend) =>
    backend == Backend.firestore ? firestoreOverrides() : localOverrides();
