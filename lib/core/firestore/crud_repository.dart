import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart' show rootBundle;

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
  bool _seeded = false;
  int _nextId = 0;

  Future<void> _ensureSeeded() async {
    if (_seeded) return;
    _seeded = true;
    final asset = seedAsset;
    if (asset == null) return;
    try {
      final raw = await rootBundle.loadString(asset);
      final decoded = jsonDecode(raw) as List<dynamic>;
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
  Stream<List<T>> watchAll() async* {
    yield await fetchAll();
  }

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
    return id;
  }

  @override
  Future<void> update(T entity) async {
    await _ensureSeeded();
    final id = idOf(entity);
    _items[id] = entity;
  }

  @override
  Future<void> delete(String id) async {
    await _ensureSeeded();
    _items.remove(id);
  }

  Future<List<T>> fetchWhere(bool Function(T item) test) async {
    await _ensureSeeded();
    return _sorted().where(test).toList();
  }

  /// Lets tests seed deterministic data without touching asset bundles.
  void seedInMemory(Iterable<T> entities) {
    _seeded = true;
    for (final entity in entities) {
      final id = idOf(entity).isEmpty ? 'local-${_nextId++}' : idOf(entity);
      _items[id] = entity;
    }
  }
}
