import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/config/settings_providers.dart';
import '../core/config/settings_repository.dart';
import '../core/storage/file_storage.dart';
import '../features/announcements/application/announcement_providers.dart';
import '../features/announcements/data/announcement_repository.dart';
import '../features/audit_log/application/audit_providers.dart';
import '../features/audit_log/data/audit_repository.dart';
import '../features/auth/application/auth_providers.dart';
import '../features/auth/data/auth_repository.dart';
import '../features/auth/data/user_repository.dart';
import '../features/church_info/application/church_info_providers.dart';
import '../features/church_info/data/church_info_repository.dart';
import '../features/connect/application/connect_providers.dart';
import '../features/connect/data/connect_repository.dart';
import '../features/devotionals/application/devotional_providers.dart';
import '../features/devotionals/data/devotional_repository.dart';
import '../features/events/application/event_providers.dart';
import '../features/events/application/rsvp_providers.dart';
import '../features/events/data/event_repository.dart';
import '../features/events/data/rsvp_repository.dart';
import '../features/giving/application/giving_providers.dart';
import '../features/giving/data/giving_repository.dart';
import '../features/groups/application/group_providers.dart';
import '../features/groups/data/group_repository.dart';
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
  // Shared, so a demo sign-in enrols that account in the same in-memory
  // congregation every other screen reads from.
  final users = LocalUserRepository();

  return [
      settingsRepositoryProvider.overrideWithValue(LocalSettingsRepository()),
      authRepositoryProvider.overrideWithValue(LocalAuthRepository(users)),
      userRepositoryProvider.overrideWithValue(users),
      sermonRepositoryProvider.overrideWithValue(LocalSermonRepository()),
      sermonSeriesRepositoryProvider.overrideWithValue(LocalSermonSeriesRepository()),
      eventRepositoryProvider.overrideWithValue(LocalEventRepository()),
      rsvpRepositoryProvider.overrideWithValue(LocalRsvpRepository()),
      connectRepositoryProvider.overrideWithValue(LocalConnectRepository()),
      staffRepositoryProvider.overrideWithValue(LocalStaffRepository()),
      locationRepositoryProvider.overrideWithValue(LocalLocationRepository()),
      faqRepositoryProvider.overrideWithValue(LocalFaqRepository()),
      groupRepositoryProvider.overrideWithValue(LocalGroupRepository()),
      membershipRepositoryProvider.overrideWithValue(LocalMembershipRepository()),
      volunteerPositionRepositoryProvider.overrideWithValue(LocalVolunteerPositionRepository()),
      volunteerAssignmentRepositoryProvider.overrideWithValue(LocalVolunteerAssignmentRepository()),
      notificationRepositoryProvider.overrideWithValue(LocalNotificationRepository()),
      givingRepositoryProvider.overrideWithValue(LocalGivingRepository()),
      announcementRepositoryProvider.overrideWithValue(LocalAnnouncementRepository()),
      auditRepositoryProvider.overrideWithValue(LocalAuditRepository()),
      devotionalRepositoryProvider.overrideWithValue(LocalDevotionalRepository()),
      readingPlanRepositoryProvider.overrideWithValue(LocalReadingPlanRepository()),
      planProgressRepositoryProvider.overrideWithValue(LocalPlanProgressRepository()),
      sermonNoteRepositoryProvider.overrideWithValue(LocalSermonNoteRepository()),
      resourceRepositoryProvider.overrideWithValue(LocalResourceRepository()),
      fileStorageProvider.overrideWithValue(const UnavailableFileStorage()),
      roomRepositoryProvider.overrideWithValue(LocalRoomRepository()),
      bookingRepositoryProvider.overrideWithValue(LocalBookingRepository()),
      prayerPostRepositoryProvider.overrideWithValue(LocalPrayerPostRepository()),
      intercessionRepositoryProvider.overrideWithValue(LocalIntercessionRepository()),
    ];
}

/// Live mode against a configured Firebase project.
List<Override> firestoreOverrides() => [
      settingsRepositoryProvider.overrideWithValue(FirestoreSettingsRepository()),
      authRepositoryProvider.overrideWithValue(FirebaseAuthRepository()),
      userRepositoryProvider.overrideWithValue(FirestoreUserRepository()),
      sermonRepositoryProvider.overrideWithValue(FirestoreSermonRepository()),
      sermonSeriesRepositoryProvider.overrideWithValue(FirestoreSermonSeriesRepository()),
      eventRepositoryProvider.overrideWithValue(FirestoreEventRepository()),
      rsvpRepositoryProvider.overrideWithValue(FirestoreRsvpRepository()),
      connectRepositoryProvider.overrideWithValue(FirestoreConnectRepository()),
      staffRepositoryProvider.overrideWithValue(FirestoreStaffRepository()),
      locationRepositoryProvider.overrideWithValue(FirestoreLocationRepository()),
      faqRepositoryProvider.overrideWithValue(FirestoreFaqRepository()),
      groupRepositoryProvider.overrideWithValue(FirestoreGroupRepository()),
      membershipRepositoryProvider.overrideWithValue(FirestoreMembershipRepository()),
      volunteerPositionRepositoryProvider.overrideWithValue(FirestoreVolunteerPositionRepository()),
      volunteerAssignmentRepositoryProvider.overrideWithValue(FirestoreVolunteerAssignmentRepository()),
      notificationRepositoryProvider.overrideWithValue(FirestoreNotificationRepository()),
      givingRepositoryProvider.overrideWithValue(FirestoreGivingRepository()),
      announcementRepositoryProvider.overrideWithValue(FirestoreAnnouncementRepository()),
      auditRepositoryProvider.overrideWithValue(FirestoreAuditRepository()),
      devotionalRepositoryProvider.overrideWithValue(FirestoreDevotionalRepository()),
      readingPlanRepositoryProvider.overrideWithValue(FirestoreReadingPlanRepository()),
      planProgressRepositoryProvider.overrideWithValue(FirestorePlanProgressRepository()),
      sermonNoteRepositoryProvider.overrideWithValue(FirestoreSermonNoteRepository()),
      resourceRepositoryProvider.overrideWithValue(FirestoreResourceRepository()),
      fileStorageProvider.overrideWithValue(FirebaseFileStorage()),
      roomRepositoryProvider.overrideWithValue(FirestoreRoomRepository()),
      bookingRepositoryProvider.overrideWithValue(FirestoreBookingRepository()),
      prayerPostRepositoryProvider.overrideWithValue(FirestorePrayerPostRepository()),
      intercessionRepositoryProvider.overrideWithValue(FirestoreIntercessionRepository()),
    ];

List<Override> overridesFor(Backend backend) =>
    backend == Backend.firestore ? firestoreOverrides() : localOverrides();
