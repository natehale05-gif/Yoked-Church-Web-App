/// A person tracked by the church (attender, visitor, or member).
enum MemberStatus { visitor, regular, member, inactive }

extension MemberStatusX on MemberStatus {
  String get label => switch (this) {
        MemberStatus.visitor => 'Visitor',
        MemberStatus.regular => 'Regular',
        MemberStatus.member => 'Member',
        MemberStatus.inactive => 'Inactive',
      };
  String get key => name;
}

MemberStatus memberStatusFromKey(String? key) =>
    MemberStatus.values.firstWhere(
      (s) => s.name == key,
      orElse: () => MemberStatus.visitor,
    );

String _newId() =>
    '${DateTime.now().microsecondsSinceEpoch}_${DateTime.now().microsecond}';

class Member {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final MemberStatus status;
  final String household;
  final String notes;
  final String? imageUrl;
  final DateTime joined;

  Member({
    String? id,
    required this.firstName,
    required this.lastName,
    this.email = '',
    this.phone = '',
    this.status = MemberStatus.visitor,
    this.household = '',
    this.notes = '',
    this.imageUrl,
    DateTime? joined,
  })  : id = id ?? _newId(),
        joined = joined ?? DateTime.now();

  String get fullName => '$firstName $lastName'.trim();
  String get initials {
    final f = firstName.isNotEmpty ? firstName[0] : '';
    final l = lastName.isNotEmpty ? lastName[0] : '';
    return (f + l).toUpperCase();
  }

  Member copyWith({
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    MemberStatus? status,
    String? household,
    String? notes,
    String? imageUrl,
    DateTime? joined,
  }) =>
      Member(
        id: id,
        firstName: firstName ?? this.firstName,
        lastName: lastName ?? this.lastName,
        email: email ?? this.email,
        phone: phone ?? this.phone,
        status: status ?? this.status,
        household: household ?? this.household,
        notes: notes ?? this.notes,
        imageUrl: imageUrl ?? this.imageUrl,
        joined: joined ?? this.joined,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'phone': phone,
        'status': status.name,
        'household': household,
        'notes': notes,
        'imageUrl': imageUrl,
        'joined': joined.toIso8601String(),
      };

  factory Member.fromJson(Map<String, dynamic> j) => Member(
        id: j['id'],
        firstName: j['firstName'] ?? '',
        lastName: j['lastName'] ?? '',
        email: j['email'] ?? '',
        phone: j['phone'] ?? '',
        status: memberStatusFromKey(j['status']),
        household: j['household'] ?? '',
        notes: j['notes'] ?? '',
        imageUrl: j['imageUrl'],
        joined: DateTime.tryParse(j['joined'] ?? '') ?? DateTime.now(),
      );
}
