import 'dart:math';

import 'package:flutter/foundation.dart';

enum CheckInStatus { checkedIn, collected }

/// One child, in one room, for one service.
///
/// The pickup code is the safety mechanism: it is handed to whoever
/// dropped the child off, and a volunteer at the door will not release
/// the child without it. Everything below exists to make that hold up.
@immutable
class CheckInSession {
  final String id;
  final String childName;
  final DateTime? childBirthDate;

  /// Who dropped the child off. Kept so staff can find a parent quickly,
  /// and so a guardian can see their own children on their phone.
  final String guardianUid;
  final String guardianName;
  final String guardianPhone;

  final String roomId;
  final String roomName;

  /// Free text, shown prominently to the volunteer in the room. Allergies
  /// and medical notes are the reason this is not buried in a detail page.
  final String allergyNote;

  final DateTime checkedInAt;
  final String pickupCode;

  /// Set the moment the code is used. A code with this set is spent.
  final DateTime? codeUsedAt;
  final String releasedTo;
  final CheckInStatus status;

  const CheckInSession({
    this.id = '',
    required this.childName,
    this.childBirthDate,
    required this.guardianUid,
    this.guardianName = '',
    this.guardianPhone = '',
    required this.roomId,
    this.roomName = '',
    this.allergyNote = '',
    required this.checkedInAt,
    required this.pickupCode,
    this.codeUsedAt,
    this.releasedTo = '',
    this.status = CheckInStatus.checkedIn,
  });

  factory CheckInSession.fromMap(String id, Map<String, dynamic> map) => CheckInSession(
        id: id,
        childName: map['childName'] as String? ?? '',
        childBirthDate:
            map['childBirthDate'] == null ? null : DateTime.tryParse(map['childBirthDate'] as String),
        guardianUid: map['guardianUid'] as String? ?? '',
        guardianName: map['guardianName'] as String? ?? '',
        guardianPhone: map['guardianPhone'] as String? ?? '',
        roomId: map['roomId'] as String? ?? '',
        roomName: map['roomName'] as String? ?? '',
        allergyNote: map['allergyNote'] as String? ?? '',
        checkedInAt: DateTime.tryParse(map['checkedInAt'] as String? ?? '') ?? DateTime.now(),
        pickupCode: map['pickupCode'] as String? ?? '',
        codeUsedAt: map['codeUsedAt'] == null ? null : DateTime.tryParse(map['codeUsedAt'] as String),
        releasedTo: map['releasedTo'] as String? ?? '',
        status: CheckInStatus.values.firstWhere(
          (s) => s.name == map['status'],
          orElse: () => CheckInStatus.checkedIn,
        ),
      );

  Map<String, dynamic> toMap() => {
        'childName': childName,
        'childBirthDate': childBirthDate?.toIso8601String(),
        'guardianUid': guardianUid,
        'guardianName': guardianName,
        'guardianPhone': guardianPhone,
        'roomId': roomId,
        'roomName': roomName,
        'allergyNote': allergyNote,
        'checkedInAt': checkedInAt.toIso8601String(),
        'pickupCode': pickupCode,
        'codeUsedAt': codeUsedAt?.toIso8601String(),
        'releasedTo': releasedTo,
        'status': status.name,
      };

  CheckInSession copyWith({DateTime? codeUsedAt, String? releasedTo, CheckInStatus? status}) =>
      CheckInSession(
        id: id,
        childName: childName,
        childBirthDate: childBirthDate,
        guardianUid: guardianUid,
        guardianName: guardianName,
        guardianPhone: guardianPhone,
        roomId: roomId,
        roomName: roomName,
        allergyNote: allergyNote,
        checkedInAt: checkedInAt,
        pickupCode: pickupCode,
        codeUsedAt: codeUsedAt ?? this.codeUsedAt,
        releasedTo: releasedTo ?? this.releasedTo,
        status: status ?? this.status,
      );

  /// The child is still in the building. This, not the code, is what the
  /// room roster counts.
  bool get isActive => status == CheckInStatus.checkedIn;

  /// A code is spendable exactly once, while the session is active.
  bool get codeIsSpent => codeUsedAt != null;

  bool get hasAllergyNote => allergyNote.trim().isNotEmpty;

  /// Age in whole years at check-in, or null when no birth date was
  /// recorded. Shown to the volunteer so an obviously misrouted child
  /// (a toddler in the 7-11 room) is visible at a glance.
  int? get ageYears {
    final born = childBirthDate;
    if (born == null) return null;
    var age = checkedInAt.year - born.year;
    final hadBirthday = checkedInAt.month > born.month ||
        (checkedInAt.month == born.month && checkedInAt.day >= born.day);
    if (!hadBirthday) age -= 1;
    return age < 0 ? null : age;
  }
}

/// Why a release attempt failed. The reason matters: "wrong code" and
/// "that code was already used" call for very different responses from
/// the volunteer at the door.
enum ReleaseFailure { noSuchCode, alreadyUsed }

@immutable
class ReleaseResult {
  final CheckInSession? released;
  final ReleaseFailure? failure;

  /// Set on [ReleaseFailure.alreadyUsed] so the volunteer can be told
  /// when, and by whom, the child was collected.
  final CheckInSession? spent;

  const ReleaseResult.success(CheckInSession session)
      : released = session,
        failure = null,
        spent = null;

  const ReleaseResult.notFound()
      : released = null,
        failure = ReleaseFailure.noSuchCode,
        spent = null;

  const ReleaseResult.alreadyUsed(CheckInSession session)
      : released = null,
        failure = ReleaseFailure.alreadyUsed,
        spent = session;

  bool get ok => released != null;
}

/// Unambiguous alphabet: no O/0, no I/1/L. A parent reads this off a
/// phone screen to a volunteer across a noisy foyer, and a
/// misread character is a failed pickup.
const _codeAlphabet = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';

/// Generates a code that is not already in use by an active session.
///
/// Uniqueness among *active* sessions is the property that matters: a
/// mistyped code must never accidentally match a different child who is
/// currently in the building. Reusing a code from last Sunday is fine
/// and expected - the space is small on purpose.
String generatePickupCode(Iterable<String> codesInUse, {Random? random, int length = 4}) {
  final rng = random ?? Random();
  final taken = codesInUse.toSet();

  // The alphabet gives ~923k four-character codes, so collisions are
  // rare; the loop exists for correctness, not for the common path.
  for (var attempt = 0; attempt < 500; attempt++) {
    final code = List.generate(length, (_) => _codeAlphabet[rng.nextInt(_codeAlphabet.length)]).join();
    if (!taken.contains(code)) return code;
  }
  // Exhausting 500 attempts means the room is implausibly full. Widening
  // beats handing out a duplicate.
  return generatePickupCode(taken, random: rng, length: length + 1);
}
