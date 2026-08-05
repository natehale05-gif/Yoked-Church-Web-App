import '../../../core/firestore/crud_repository.dart';
import '../domain/prayer_post.dart';

abstract interface class PrayerPostRepository implements CrudRepository<PrayerPost> {}

abstract interface class IntercessionRepository implements CrudRepository<PrayerIntercession> {
  Future<List<PrayerIntercession>> forMember(String uid);
  Future<List<PrayerIntercession>> forPosts(List<String> postIds);

  /// Idempotent by construction - the id is derived from post + member.
  Future<void> pray(PrayerIntercession intercession);
  Future<void> unpray({required String postId, required String uid});
}

mixin _PostCodec implements EntityCodec<PrayerPost> {
  @override
  PrayerPost fromMap(String id, Map<String, dynamic> map) => PrayerPost.fromMap(id, map);
  @override
  Map<String, dynamic> toMap(PrayerPost entity) => entity.toMap();
  @override
  String idOf(PrayerPost entity) => entity.id;
}

mixin _IntercessionCodec implements EntityCodec<PrayerIntercession> {
  @override
  PrayerIntercession fromMap(String id, Map<String, dynamic> map) => PrayerIntercession.fromMap(id, map);
  @override
  Map<String, dynamic> toMap(PrayerIntercession entity) => entity.toMap();
  @override
  String idOf(PrayerIntercession entity) => entity.id;
}

class FirestorePrayerPostRepository extends FirestoreCrudRepository<PrayerPost>
    with _PostCodec
    implements PrayerPostRepository {
  FirestorePrayerPostRepository(super.churchId);

  @override
  String get collectionPath => 'prayerPosts';
  @override
  String? get orderByField => 'createdAt';
  @override
  bool get descending => true;
}

class LocalPrayerPostRepository extends LocalCrudRepository<PrayerPost>
    with _PostCodec
    implements PrayerPostRepository {
  LocalPrayerPostRepository([super.churchId]);

  @override
  String? get seedAsset => 'assets/data/prayer_posts.json';
  @override
  int Function(PrayerPost, PrayerPost)? get sorter => (a, b) => b.createdAt.compareTo(a.createdAt);
}

class FirestoreIntercessionRepository extends FirestoreCrudRepository<PrayerIntercession>
    with _IntercessionCodec
    implements IntercessionRepository {
  FirestoreIntercessionRepository(super.churchId);

  @override
  String get collectionPath => 'prayerIntercessions';

  @override
  Future<List<PrayerIntercession>> forMember(String uid) => fetchWhere('uid', uid);

  @override
  Future<List<PrayerIntercession>> forPosts(List<String> postIds) => fetchWhereIn('postId', postIds);

  @override
  Future<void> pray(PrayerIntercession intercession) =>
      collection.doc(intercessionId(intercession.postId, intercession.uid)).set(toMap(intercession));

  @override
  Future<void> unpray({required String postId, required String uid}) =>
      collection.doc(intercessionId(postId, uid)).delete();
}

class LocalIntercessionRepository extends LocalCrudRepository<PrayerIntercession>
    with _IntercessionCodec
    implements IntercessionRepository {
  LocalIntercessionRepository([super.churchId]);

  @override
  String? get seedAsset => 'assets/data/prayer_intercessions.json';

  @override
  Future<List<PrayerIntercession>> forMember(String uid) => fetchWhere((i) => i.uid == uid);

  @override
  Future<List<PrayerIntercession>> forPosts(List<String> postIds) =>
      fetchWhere((i) => postIds.contains(i.postId));

  @override
  Future<void> pray(PrayerIntercession intercession) async {
    await update(PrayerIntercession(
      id: intercessionId(intercession.postId, intercession.uid),
      postId: intercession.postId,
      uid: intercession.uid,
      prayedAt: intercession.prayedAt,
    ));
  }

  @override
  Future<void> unpray({required String postId, required String uid}) =>
      delete(intercessionId(postId, uid));
}
