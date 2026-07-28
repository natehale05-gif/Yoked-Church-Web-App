import '../../../core/firestore/crud_repository.dart';
import '../domain/sermon_note.dart';

abstract interface class SermonNoteRepository implements CrudRepository<SermonNote> {
  Future<List<SermonNote>> forMember(String uid);

  /// Upsert under the deterministic id.
  Future<void> setNote(SermonNote note);
}

mixin _NoteCodec implements EntityCodec<SermonNote> {
  @override
  SermonNote fromMap(String id, Map<String, dynamic> map) => SermonNote.fromMap(id, map);
  @override
  Map<String, dynamic> toMap(SermonNote entity) => entity.toMap();
  @override
  String idOf(SermonNote entity) => entity.id;
}

class FirestoreSermonNoteRepository extends FirestoreCrudRepository<SermonNote>
    with _NoteCodec
    implements SermonNoteRepository {
  @override
  String get collectionPath => 'sermonNotes';

  @override
  Future<List<SermonNote>> forMember(String uid) => fetchWhere('uid', uid);

  @override
  Future<void> setNote(SermonNote note) =>
      collection.doc(sermonNoteId(note.sermonId, note.uid)).set(toMap(note));
}

class LocalSermonNoteRepository extends LocalCrudRepository<SermonNote>
    with _NoteCodec
    implements SermonNoteRepository {
  @override
  int Function(SermonNote, SermonNote)? get sorter => (a, b) => b.updatedAt.compareTo(a.updatedAt);

  @override
  Future<List<SermonNote>> forMember(String uid) => fetchWhere((n) => n.uid == uid);

  @override
  Future<void> setNote(SermonNote note) async {
    await update(SermonNote(
      id: sermonNoteId(note.sermonId, note.uid),
      uid: note.uid,
      sermonId: note.sermonId,
      sermonTitle: note.sermonTitle,
      sermonDate: note.sermonDate,
      body: note.body,
      updatedAt: note.updatedAt,
    ));
  }
}
