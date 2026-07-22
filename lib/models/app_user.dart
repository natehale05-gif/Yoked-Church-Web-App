enum UserRole { member, staff, admin }

UserRole userRoleFromString(String? value) {
  return UserRole.values.firstWhere(
    (role) => role.name == value,
    orElse: () => UserRole.member,
  );
}

class HouseholdMember {
  final String name;
  final String relationship;

  const HouseholdMember({required this.name, required this.relationship});

  factory HouseholdMember.fromMap(Map<String, dynamic> map) => HouseholdMember(
        name: map['name'] as String? ?? '',
        relationship: map['relationship'] as String? ?? '',
      );

  Map<String, dynamic> toMap() => {'name': name, 'relationship': relationship};
}

class AppUser {
  final String uid;
  final String email;
  final String displayName;
  final String photoUrl;
  final UserRole role;
  final List<HouseholdMember> household;
  final bool directoryOptIn;
  final DateTime createdAt;

  const AppUser({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.photoUrl,
    required this.role,
    required this.household,
    required this.directoryOptIn,
    required this.createdAt,
  });

  bool get isStaff => role == UserRole.staff || role == UserRole.admin;
  bool get isAdmin => role == UserRole.admin;

  factory AppUser.fromMap(String uid, Map<String, dynamic> map) {
    return AppUser(
      uid: uid,
      email: map['email'] as String? ?? '',
      displayName: map['displayName'] as String? ?? '',
      photoUrl: map['photoUrl'] as String? ?? '',
      role: userRoleFromString(map['role'] as String?),
      household: ((map['household'] as List<dynamic>?) ?? [])
          .cast<Map<String, dynamic>>()
          .map(HouseholdMember.fromMap)
          .toList(),
      directoryOptIn: map['directoryOptIn'] as bool? ?? false,
      createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'email': email,
        'displayName': displayName,
        'photoUrl': photoUrl,
        'role': role.name,
        'household': household.map((m) => m.toMap()).toList(),
        'directoryOptIn': directoryOptIn,
        'createdAt': createdAt.toIso8601String(),
      };

  AppUser copyWith({
    String? displayName,
    String? photoUrl,
    List<HouseholdMember>? household,
    bool? directoryOptIn,
  }) {
    return AppUser(
      uid: uid,
      email: email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      role: role,
      household: household ?? this.household,
      directoryOptIn: directoryOptIn ?? this.directoryOptIn,
      createdAt: createdAt,
    );
  }
}
