import '../../../core/firestore/crud_repository.dart';
import '../domain/announcement.dart';

abstract interface class AnnouncementRepository implements CrudRepository<Announcement> {}

mixin _AnnouncementCodec implements EntityCodec<Announcement> {
  @override
  Announcement fromMap(String id, Map<String, dynamic> map) => Announcement.fromMap(id, map);
  @override
  Map<String, dynamic> toMap(Announcement entity) => entity.toMap();
  @override
  String idOf(Announcement entity) => entity.id;
}

class FirestoreAnnouncementRepository extends FirestoreCrudRepository<Announcement>
    with _AnnouncementCodec
    implements AnnouncementRepository {
  FirestoreAnnouncementRepository(super.churchId);

  @override
  String get collectionPath => 'announcements';
  @override
  String? get orderByField => 'sentAt';
  @override
  bool get descending => true;
}

class LocalAnnouncementRepository extends LocalCrudRepository<Announcement>
    with _AnnouncementCodec
    implements AnnouncementRepository {
  LocalAnnouncementRepository([super.churchId]);

  @override
  String? get seedAsset => 'assets/data/announcements.json';

  @override
  int Function(Announcement, Announcement)? get sorter => (a, b) => b.sentAt.compareTo(a.sentAt);
}
