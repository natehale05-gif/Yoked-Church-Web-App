import 'package:flutter/foundation.dart';

/// A bookable space. Tied to a [ChurchLocation] so a multi-campus church
/// can keep its rooms straight; single-campus churches leave it blank
/// and never notice.
@immutable
class Room {
  final String id;
  final String name;
  final String locationId;
  final String locationName;
  final String description;
  final int capacity;

  /// Some rooms exist for kids check-in but must never appear on the
  /// booking form - a nursery is not a meeting space.
  final bool bookable;

  const Room({
    this.id = '',
    required this.name,
    this.locationId = '',
    this.locationName = '',
    this.description = '',
    this.capacity = 0,
    this.bookable = true,
  });

  factory Room.fromMap(String id, Map<String, dynamic> map) => Room(
        id: id,
        name: map['name'] as String? ?? '',
        locationId: map['locationId'] as String? ?? '',
        locationName: map['locationName'] as String? ?? '',
        description: map['description'] as String? ?? '',
        capacity: (map['capacity'] as num?)?.toInt() ?? 0,
        bookable: map['bookable'] as bool? ?? true,
      );

  Map<String, dynamic> toMap() => {
        'name': name,
        'locationId': locationId,
        'locationName': locationName,
        'description': description,
        'capacity': capacity,
        'bookable': bookable,
      };

  Room copyWith({
    String? name,
    String? locationId,
    String? locationName,
    String? description,
    int? capacity,
    bool? bookable,
  }) =>
      Room(
        id: id,
        name: name ?? this.name,
        locationId: locationId ?? this.locationId,
        locationName: locationName ?? this.locationName,
        description: description ?? this.description,
        capacity: capacity ?? this.capacity,
        bookable: bookable ?? this.bookable,
      );

  String get subtitle => [
        if (locationName.isNotEmpty) locationName,
        if (capacity > 0) 'seats $capacity',
      ].join(' · ');
}

enum BookingStatus { pending, approved, declined, cancelled }

@immutable
class RoomBooking {
  final String id;
  final String roomId;

  /// Denormalised so the member's own list renders without loading every
  /// room, and still reads correctly if a room is later deleted.
  final String roomName;
  final String requestedByUid;
  final String requestedByName;
  final String purpose;
  final DateTime start;
  final DateTime end;
  final int expectedAttendance;
  final BookingStatus status;
  final String staffNote;
  final String moderatedBy;

  const RoomBooking({
    this.id = '',
    required this.roomId,
    this.roomName = '',
    required this.requestedByUid,
    this.requestedByName = '',
    required this.purpose,
    required this.start,
    required this.end,
    this.expectedAttendance = 0,
    this.status = BookingStatus.pending,
    this.staffNote = '',
    this.moderatedBy = '',
  });

  factory RoomBooking.fromMap(String id, Map<String, dynamic> map) => RoomBooking(
        id: id,
        roomId: map['roomId'] as String? ?? '',
        roomName: map['roomName'] as String? ?? '',
        requestedByUid: map['requestedByUid'] as String? ?? '',
        requestedByName: map['requestedByName'] as String? ?? '',
        purpose: map['purpose'] as String? ?? '',
        start: DateTime.tryParse(map['start'] as String? ?? '') ?? DateTime.now(),
        end: DateTime.tryParse(map['end'] as String? ?? '') ?? DateTime.now(),
        expectedAttendance: (map['expectedAttendance'] as num?)?.toInt() ?? 0,
        status: BookingStatus.values.firstWhere(
          (s) => s.name == map['status'],
          orElse: () => BookingStatus.pending,
        ),
        staffNote: map['staffNote'] as String? ?? '',
        moderatedBy: map['moderatedBy'] as String? ?? '',
      );

  Map<String, dynamic> toMap() => {
        'roomId': roomId,
        'roomName': roomName,
        'requestedByUid': requestedByUid,
        'requestedByName': requestedByName,
        'purpose': purpose,
        'start': start.toIso8601String(),
        'end': end.toIso8601String(),
        'expectedAttendance': expectedAttendance,
        'status': status.name,
        'staffNote': staffNote,
        'moderatedBy': moderatedBy,
      };

  RoomBooking copyWith({BookingStatus? status, String? staffNote, String? moderatedBy}) => RoomBooking(
        id: id,
        roomId: roomId,
        roomName: roomName,
        requestedByUid: requestedByUid,
        requestedByName: requestedByName,
        purpose: purpose,
        start: start,
        end: end,
        expectedAttendance: expectedAttendance,
        status: status ?? this.status,
        staffNote: staffNote ?? this.staffNote,
        moderatedBy: moderatedBy ?? this.moderatedBy,
      );

  /// Only an approved booking actually holds the room. A pending request
  /// is a question, not a reservation.
  bool get holdsTheRoom => status == BookingStatus.approved;

  bool get isPast => end.isBefore(DateTime.now());

  /// Half-open interval: a booking ending at 3:00 and one starting at
  /// 3:00 do not overlap. Back-to-back meetings are the normal case in a
  /// church building, and treating them as a clash would make the
  /// feature useless.
  bool overlaps(RoomBooking other) =>
      roomId == other.roomId && start.isBefore(other.end) && other.start.isBefore(end);

  /// A booking that ends before it starts would silently never overlap
  /// with anything, so it is rejected at the form rather than stored.
  bool get isWellFormed => end.isAfter(start);
}
