import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../domain/church_slug.dart';
import '../domain/church_summary.dart';

/// The list of churches a member can choose between.
///
/// The one repository in the app that is *not* scoped to a church, for
/// the obvious reason: it is what you use before you have one.
abstract interface class ChurchDirectoryRepository {
  Future<List<ChurchSummary>> fetchAll();
  Future<ChurchSummary?> fetchById(String id);

  /// Creates a church and makes the signed-in account its admin.
  ///
  /// Returns the id it was actually given, which may not be the one
  /// asked for: two churches called Grace Chapel is not an edge case,
  /// and the second one becomes `grace-chapel-2` rather than being
  /// turned away.
  ///
  /// Throws [ChurchCreationFailure] with something worth showing a
  /// person - this is the first thing a new customer ever does, and
  /// "unknown error" at that moment is the end of the relationship.
  Future<String> create({required String name, required String desiredSlug});
}

/// A signup that could not go through, carrying a message safe to show.
class ChurchCreationFailure implements Exception {
  final String message;

  const ChurchCreationFailure(this.message);

  @override
  String toString() => message;
}

/// Reads the bundled `assets/data/churches.json`.
///
/// Three churches with genuinely different names, colours and copy, so
/// the zero-backend build demonstrates the actual point of the picker -
/// choose a different church and the whole app re-themes - rather than
/// listing three names that all lead to the same site.
class LocalChurchDirectoryRepository implements ChurchDirectoryRepository {
  /// Static because a church created in this mode has to be visible to
  /// everything that looks one up - including [LocalSettingsRepository],
  /// which reads this same list to theme the app as that church. Held
  /// for the session, like every other write with no backend.
  static List<Map<String, dynamic>>? _cache;

  /// Forgets everything, including the bundled churches, so the next
  /// read loads the asset again.
  ///
  /// Only for tests: a static that survives between them turns "a church
  /// called Grace Chapel" into `grace-chapel-4` by the fourth test, and
  /// failures that depend on running order are worse than no test.
  @visibleForTesting
  static void reset() => _cache = null;

  static Future<List<Map<String, dynamic>>> load() async {
    if (_cache != null) return _cache!;
    try {
      final raw = await rootBundle.loadString('assets/data/churches.json');
      _cache = (jsonDecode(raw) as List<dynamic>)
          .whereType<Map<String, dynamic>>()
          .toList();
    } catch (_) {
      // A missing or malformed asset must not leave a member unable to
      // reach any church at all.
      _cache = const [];
    }
    return _cache!;
  }

  /// Whether this church came with the app rather than being created in
  /// it. Only the bundled ones get the bundled sample content.
  static Future<bool> isBundled(String churchId) async {
    for (final map in await load()) {
      if (map['id'] == churchId) return map['bundled'] != false;
    }
    return false;
  }

  @override
  Future<List<ChurchSummary>> fetchAll() async {
    final raw = await load();
    return [
      for (final map in raw) ChurchSummary.fromMap(map['id'] as String? ?? '', map),
    ];
  }

  @override
  Future<ChurchSummary?> fetchById(String id) async {
    final all = await fetchAll();
    for (final church in all) {
      if (church.id == id) return church;
    }
    return null;
  }

  /// Adds the church to the in-memory directory.
  ///
  /// Held for the session only, like every other write in this mode -
  /// which is enough to make the entire signup walkable with no backend
  /// at all: name a church, land in its empty admin, add a sermon, see
  /// it on its own public site.
  @override
  Future<String> create({required String name, required String desiredSlug}) async {
    final raw = await load();
    final id = availableSlug(desiredSlug, {for (final map in raw) map['id'] as String? ?? ''});

    _cache = [
      ...raw,
      // `bundled: false` is what keeps the sample sermons and the
      // sample unread messages out of a church somebody just made.
      {'id': id, 'churchName': name, 'bundled': false},
    ];
    return id;
  }
}

class FirestoreChurchDirectoryRepository implements ChurchDirectoryRepository {
  CollectionReference<Map<String, dynamic>> get _churches =>
      FirebaseFirestore.instance.collection('churches');

  @override
  Future<List<ChurchSummary>> fetchAll() async {
    // Ordered by name because the picker is a list a person scans for
    // their own church, not a ranking.
    final snapshot = await _churches.orderBy('churchName').get();
    return snapshot.docs.map((doc) => ChurchSummary.fromMap(doc.id, doc.data())).toList();
  }

  @override
  Future<ChurchSummary?> fetchById(String id) async {
    final doc = await _churches.doc(id).get();
    final data = doc.data();
    return data == null ? null : ChurchSummary.fromMap(doc.id, data);
  }

  /// Asks the server to do it.
  ///
  /// Deliberately not a client write. The rules keep
  /// `allow create: if false` on `churches/{churchId}` because creating
  /// a church also means writing yourself in as its admin, and a rule
  /// that permitted both would permit anyone to mint admin rights. The
  /// function holds the only path, so it can allocate the id without a
  /// race, cap how many one account may create, and seed the document
  /// in one transaction.
  @override
  Future<String> create({required String name, required String desiredSlug}) async {
    try {
      final callable = FirebaseFunctions.instance.httpsCallable('createChurch');
      final result = await callable.call<Map<String, dynamic>>({
        'name': name,
        'slug': desiredSlug,
      });
      final id = result.data['churchId'] as String?;
      if (id == null || id.isEmpty) {
        throw const ChurchCreationFailure('The server did not say which address it used.');
      }
      return id;
    } on FirebaseFunctionsException catch (e) {
      throw ChurchCreationFailure(churchCreationMessageFor(e));
    }
  }

}

///
/// Switched on the code rather than sniffing the message, because the
/// two sources of failure read completely differently. `createChurch`
/// raises its own refusals with sentences written for a person - a
/// name too short, an address taken, a cap reached - while the SDK
/// raises transport failures whose `message` is empty or a bare
/// `NOT_FOUND`.
///
/// Getting this wrong is expensive in the one place it happens: the
/// first thing a new customer ever does. "Please try again" in front
/// of a problem that retrying cannot fix costs someone their evening.
String churchCreationMessageFor(FirebaseFunctionsException e) {
  final written = e.message?.trim() ?? '';

  switch (e.code) {
    // Raised by the function itself, which already said something
    // useful. Only fall back if it somehow did not.
    case 'invalid-argument':
    case 'resource-exhausted':
    case 'unauthenticated':
      return written.isNotEmpty ? written : _generic;

    // The callable does not exist. Not a transient failure and not the
    // person's fault - the deploy has not happened - so it names the
    // command rather than suggesting a retry that can never work.
    case 'not-found':
      return 'Church signup is not switched on for this site yet. '
          'It needs the createChurch function deployed: '
          '`firebase deploy --only functions`.';

    case 'unavailable':
    case 'deadline-exceeded':
      return "We couldn't reach the server. Check your connection and try again.";

    case 'permission-denied':
      return 'The server refused that. If this keeps happening, the '
          "site's Firebase configuration needs a look.";

    default:
      return written.isNotEmpty ? written : _generic;
  }
}

const String _generic = "We couldn't set up your church just then. Please try again.";
