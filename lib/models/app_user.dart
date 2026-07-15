/// Account roles. Staff can manage everything; members get a personal portal.
enum UserRole { staff, member }

extension UserRoleX on UserRole {
  String get label => this == UserRole.staff ? 'Staff' : 'Member';
}

UserRole roleFromKey(String? key) =>
    key == 'staff' ? UserRole.staff : UserRole.member;

class AppUser {
  final String id;
  final String name;
  final String email;
  final UserRole role;

  /// A lightweight hash of the password. NOTE: this is a functional prototype
  /// only — real authentication must be handled by a secure backend.
  final String passwordHash;

  /// Links a member-role account to their [Member] record.
  final String? memberId;

  AppUser({
    String? id,
    required this.name,
    required this.email,
    required this.role,
    required this.passwordHash,
    this.memberId,
  }) : id = id ??
            '${DateTime.now().microsecondsSinceEpoch}_${DateTime.now().microsecond}';

  AppUser copyWith({
    String? name,
    String? email,
    UserRole? role,
    String? passwordHash,
    String? memberId,
  }) =>
      AppUser(
        id: id,
        name: name ?? this.name,
        email: email ?? this.email,
        role: role ?? this.role,
        passwordHash: passwordHash ?? this.passwordHash,
        memberId: memberId ?? this.memberId,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'role': role.name,
        'passwordHash': passwordHash,
        'memberId': memberId,
      };

  factory AppUser.fromJson(Map<String, dynamic> j) => AppUser(
        id: j['id'],
        name: j['name'] ?? '',
        email: j['email'] ?? '',
        role: roleFromKey(j['role']),
        passwordHash: j['passwordHash'] ?? '',
        memberId: j['memberId'],
      );
}
