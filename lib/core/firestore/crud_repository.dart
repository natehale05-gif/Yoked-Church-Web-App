import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'sample_data.dart';

/// The read/write surface every content collection shares.
///
/// Features declare a narrow interface extending this (adding only their
/// own queries), and get both a Firestore and a local implementation for
/// free from the two base classes below. That is what makes the whole app
/// runnable - and unit-testable - with no backend.
abstract interface class CrudRepository<T> {
  Future<List<T>> fetchAll();
  Stream<List<T>> watchAll();
  Future<T?> fetchById(String id);
  Future<String> create(T entity);
  Future<void> update(T entity);
  Future<void> delete(String id);
}

/// Maps a domain entity to/from a Firestore document.
abstract mixin class EntityCodec<T> {
  T fromMap(String id, Map<String, dynamic> map);
  Map<String, dynamic> toMap(T entity);
  String idOf(T entity);
}

/// Firestore-backed CRUD. Subclasses supply the collection path, the
/// codec, and optionally a default ordering.
abstract class FirestoreCrudRepository<T> with EntityCodec<T> implements CrudRepository<T> {
  String get collectionPath;

  /// Field to order list reads by, if any.
  String? get orderByField => null;
  bool get descending => false;

  CollectionReference<Map<String, dynamic>> get collection =>
      FirebaseFirestore.instance.collection(collectionPath);

  Query<Map<String, dynamic>> get _ordered {
    final field = orderByField;
    return field == null ? collection : collection.orderBy(field, descending: descending);
  }

  List<T> _decode(QuerySnapshot<Map<String, dynamic>> snapshot) =>
      snapshot.docs.map((doc) => fromMap(doc.id, doc.data())).toList();

  @override
  Future<List<T>> fetchAll() async => _decode(await _ordered.get());

  @override
  Stream<List<T>> watchAll() => _ordered.snapshots().map(_decode);

  @override
  Future<T?> fetchById(String id) async {
    final doc = await collection.doc(id).get();
    final data = doc.data();
    return data == null ? null : fromMap(doc.id, data);
  }

  @override
  Future<String> create(T entity) async {
    final doc = await collection.add(toMap(entity));
    return doc.id;
  }

  @override
  Future<void> update(T entity) => collection.doc(idOf(entity)).update(toMap(entity));

  @override
  Future<void> delete(String id) => collection.doc(id).delete();

  /// Fetch documents matching a field - used instead of an N+1 loop when
  /// a screen needs related records for many parents at once.
  Future<List<T>> fetchWhere(String field, Object? value) async {
    final snapshot = await collection.where(field, isEqualTo: value).get();
    return _decode(snapshot);
  }

  /// Batched `whereIn` lookup that transparently chunks past Firestore's
  /// 30-value limit.
  Future<List<T>> fetchWhereIn(String field, List<Object?> values) async {
    if (values.isEmpty) return [];
    final results = <T>[];
    for (var i = 0; i < values.length; i += 30) {
      final chunk = values.sublist(i, i + 30 > values.length ? values.length : i + 30);
      results.addAll(_decode(await collection.where(field, whereIn: chunk).get()));
    }
    return results;
  }
}

/// In-memory CRUD seeded from a bundled JSON asset.
///
/// Reads come from `assets/data/<file>.json`; writes are kept in memory
/// for the session. This makes the zero-backend mode genuinely usable -
/// including the admin CMS, which in the previous architecture simply
/// failed without Firebase.
abstract class LocalCrudRepository<T> with EntityCodec<T> implements CrudRepository<T> {
  /// Asset to seed from, e.g. `assets/data/sermons.json`. Null seeds empty.
  String? get seedAsset => null;

  /// Sort applied to list reads, mirroring the Firestore ordering.
  int Function(T a, T b)? get sorter => null;

  final Map<String, T> _items = {};

  /// Ticks on every mutation so open [watchAll] subscriptions re-emit.
  /// Firestore's snapshot streams are live, and anything long-lived
  /// (the nav bar's notification bell, say) subscribes once at startup -
  /// without this, local mode would show those listeners a snapshot
  /// frozen at app launch.
  final StreamController<void> _changes = StreamController<void>.broadcast();

  /// The in-flight (or finished) seed load.
  ///
  /// Held as a future rather than a bool so concurrent first reads await
  /// the *same* load. A flag flipped before the `await` lets whichever
  /// read arrives second sail past an empty map - which is how a screen
  /// that watches a collection and looks one document up at the same
  /// time ends up reporting that the document does not exist.
  Future<void>? _seeding;

  int _nextId = 0;

  void _notifyChanged() {
    if (!_changes.isClosed) _changes.add(null);
  }

  /// Re-emits [read] on every mutation, starting with the current value.
  /// Feature repositories build their filtered watches on this.
  Stream<R> watchDerived<R>(Future<R> Function() read) async* {
    yield await read();
    yield* _changes.stream.asyncMap((_) => read());
  }

  Future<void> _ensureSeeded() => _seeding ??= _seed();

  Future<void> _seed() async {
    final asset = seedAsset;
    if (asset == null) return;
    try {
      final raw = await rootBundle.loadString(asset);
      // Read as relative to the day it was authored, not as absolute
      // dates. Without this the demo expires: the sign-up form closes,
      // the events page empties, and the reports fall to zero as real
      // time passes the hand-written dates by. See sample_data.dart.
      final decoded =
          rollSampleDates(jsonDecode(raw), sampleDataShift()) as List<dynamic>;
      for (final entry in decoded.whereType<Map<dynamic, dynamic>>()) {
        final id = 'local-${_nextId++}';
        _items[id] = fromMap(id, entry.cast<String, dynamic>());
      }
    } catch (_) {
      // Missing sample data is not fatal - the feature just shows empty.
    }
  }

  List<T> _sorted() {
    final list = _items.values.toList();
    final sort = sorter;
    if (sort != null) list.sort(sort);
    return list;
  }

  @override
  Future<List<T>> fetchAll() async {
    await _ensureSeeded();
    return _sorted();
  }

  @override
  Stream<List<T>> watchAll() => watchDerived(fetchAll);

  @override
  Future<T?> fetchById(String id) async {
    await _ensureSeeded();
    return _items[id];
  }

  @override
  Future<String> create(T entity) async {
    await _ensureSeeded();
    final id = 'local-${_nextId++}';
    _items[id] = fromMap(id, toMap(entity));
    _notifyChanged();
    return id;
  }

  @override
  Future<void> update(T entity) async {
    await _ensureSeeded();
    final id = idOf(entity);
    _items[id] = entity;
    _notifyChanged();
  }

  @override
  Future<void> delete(String id) async {
    await _ensureSeeded();
    _items.remove(id);
    _notifyChanged();
  }

  Future<List<T>> fetchWhere(bool Function(T item) test) async {
    await _ensureSeeded();
    return _sorted().where(test).toList();
  }

  /// Lets tests seed deterministic data without touching asset bundles.
  void seedInMemory(Iterable<T> entities) {
    _seeding = Future.value();
    for (final entity in entities) {
      final id = idOf(entity).isEmpty ? 'local-${_nextId++}' : idOf(entity);
      _items[id] = entity;
    }
    _notifyChanged();
  }
}
