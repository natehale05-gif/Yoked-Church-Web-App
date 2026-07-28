import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_providers.dart';
import '../../sermons/domain/sermon.dart';
import '../data/sermon_note_repository.dart';
import '../domain/sermon_note.dart';

final sermonNoteRepositoryProvider = Provider<SermonNoteRepository>((ref) {
  throw UnimplementedError('sermonNoteRepositoryProvider must be overridden in ProviderScope');
});

final noteRefreshProvider = StateProvider<int>((ref) => 0);

/// This member's notes, newest first. Never anyone else's - the query is
/// scoped by uid here and by Firestore rules on the server.
final myNotesProvider = FutureProvider<List<SermonNote>>((ref) async {
  ref.watch(noteRefreshProvider);
  final uid = ref.watch(currentUserProvider)?.uid;
  if (uid == null) return const [];
  final notes = await ref.watch(sermonNoteRepositoryProvider).forMember(uid);
  return notes.where((n) => !n.isEmpty).toList();
});

final noteForSermonProvider = Provider.family<SermonNote?, String>((ref, sermonId) {
  final mine = ref.watch(myNotesProvider).valueOrNull ?? const <SermonNote>[];
  for (final note in mine) {
    if (note.sermonId == sermonId) return note;
  }
  return null;
});

final sermonNoteControllerProvider = Provider<SermonNoteController>((ref) => SermonNoteController(ref));

class SermonNoteController {
  final Ref _ref;

  SermonNoteController(this._ref);

  /// Save (or clear) this member's note on a sermon.
  ///
  /// An emptied note is deleted rather than stored blank, so "I cleared
  /// my notes" actually removes the record instead of leaving an empty
  /// one behind in the member's list.
  Future<void> save({required Sermon sermon, required String body}) async {
    final user = _ref.read(currentUserProvider);
    if (user == null) return;

    final repo = _ref.read(sermonNoteRepositoryProvider);
    final id = sermonNoteId(sermon.id, user.uid);

    if (body.trim().isEmpty) {
      if (await repo.fetchById(id) != null) await repo.delete(id);
    } else {
      await repo.setNote(SermonNote(
        uid: user.uid,
        sermonId: sermon.id,
        sermonTitle: sermon.title,
        sermonDate: sermon.date,
        body: body.trim(),
        updatedAt: DateTime.now(),
      ));
    }
    _ref.read(noteRefreshProvider.notifier).state++;
  }

  Future<void> delete(String sermonId) async {
    final user = _ref.read(currentUserProvider);
    if (user == null) return;
    await _ref.read(sermonNoteRepositoryProvider).delete(sermonNoteId(sermonId, user.uid));
    _ref.read(noteRefreshProvider.notifier).state++;
  }
}
