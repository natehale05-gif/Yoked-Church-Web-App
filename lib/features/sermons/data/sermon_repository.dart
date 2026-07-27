import '../../../core/firestore/crud_repository.dart';
import '../domain/sermon.dart';
import '../domain/sermon_series.dart';

abstract interface class SermonRepository implements CrudRepository<Sermon> {}

abstract interface class SermonSeriesRepository implements CrudRepository<SermonSeries> {}

mixin _SermonCodec implements EntityCodec<Sermon> {
  @override
  Sermon fromMap(String id, Map<String, dynamic> map) => Sermon.fromMap(id, map);
  @override
  Map<String, dynamic> toMap(Sermon entity) => entity.toMap();
  @override
  String idOf(Sermon entity) => entity.id;
}

mixin _SeriesCodec implements EntityCodec<SermonSeries> {
  @override
  SermonSeries fromMap(String id, Map<String, dynamic> map) => SermonSeries.fromMap(id, map);
  @override
  Map<String, dynamic> toMap(SermonSeries entity) => entity.toMap();
  @override
  String idOf(SermonSeries entity) => entity.id;
}

class FirestoreSermonRepository extends FirestoreCrudRepository<Sermon> with _SermonCodec implements SermonRepository {
  @override
  String get collectionPath => 'sermons';
  @override
  String? get orderByField => 'date';
  @override
  bool get descending => true;
}

class LocalSermonRepository extends LocalCrudRepository<Sermon> with _SermonCodec implements SermonRepository {
  @override
  String? get seedAsset => 'assets/data/sermons.json';
  @override
  int Function(Sermon, Sermon)? get sorter => (a, b) => b.date.compareTo(a.date);
}

class FirestoreSermonSeriesRepository extends FirestoreCrudRepository<SermonSeries>
    with _SeriesCodec
    implements SermonSeriesRepository {
  @override
  String get collectionPath => 'sermonSeries';
  @override
  String? get orderByField => 'startDate';
  @override
  bool get descending => true;
}

class LocalSermonSeriesRepository extends LocalCrudRepository<SermonSeries>
    with _SeriesCodec
    implements SermonSeriesRepository {
  @override
  String? get seedAsset => 'assets/data/sermon_series.json';
  @override
  int Function(SermonSeries, SermonSeries)? get sorter => (a, b) => b.startDate.compareTo(a.startDate);
}
