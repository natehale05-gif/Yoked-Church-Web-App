import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yoked_church_app/core/config/church_settings.dart';
import 'package:yoked_church_app/core/config/tenant.dart';
import 'package:yoked_church_app/features/churches/application/church_providers.dart';
import 'package:yoked_church_app/features/churches/data/church_directory_repository.dart';
import 'package:yoked_church_app/core/config/settings_providers.dart';
import 'package:yoked_church_app/core/config/settings_repository.dart';
import 'package:yoked_church_app/core/firestore/crud_repository.dart';
import 'package:yoked_church_app/features/announcements/application/announcement_providers.dart';
import 'package:yoked_church_app/features/announcements/data/announcement_repository.dart';
import 'package:yoked_church_app/features/announcements/domain/announcement.dart';
import 'package:yoked_church_app/features/attendance/application/attendance_providers.dart';
import 'package:yoked_church_app/features/attendance/data/attendance_repository.dart';
import 'package:yoked_church_app/features/attendance/domain/attendance_record.dart';
import 'package:yoked_church_app/features/audit_log/application/audit_providers.dart';
import 'package:yoked_church_app/features/audit_log/data/audit_repository.dart';
import 'package:yoked_church_app/features/audit_log/domain/audit_entry.dart';
import 'package:yoked_church_app/features/auth/application/auth_providers.dart';
import 'package:yoked_church_app/features/auth/data/auth_repository.dart';
import 'package:yoked_church_app/features/auth/data/user_repository.dart';
import 'package:yoked_church_app/features/auth/domain/app_user.dart';
import 'package:yoked_church_app/features/church_info/application/church_info_providers.dart';
import 'package:yoked_church_app/features/church_info/data/church_info_repository.dart';
import 'package:yoked_church_app/features/church_info/domain/church_info.dart';
import 'package:yoked_church_app/features/connect/application/connect_providers.dart';
import 'package:yoked_church_app/features/connect/data/connect_repository.dart';
import 'package:yoked_church_app/features/connect/domain/connect_submission.dart';
import 'package:yoked_church_app/features/devotionals/application/devotional_providers.dart';
import 'package:yoked_church_app/features/devotionals/data/devotional_repository.dart';
import 'package:yoked_church_app/features/devotionals/domain/devotional.dart';
import 'package:yoked_church_app/features/events/application/event_providers.dart';
import 'package:yoked_church_app/features/events/application/rsvp_providers.dart';
import 'package:yoked_church_app/features/events/data/event_repository.dart';
import 'package:yoked_church_app/features/events/data/rsvp_repository.dart';
import 'package:yoked_church_app/features/events/domain/church_event.dart';
import 'package:yoked_church_app/features/events/domain/event_rsvp.dart';
import 'package:yoked_church_app/features/forms/application/form_providers.dart';
import 'package:yoked_church_app/features/forms/data/form_repository.dart';
import 'package:yoked_church_app/features/forms/domain/church_form.dart';
import 'package:yoked_church_app/features/forms/domain/form_submission.dart';
import 'package:yoked_church_app/features/giving/application/giving_providers.dart';
import 'package:yoked_church_app/features/giving/data/giving_repository.dart';
import 'package:yoked_church_app/features/giving/domain/giving_record.dart';
import 'package:yoked_church_app/features/groups/application/group_providers.dart';
import 'package:yoked_church_app/features/groups/data/group_repository.dart';
import 'package:yoked_church_app/features/groups/domain/group.dart';
import 'package:yoked_church_app/features/kids/application/check_in_providers.dart';
import 'package:yoked_church_app/features/kids/data/check_in_repository.dart';
import 'package:yoked_church_app/features/kids/domain/check_in.dart';
import 'package:yoked_church_app/features/notifications/application/notification_providers.dart';
import 'package:yoked_church_app/features/notifications/data/notification_repository.dart';
import 'package:yoked_church_app/features/notifications/domain/app_notification.dart';
import 'package:yoked_church_app/core/storage/file_storage.dart';
import 'package:yoked_church_app/features/prayer_wall/application/prayer_providers.dart';
import 'package:yoked_church_app/features/prayer_wall/data/prayer_repository.dart';
import 'package:yoked_church_app/features/prayer_wall/domain/prayer_post.dart';
import 'package:yoked_church_app/features/reading_plans/application/reading_plan_providers.dart';
import 'package:yoked_church_app/features/reading_plans/data/reading_plan_repository.dart';
import 'package:yoked_church_app/features/reading_plans/domain/reading_plan.dart';
import 'package:yoked_church_app/features/resources/application/resource_providers.dart';
import 'package:yoked_church_app/features/resources/data/resource_repository.dart';
import 'package:yoked_church_app/features/resources/domain/resource.dart';
import 'package:yoked_church_app/features/rooms/application/room_providers.dart';
import 'package:yoked_church_app/features/rooms/data/room_repository.dart';
import 'package:yoked_church_app/features/rooms/domain/room.dart';
import 'package:yoked_church_app/features/sermon_notes/application/sermon_note_providers.dart';
import 'package:yoked_church_app/features/sermon_notes/data/sermon_note_repository.dart';
import 'package:yoked_church_app/features/sermon_notes/domain/sermon_note.dart';
import 'package:yoked_church_app/features/sermons/application/sermon_providers.dart';
import 'package:yoked_church_app/features/sermons/data/sermon_repository.dart';
import 'package:yoked_church_app/features/sermons/domain/sermon.dart';
import 'package:yoked_church_app/features/sermons/domain/sermon_series.dart';
import 'package:yoked_church_app/features/volunteering/application/volunteering_providers.dart';
import 'package:yoked_church_app/features/volunteering/data/volunteering_repository.dart';
import 'package:yoked_church_app/features/volunteering/domain/volunteering.dart';

/// Pure in-memory repositories for tests.
///
/// These reuse [LocalCrudRepository] with no seed asset, so tests exercise
/// the same base class the app's zero-backend mode uses - and never touch
/// Firebase, the network, or the asset bundle.
class FakeSettingsRepository implements SettingsRepository {
  ChurchSettings settings;

  FakeSettingsRepository([ChurchSettings? initial]) : settings = initial ?? testSettings();

  @override
  Future<ChurchSettings> fetch() async => settings;

  @override
  Stream<ChurchSettings> watch() => Stream.value(settings);

  @override
  Future<void> save(ChurchSettings value) async => settings = value;
}

class FakeSermonRepository extends LocalCrudRepository<Sermon> implements SermonRepository {
  @override
  Sermon fromMap(String id, Map<String, dynamic> map) => Sermon.fromMap(id, map);
  @override
  Map<String, dynamic> toMap(Sermon entity) => entity.toMap();
  @override
  String idOf(Sermon entity) => entity.id;
  @override
  int Function(Sermon, Sermon)? get sorter => (a, b) => b.date.compareTo(a.date);
}

class FakeSermonSeriesRepository extends LocalCrudRepository<SermonSeries> implements SermonSeriesRepository {
  @override
  SermonSeries fromMap(String id, Map<String, dynamic> map) => SermonSeries.fromMap(id, map);
  @override
  Map<String, dynamic> toMap(SermonSeries entity) => entity.toMap();
  @override
  String idOf(SermonSeries entity) => entity.id;
}

class FakeEventRepository extends LocalCrudRepository<ChurchEvent> implements EventRepository {
  @override
  ChurchEvent fromMap(String id, Map<String, dynamic> map) => ChurchEvent.fromMap(id, map);
  @override
  Map<String, dynamic> toMap(ChurchEvent entity) => entity.toMap();
  @override
  String idOf(ChurchEvent entity) => entity.id;
  @override
  int Function(ChurchEvent, ChurchEvent)? get sorter => (a, b) => a.start.compareTo(b.start);
}

class FakeConnectRepository extends LocalCrudRepository<ConnectSubmission> implements ConnectRepository {
  @override
  ConnectSubmission fromMap(String id, Map<String, dynamic> map) => ConnectSubmission.fromMap(id, map);
  @override
  Map<String, dynamic> toMap(ConnectSubmission entity) => entity.toMap();
  @override
  String idOf(ConnectSubmission entity) => entity.id;
}

class FakeStaffRepository extends LocalCrudRepository<StaffMember> implements StaffRepository {
  @override
  StaffMember fromMap(String id, Map<String, dynamic> map) => StaffMember.fromMap(id, map);
  @override
  Map<String, dynamic> toMap(StaffMember entity) => entity.toMap();
  @override
  String idOf(StaffMember entity) => entity.id;
}

class FakeLocationRepository extends LocalCrudRepository<ChurchLocation> implements LocationRepository {
  @override
  ChurchLocation fromMap(String id, Map<String, dynamic> map) => ChurchLocation.fromMap(id, map);
  @override
  Map<String, dynamic> toMap(ChurchLocation entity) => entity.toMap();
  @override
  String idOf(ChurchLocation entity) => entity.id;
}

class FakeFaqRepository extends LocalCrudRepository<Faq> implements FaqRepository {
  @override
  Faq fromMap(String id, Map<String, dynamic> map) => Faq.fromMap(id, map);
  @override
  Map<String, dynamic> toMap(Faq entity) => entity.toMap();
  @override
  String idOf(Faq entity) => entity.id;
}

ChurchSettings testSettings({
  String churchName = 'Test Church',
  FeatureFlags? features,
  // Non-empty by default so the /download route is open unless a test
  // deliberately clears it - otherwise the feature-flag test would pass
  // for the wrong reason, the route being shut either way.
  String releasesRepo = 'test-church/test-app',
}) =>
    ChurchSettings(
      churchName: churchName,
      releasesRepo: releasesRepo,
      tagline: 'A tagline',
      aboutHeadline: 'Welcome Home',
      aboutBody: 'About body copy.',
      colors: BrandColors.fallback,
      contact: const ContactInfo(
        address: '1 Test St',
        phone: '(555) 000-0000',
        email: 'test@example.org',
        mapUrl: '',
      ),
      social: const SocialLinks(
        facebook: '',
        instagram: '',
        youtube: '',
        givingUrl: 'https://example.org/give',
        liveStreamUrl: '',
      ),
      serviceTimes: const [ServiceTime(day: 'Sunday', time: '9:00 AM', label: 'Morning')],
      features: features ?? const FeatureFlags(),
    );

class FakeGroupRepository extends LocalCrudRepository<ChurchGroup> implements GroupRepository {
  @override
  ChurchGroup fromMap(String id, Map<String, dynamic> map) => ChurchGroup.fromMap(id, map);
  @override
  Map<String, dynamic> toMap(ChurchGroup entity) => entity.toMap();
  @override
  String idOf(ChurchGroup entity) => entity.id;
}

class FakeMembershipRepository extends LocalCrudRepository<GroupMembership> implements MembershipRepository {
  @override
  GroupMembership fromMap(String id, Map<String, dynamic> map) => GroupMembership.fromMap(id, map);
  @override
  Map<String, dynamic> toMap(GroupMembership entity) => entity.toMap();
  @override
  String idOf(GroupMembership entity) => entity.id;
  @override
  Future<List<GroupMembership>> forMember(String uid) => fetchWhere((m) => m.uid == uid);
  @override
  Future<List<GroupMembership>> forGroup(String groupId) => fetchWhere((m) => m.groupId == groupId);
}

class FakeRsvpRepository extends LocalCrudRepository<EventRsvp> implements RsvpRepository {
  @override
  EventRsvp fromMap(String id, Map<String, dynamic> map) => EventRsvp.fromMap(id, map);
  @override
  Map<String, dynamic> toMap(EventRsvp entity) => entity.toMap();
  @override
  String idOf(EventRsvp entity) => entity.id;
  @override
  Future<List<EventRsvp>> forMember(String uid) => fetchWhere((r) => r.uid == uid);
  @override
  Future<List<EventRsvp>> forEvent(String eventId) => fetchWhere((r) => r.eventId == eventId);
  @override
  Future<void> setRsvp(EventRsvp rsvp) => update(EventRsvp(
        id: rsvpId(rsvp.eventId, rsvp.uid),
        eventId: rsvp.eventId,
        uid: rsvp.uid,
        memberName: rsvp.memberName,
        partySize: rsvp.partySize,
        respondedAt: rsvp.respondedAt,
      ));
  @override
  Future<void> cancel({required String eventId, required String uid}) => delete(rsvpId(eventId, uid));
}

class FakeVolunteerPositionRepository extends LocalCrudRepository<VolunteerPosition>
    implements VolunteerPositionRepository {
  @override
  VolunteerPosition fromMap(String id, Map<String, dynamic> map) => VolunteerPosition.fromMap(id, map);
  @override
  Map<String, dynamic> toMap(VolunteerPosition entity) => entity.toMap();
  @override
  String idOf(VolunteerPosition entity) => entity.id;
}

class FakeVolunteerAssignmentRepository extends LocalCrudRepository<VolunteerAssignment>
    implements VolunteerAssignmentRepository {
  @override
  VolunteerAssignment fromMap(String id, Map<String, dynamic> map) => VolunteerAssignment.fromMap(id, map);
  @override
  Map<String, dynamic> toMap(VolunteerAssignment entity) => entity.toMap();
  @override
  String idOf(VolunteerAssignment entity) => entity.id;
  @override
  Future<List<VolunteerAssignment>> forMember(String uid) => fetchWhere((a) => a.uid == uid);
  @override
  Future<List<VolunteerAssignment>> forPosition(String id) => fetchWhere((a) => a.positionId == id);
  @override
  Future<List<VolunteerAssignment>> forPositions(List<String> ids) =>
      fetchWhere((a) => ids.contains(a.positionId));
}

class FakeNotificationRepository extends LocalCrudRepository<AppNotification>
    implements NotificationRepository {
  @override
  AppNotification fromMap(String id, Map<String, dynamic> map) => AppNotification.fromMap(id, map);
  @override
  Map<String, dynamic> toMap(AppNotification entity) => entity.toMap();
  @override
  String idOf(AppNotification entity) => entity.id;
  @override
  Stream<List<AppNotification>> watchForMember(String uid) =>
      watchDerived(() => fetchWhere((n) => n.uid == uid));

  @override
  Future<void> markRead(String id) async {
    final existing = await fetchById(id);
    if (existing != null) await update(existing.copyWith(read: true));
  }
}

class FakeGivingRepository extends LocalCrudRepository<GivingRecord> implements GivingRepository {
  @override
  GivingRecord fromMap(String id, Map<String, dynamic> map) => GivingRecord.fromMap(id, map);
  @override
  Map<String, dynamic> toMap(GivingRecord entity) => entity.toMap();
  @override
  String idOf(GivingRecord entity) => entity.id;
  @override
  Future<List<GivingRecord>> forMember(String uid) => fetchWhere((r) => r.uid == uid);
}

class FakeUserRepository extends LocalCrudRepository<AppUser> implements UserRepository {
  @override
  AppUser fromMap(String id, Map<String, dynamic> map) => AppUser.fromMap(id, map);
  @override
  Map<String, dynamic> toMap(AppUser entity) => entity.toMap();
  @override
  String idOf(AppUser entity) => entity.uid;
  @override
  Future<List<AppUser>> fetchDirectory() => fetchWhere((u) => u.directoryOptIn);
  @override
  Future<void> updateRole(String uid, UserRole role) async {
    final user = await fetchById(uid);
    if (user != null) await update(user.copyWith(role: role));
  }
}

class FakeAnnouncementRepository extends LocalCrudRepository<Announcement>
    implements AnnouncementRepository {
  @override
  Announcement fromMap(String id, Map<String, dynamic> map) => Announcement.fromMap(id, map);
  @override
  Map<String, dynamic> toMap(Announcement entity) => entity.toMap();
  @override
  String idOf(Announcement entity) => entity.id;
  @override
  int Function(Announcement, Announcement)? get sorter => (a, b) => b.sentAt.compareTo(a.sentAt);
}

class FakeDevotionalRepository extends LocalCrudRepository<Devotional> implements DevotionalRepository {
  @override
  Devotional fromMap(String id, Map<String, dynamic> map) => Devotional.fromMap(id, map);
  @override
  Map<String, dynamic> toMap(Devotional entity) => entity.toMap();
  @override
  String idOf(Devotional entity) => entity.id;
  @override
  int Function(Devotional, Devotional)? get sorter => (a, b) => b.publishDate.compareTo(a.publishDate);
}

class FakeReadingPlanRepository extends LocalCrudRepository<ReadingPlan> implements ReadingPlanRepository {
  @override
  ReadingPlan fromMap(String id, Map<String, dynamic> map) => ReadingPlan.fromMap(id, map);
  @override
  Map<String, dynamic> toMap(ReadingPlan entity) => entity.toMap();
  @override
  String idOf(ReadingPlan entity) => entity.id;
  @override
  int Function(ReadingPlan, ReadingPlan)? get sorter => (a, b) => a.title.compareTo(b.title);
}

class FakePlanProgressRepository extends LocalCrudRepository<PlanProgress>
    implements PlanProgressRepository {
  @override
  PlanProgress fromMap(String id, Map<String, dynamic> map) => PlanProgress.fromMap(id, map);
  @override
  Map<String, dynamic> toMap(PlanProgress entity) => entity.toMap();
  @override
  String idOf(PlanProgress entity) => entity.id;
  @override
  Future<List<PlanProgress>> forMember(String uid) => fetchWhere((p) => p.uid == uid);
  @override
  Future<void> setProgress(PlanProgress progress) => update(PlanProgress(
        id: progressId(progress.planId, progress.uid),
        uid: progress.uid,
        planId: progress.planId,
        completedDays: progress.completedDays,
        startedAt: progress.startedAt,
        lastReadAt: progress.lastReadAt,
      ));
}

class FakeSermonNoteRepository extends LocalCrudRepository<SermonNote> implements SermonNoteRepository {
  @override
  SermonNote fromMap(String id, Map<String, dynamic> map) => SermonNote.fromMap(id, map);
  @override
  Map<String, dynamic> toMap(SermonNote entity) => entity.toMap();
  @override
  String idOf(SermonNote entity) => entity.id;
  @override
  int Function(SermonNote, SermonNote)? get sorter => (a, b) => b.updatedAt.compareTo(a.updatedAt);
  @override
  Future<List<SermonNote>> forMember(String uid) => fetchWhere((n) => n.uid == uid);
  @override
  Future<void> setNote(SermonNote note) => update(SermonNote(
        id: sermonNoteId(note.sermonId, note.uid),
        uid: note.uid,
        sermonId: note.sermonId,
        sermonTitle: note.sermonTitle,
        sermonDate: note.sermonDate,
        body: note.body,
        updatedAt: note.updatedAt,
      ));
}

class FakeResourceRepository extends LocalCrudRepository<Resource> implements ResourceRepository {
  @override
  Resource fromMap(String id, Map<String, dynamic> map) => Resource.fromMap(id, map);
  @override
  Map<String, dynamic> toMap(Resource entity) => entity.toMap();
  @override
  String idOf(Resource entity) => entity.id;
  @override
  int Function(Resource, Resource)? get sorter => (a, b) => b.createdAt.compareTo(a.createdAt);
}

/// In-memory storage that records what it was asked to do, so the upload
/// path is testable without Firebase. Set [failWith] to exercise the
/// error branch.
class FakeFileStorage implements FileStorage {
  final Map<String, Uint8List> stored = {};
  final List<String> deleted = [];
  final bool uploadsSupported;
  String? failWith;

  FakeFileStorage({this.uploadsSupported = true});

  @override
  bool get supportsUpload => uploadsSupported;

  @override
  Future<String> upload({
    required String path,
    required Uint8List bytes,
    required String contentType,
  }) async {
    if (failWith != null) throw UploadFailure(failWith!);
    stored[path] = bytes;
    return 'https://files.example.org/$path';
  }

  @override
  Future<void> deleteAt(String url) async => deleted.add(url);
}

class FakePrayerPostRepository extends LocalCrudRepository<PrayerPost> implements PrayerPostRepository {
  @override
  PrayerPost fromMap(String id, Map<String, dynamic> map) => PrayerPost.fromMap(id, map);
  @override
  Map<String, dynamic> toMap(PrayerPost entity) => entity.toMap();
  @override
  String idOf(PrayerPost entity) => entity.id;
  @override
  int Function(PrayerPost, PrayerPost)? get sorter => (a, b) => b.createdAt.compareTo(a.createdAt);
}

class FakeIntercessionRepository extends LocalCrudRepository<PrayerIntercession>
    implements IntercessionRepository {
  @override
  PrayerIntercession fromMap(String id, Map<String, dynamic> map) => PrayerIntercession.fromMap(id, map);
  @override
  Map<String, dynamic> toMap(PrayerIntercession entity) => entity.toMap();
  @override
  String idOf(PrayerIntercession entity) => entity.id;
  @override
  Future<List<PrayerIntercession>> forMember(String uid) => fetchWhere((i) => i.uid == uid);
  @override
  Future<List<PrayerIntercession>> forPosts(List<String> ids) => fetchWhere((i) => ids.contains(i.postId));
  @override
  Future<void> pray(PrayerIntercession intercession) => update(PrayerIntercession(
        id: intercessionId(intercession.postId, intercession.uid),
        postId: intercession.postId,
        uid: intercession.uid,
        prayedAt: intercession.prayedAt,
      ));
  @override
  Future<void> unpray({required String postId, required String uid}) =>
      delete(intercessionId(postId, uid));
}

class FakeRoomRepository extends LocalCrudRepository<Room> implements RoomRepository {
  @override
  Room fromMap(String id, Map<String, dynamic> map) => Room.fromMap(id, map);
  @override
  Map<String, dynamic> toMap(Room entity) => entity.toMap();
  @override
  String idOf(Room entity) => entity.id;
  @override
  int Function(Room, Room)? get sorter => (a, b) => a.name.compareTo(b.name);
}

class FakeBookingRepository extends LocalCrudRepository<RoomBooking> implements BookingRepository {
  @override
  RoomBooking fromMap(String id, Map<String, dynamic> map) => RoomBooking.fromMap(id, map);
  @override
  Map<String, dynamic> toMap(RoomBooking entity) => entity.toMap();
  @override
  String idOf(RoomBooking entity) => entity.id;
  @override
  int Function(RoomBooking, RoomBooking)? get sorter => (a, b) => a.start.compareTo(b.start);
  @override
  Future<List<RoomBooking>> forMember(String uid) => fetchWhere((b) => b.requestedByUid == uid);
  @override
  Future<List<RoomBooking>> forRoom(String roomId) => fetchWhere((b) => b.roomId == roomId);
}

class FakeCheckInRepository extends LocalCrudRepository<CheckInSession> implements CheckInRepository {
  @override
  CheckInSession fromMap(String id, Map<String, dynamic> map) => CheckInSession.fromMap(id, map);
  @override
  Map<String, dynamic> toMap(CheckInSession entity) => entity.toMap();
  @override
  String idOf(CheckInSession entity) => entity.id;
  @override
  int Function(CheckInSession, CheckInSession)? get sorter =>
      (a, b) => b.checkedInAt.compareTo(a.checkedInAt);
  @override
  Future<List<CheckInSession>> forGuardian(String uid) => fetchWhere((s) => s.guardianUid == uid);
  @override
  Future<List<CheckInSession>> forRoom(String roomId) => fetchWhere((s) => s.roomId == roomId);
}

class FakeAttendanceRepository extends LocalCrudRepository<AttendanceRecord>
    implements AttendanceRepository {
  @override
  AttendanceRecord fromMap(String id, Map<String, dynamic> map) => AttendanceRecord.fromMap(id, map);
  @override
  Map<String, dynamic> toMap(AttendanceRecord entity) => entity.toMap();
  @override
  String idOf(AttendanceRecord entity) => entity.id;
  @override
  int Function(AttendanceRecord, AttendanceRecord)? get sorter => (a, b) => b.date.compareTo(a.date);
  @override
  Future<List<AttendanceRecord>> forGathering(String gatheringId) =>
      fetchWhere((r) => r.gatheringId == gatheringId);
  @override
  Future<void> setRecord(AttendanceRecord record) => update(AttendanceRecord(
        id: attendanceId(record.gatheringType, record.gatheringId, record.date),
        gatheringType: record.gatheringType,
        gatheringId: record.gatheringId,
        gatheringName: record.gatheringName,
        date: record.date,
        headcount: record.headcount,
        presentUids: record.presentUids,
        note: record.note,
        recordedBy: record.recordedBy,
      ));
}

class FakeFormRepository extends LocalCrudRepository<FormDefinition> implements FormRepository {
  @override
  FormDefinition fromMap(String id, Map<String, dynamic> map) => FormDefinition.fromMap(id, map);
  @override
  Map<String, dynamic> toMap(FormDefinition entity) => entity.toMap();
  @override
  String idOf(FormDefinition entity) => entity.id;
  @override
  int Function(FormDefinition, FormDefinition)? get sorter => (a, b) => a.title.compareTo(b.title);
  @override
  Future<FormDefinition?> bySlug(String slug) async {
    final matches = await fetchWhere((f) => f.slug == slug);
    return matches.isEmpty ? null : matches.first;
  }
}

class FakeSubmissionRepository extends LocalCrudRepository<FormSubmission>
    implements SubmissionRepository {
  @override
  FormSubmission fromMap(String id, Map<String, dynamic> map) => FormSubmission.fromMap(id, map);
  @override
  Map<String, dynamic> toMap(FormSubmission entity) => entity.toMap();
  @override
  String idOf(FormSubmission entity) => entity.id;
  @override
  int Function(FormSubmission, FormSubmission)? get sorter =>
      (a, b) => b.submittedAt.compareTo(a.submittedAt);
  @override
  Future<List<FormSubmission>> forForm(String formId) => fetchWhere((s) => s.formId == formId);
}

class FakeAuditRepository extends LocalCrudRepository<AuditEntry> implements AuditRepository {
  @override
  AuditEntry fromMap(String id, Map<String, dynamic> map) => AuditEntry.fromMap(id, map);
  @override
  Map<String, dynamic> toMap(AuditEntry entity) => entity.toMap();
  @override
  String idOf(AuditEntry entity) => entity.id;
  @override
  int Function(AuditEntry, AuditEntry)? get sorter => (a, b) => b.at.compareTo(a.at);
}

/// A complete override set backed by fakes, optionally pre-seeded.
///
/// Pass [signedInAs] to start the test with an authenticated member -
/// every screen behind the auth guard is reachable without any Firebase.
List<Override> fakeOverrides({
  ChurchSettings? settings,
  AppUser? signedInAs,
  List<Sermon> sermons = const [],
  List<SermonSeries> series = const [],
  List<ChurchEvent> events = const [],
  List<StaffMember> staff = const [],
  List<ChurchLocation> locations = const [],
  List<Faq> faqs = const [],
  List<ChurchGroup> groups = const [],
  List<GroupMembership> memberships = const [],
  List<VolunteerPosition> positions = const [],
  List<VolunteerAssignment> assignments = const [],
  List<AppNotification> notifications = const [],
  List<GivingRecord> giving = const [],
  List<AppUser> members = const [],
  List<Devotional> devotionals = const [],
  List<ReadingPlan> readingPlans = const [],
  List<PlanProgress> planProgress = const [],
  List<SermonNote> sermonNotes = const [],
  List<Resource> resources = const [],
  List<PrayerPost> prayerPosts = const [],
  List<PrayerIntercession> intercessions = const [],
  List<Room> rooms = const [],
  List<RoomBooking> bookings = const [],
  List<CheckInSession> checkIns = const [],
  List<AttendanceRecord> attendance = const [],
  List<FormDefinition> forms = const [],
  List<FormSubmission> submissions = const [],
  FakeFileStorage? storage,
  FakeConnectRepository? connect,
  FakeRsvpRepository? rsvps,
  FakeVolunteerAssignmentRepository? assignmentRepo,
  /// Which church the app is acting as.
  ///
  /// Defaulted rather than required: almost every test is about one
  /// church's behaviour and should not have to say so. Pass null to get
  /// the state a member is in before they have chosen one, which is what
  /// sends them to the picker.
  String? churchId = demoChurchId,
}) {
  final connectRepo = connect ?? FakeConnectRepository()
    ..seedInMemory(const []);
  final rsvpRepo = rsvps ?? FakeRsvpRepository()
    ..seedInMemory(const []);
  final assignRepo = assignmentRepo ?? FakeVolunteerAssignmentRepository()
    ..seedInMemory(assignments);

  return [
    selectedChurchIdProvider.overrideWith((ref) => churchId),
    churchDirectoryProvider.overrideWithValue(LocalChurchDirectoryRepository()),
    settingsRepositoryProvider.overrideWithValue(FakeSettingsRepository(settings)),
    authRepositoryProvider.overrideWithValue(FakeAuthRepository(signedInAs)),
    userRepositoryProvider.overrideWithValue(FakeUserRepository()..seedInMemory(members)),
    sermonRepositoryProvider.overrideWithValue(FakeSermonRepository()..seedInMemory(sermons)),
    sermonSeriesRepositoryProvider.overrideWithValue(FakeSermonSeriesRepository()..seedInMemory(series)),
    eventRepositoryProvider.overrideWithValue(FakeEventRepository()..seedInMemory(events)),
    rsvpRepositoryProvider.overrideWithValue(rsvpRepo),
    connectRepositoryProvider.overrideWithValue(connectRepo),
    staffRepositoryProvider.overrideWithValue(FakeStaffRepository()..seedInMemory(staff)),
    locationRepositoryProvider.overrideWithValue(FakeLocationRepository()..seedInMemory(locations)),
    faqRepositoryProvider.overrideWithValue(FakeFaqRepository()..seedInMemory(faqs)),
    groupRepositoryProvider.overrideWithValue(FakeGroupRepository()..seedInMemory(groups)),
    membershipRepositoryProvider.overrideWithValue(FakeMembershipRepository()..seedInMemory(memberships)),
    volunteerPositionRepositoryProvider
        .overrideWithValue(FakeVolunteerPositionRepository()..seedInMemory(positions)),
    volunteerAssignmentRepositoryProvider.overrideWithValue(assignRepo),
    notificationRepositoryProvider
        .overrideWithValue(FakeNotificationRepository()..seedInMemory(notifications)),
    givingRepositoryProvider.overrideWithValue(FakeGivingRepository()..seedInMemory(giving)),
    announcementRepositoryProvider
        .overrideWithValue(FakeAnnouncementRepository()..seedInMemory(const [])),
    auditRepositoryProvider.overrideWithValue(FakeAuditRepository()..seedInMemory(const [])),
    devotionalRepositoryProvider.overrideWithValue(FakeDevotionalRepository()..seedInMemory(devotionals)),
    readingPlanRepositoryProvider.overrideWithValue(FakeReadingPlanRepository()..seedInMemory(readingPlans)),
    planProgressRepositoryProvider
        .overrideWithValue(FakePlanProgressRepository()..seedInMemory(planProgress)),
    sermonNoteRepositoryProvider.overrideWithValue(FakeSermonNoteRepository()..seedInMemory(sermonNotes)),
    resourceRepositoryProvider.overrideWithValue(FakeResourceRepository()..seedInMemory(resources)),
    fileStorageProvider.overrideWithValue(storage ?? FakeFileStorage()),
    prayerPostRepositoryProvider.overrideWithValue(FakePrayerPostRepository()..seedInMemory(prayerPosts)),
    intercessionRepositoryProvider
        .overrideWithValue(FakeIntercessionRepository()..seedInMemory(intercessions)),
    roomRepositoryProvider.overrideWithValue(FakeRoomRepository()..seedInMemory(rooms)),
    bookingRepositoryProvider.overrideWithValue(FakeBookingRepository()..seedInMemory(bookings)),
    checkInRepositoryProvider.overrideWithValue(FakeCheckInRepository()..seedInMemory(checkIns)),
    attendanceRepositoryProvider.overrideWithValue(FakeAttendanceRepository()..seedInMemory(attendance)),
    formRepositoryProvider.overrideWithValue(FakeFormRepository()..seedInMemory(forms)),
    submissionRepositoryProvider.overrideWithValue(FakeSubmissionRepository()..seedInMemory(submissions)),
  ];
}

Resource testResource({
  String id = 'r1',
  String title = 'Test Resource',
  String description = 'A resource for testing.',
  String category = 'Forms',
  String url = 'https://example.org/thing.pdf',
  String fileName = 'thing.pdf',
  String storagePath = '',
  bool membersOnly = false,
  DateTime? createdAt,
}) =>
    Resource(
      id: id,
      title: title,
      description: description,
      category: category,
      url: url,
      fileName: fileName,
      storagePath: storagePath,
      membersOnly: membersOnly,
      createdAt: createdAt ?? DateTime(2026, 7, 1),
    );

ReadingPlan testPlan({
  String id = 'p1',
  String title = 'Test Plan',
  String description = 'A plan for testing.',
  int days = 3,
  bool published = true,
}) =>
    ReadingPlan(
      id: id,
      title: title,
      description: description,
      published: published,
      days: [
        for (var i = 1; i <= days; i++) ReadingDay(dayNumber: i, reference: 'John $i:1-10'),
      ],
    );

Devotional testDevotional({
  String id = 'd1',
  String title = 'Test Devotional',
  String body = 'Body copy for the devotional.',
  String scripture = 'Psalm 23:1',
  String author = 'Pastor Test',
  DateTime? publishDate,
  bool published = true,
}) =>
    Devotional(
      id: id,
      title: title,
      body: body,
      scripture: scripture,
      author: author,
      publishDate: publishDate ?? DateTime(2026, 7, 1),
      published: published,
    );

/// Auth fake that can start signed-in and supports sign-out/sign-in.
class FakeAuthRepository implements AuthRepository {
  final _controller = StreamController<AppUser?>.broadcast();
  AppUser? _current;

  FakeAuthRepository([this._current]);

  @override
  bool get supportsSocialSignIn => true;
  @override
  bool get isDemo => false;

  @override
  Stream<AppUser?> authStateChanges() async* {
    yield _current;
    yield* _controller.stream;
  }

  void _emit(AppUser? user) {
    _current = user;
    _controller.add(user);
  }

  @override
  Future<void> signIn({required String email, required String password}) async {
    if (password == 'wrong') throw const AuthFailure("We couldn't sign you in with that email and password.");
    _emit(testMember(email: email));
  }

  @override
  Future<void> signUp({required String email, required String password, required String displayName}) async =>
      _emit(testMember(email: email, displayName: displayName));

  @override
  Future<void> signInWithGoogle() async => _emit(testMember());
  @override
  Future<void> signInWithApple() async => _emit(testMember());
  @override
  Future<void> sendPasswordReset(String email) async {}
  @override
  Future<void> signOut() async => _emit(null);
  @override
  Future<void> signInAsDemo(UserRole role) async => _emit(testMember(role: role));
}

AppUser testMember({
  String uid = 'u1',
  String email = 'member@example.org',
  String displayName = 'Test Member',
  UserRole role = UserRole.member,
  bool directoryOptIn = false,
}) =>
    AppUser(
      uid: uid,
      email: email,
      displayName: displayName,
      role: role,
      directoryOptIn: directoryOptIn,
      createdAt: DateTime(2025, 1, 1),
    );

Sermon testSermon({
  String id = 's1',
  String title = 'Test Sermon',
  String speaker = 'Pastor Test',
  String seriesId = '',
  String seriesName = '',
  String scripture = '',
  DateTime? date,
  bool published = true,
}) =>
    Sermon(
      id: id,
      title: title,
      speaker: speaker,
      date: date ?? DateTime(2026, 7, 19),
      seriesId: seriesId,
      seriesName: seriesName,
      scripture: scripture,
      published: published,
    );

ChurchEvent testEvent({
  String id = 'e1',
  String title = 'Test Event',
  DateTime? start,
  String location = 'Main Hall',
}) =>
    ChurchEvent(
      id: id,
      title: title,
      start: start ?? DateTime.now().add(const Duration(days: 7)),
      location: location,
    );
