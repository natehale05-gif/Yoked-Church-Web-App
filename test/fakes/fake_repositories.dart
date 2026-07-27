import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yoked_church_app/core/config/church_settings.dart';
import 'package:yoked_church_app/core/config/settings_providers.dart';
import 'package:yoked_church_app/core/config/settings_repository.dart';
import 'package:yoked_church_app/core/firestore/crud_repository.dart';
import 'package:yoked_church_app/features/church_info/application/church_info_providers.dart';
import 'package:yoked_church_app/features/church_info/data/church_info_repository.dart';
import 'package:yoked_church_app/features/church_info/domain/church_info.dart';
import 'package:yoked_church_app/features/connect/application/connect_providers.dart';
import 'package:yoked_church_app/features/connect/data/connect_repository.dart';
import 'package:yoked_church_app/features/connect/domain/connect_submission.dart';
import 'package:yoked_church_app/features/events/application/event_providers.dart';
import 'package:yoked_church_app/features/events/data/event_repository.dart';
import 'package:yoked_church_app/features/events/domain/church_event.dart';
import 'package:yoked_church_app/features/sermons/application/sermon_providers.dart';
import 'package:yoked_church_app/features/sermons/data/sermon_repository.dart';
import 'package:yoked_church_app/features/sermons/domain/sermon.dart';
import 'package:yoked_church_app/features/sermons/domain/sermon_series.dart';

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

ChurchSettings testSettings({String churchName = 'Test Church', FeatureFlags? features}) => ChurchSettings(
      churchName: churchName,
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

/// A complete override set backed by fakes, optionally pre-seeded.
List<Override> fakeOverrides({
  ChurchSettings? settings,
  List<Sermon> sermons = const [],
  List<SermonSeries> series = const [],
  List<ChurchEvent> events = const [],
  List<StaffMember> staff = const [],
  List<ChurchLocation> locations = const [],
  List<Faq> faqs = const [],
  FakeConnectRepository? connect,
}) {
  final sermonRepo = FakeSermonRepository()..seedInMemory(sermons);
  final seriesRepo = FakeSermonSeriesRepository()..seedInMemory(series);
  final eventRepo = FakeEventRepository()..seedInMemory(events);
  final staffRepo = FakeStaffRepository()..seedInMemory(staff);
  final locationRepo = FakeLocationRepository()..seedInMemory(locations);
  final faqRepo = FakeFaqRepository()..seedInMemory(faqs);
  final connectRepo = connect ?? (FakeConnectRepository()..seedInMemory(const []));

  return [
    settingsRepositoryProvider.overrideWithValue(FakeSettingsRepository(settings)),
    sermonRepositoryProvider.overrideWithValue(sermonRepo),
    sermonSeriesRepositoryProvider.overrideWithValue(seriesRepo),
    eventRepositoryProvider.overrideWithValue(eventRepo),
    connectRepositoryProvider.overrideWithValue(connectRepo),
    staffRepositoryProvider.overrideWithValue(staffRepo),
    locationRepositoryProvider.overrideWithValue(locationRepo),
    faqRepositoryProvider.overrideWithValue(faqRepo),
  ];
}

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
