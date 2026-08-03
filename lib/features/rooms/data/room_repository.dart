import '../../../core/firestore/crud_repository.dart';
import '../domain/room.dart';

abstract interface class RoomRepository implements CrudRepository<Room> {}

abstract interface class BookingRepository implements CrudRepository<RoomBooking> {
  Future<List<RoomBooking>> forMember(String uid);
  Future<List<RoomBooking>> forRoom(String roomId);
}

mixin _RoomCodec implements EntityCodec<Room> {
  @override
  Room fromMap(String id, Map<String, dynamic> map) => Room.fromMap(id, map);
  @override
  Map<String, dynamic> toMap(Room entity) => entity.toMap();
  @override
  String idOf(Room entity) => entity.id;
}

mixin _BookingCodec implements EntityCodec<RoomBooking> {
  @override
  RoomBooking fromMap(String id, Map<String, dynamic> map) => RoomBooking.fromMap(id, map);
  @override
  Map<String, dynamic> toMap(RoomBooking entity) => entity.toMap();
  @override
  String idOf(RoomBooking entity) => entity.id;
}

class FirestoreRoomRepository extends FirestoreCrudRepository<Room> with _RoomCodec implements RoomRepository {
  FirestoreRoomRepository(super.churchId);

  @override
  String get collectionPath => 'rooms';
  @override
  String? get orderByField => 'name';
}

class LocalRoomRepository extends LocalCrudRepository<Room> with _RoomCodec implements RoomRepository {
  @override
  String? get seedAsset => 'assets/data/rooms.json';
  @override
  int Function(Room, Room)? get sorter => (a, b) => a.name.compareTo(b.name);
}

class FirestoreBookingRepository extends FirestoreCrudRepository<RoomBooking>
    with _BookingCodec
    implements BookingRepository {
  FirestoreBookingRepository(super.churchId);

  @override
  String get collectionPath => 'roomBookings';
  @override
  String? get orderByField => 'start';

  @override
  Future<List<RoomBooking>> forMember(String uid) => fetchWhere('requestedByUid', uid);

  @override
  Future<List<RoomBooking>> forRoom(String roomId) => fetchWhere('roomId', roomId);
}

class LocalBookingRepository extends LocalCrudRepository<RoomBooking>
    with _BookingCodec
    implements BookingRepository {
  @override
  String? get seedAsset => 'assets/data/room_bookings.json';
  @override
  int Function(RoomBooking, RoomBooking)? get sorter => (a, b) => a.start.compareTo(b.start);

  @override
  Future<List<RoomBooking>> forMember(String uid) => fetchWhere((b) => b.requestedByUid == uid);

  @override
  Future<List<RoomBooking>> forRoom(String roomId) => fetchWhere((b) => b.roomId == roomId);
}
