import 'package:flutter/foundation.dart';

enum UserRole { member, staff, admin }

UserRole userRoleFromString(String? value) =>
    UserRole.values.firstWhere((r) => r.name == value, orElse: () => UserRole.member);

@immutable
class HouseholdMember {
  final String name;
  final String relationship;

  /// Set for children so kids check-in can find them. Optional otherwise.
  final DateTime? birthDate;

  const HouseholdMember({required this.name, this.relationship = '', this.birthDate});

  factory HouseholdMember.fromMap(Map<String, dynamic> map) => HouseholdMember(
        name: map['name'] as String? ?? '',
        relationship: map['relationship'] as String? ?? '',
        birthDate: map['birthDate'] == null ? null : DateTime.tryParse(map['birthDate'] as String),
      );

  Map<String, dynamic> toMap() => {
        'name': name,
        'relationship': relationship,
        'birthDate': birthDate?.toIso8601String(),
      };
}

/// Which notification categories a member wants in their inbox.
@immutable
class NotificationPreferences {
  final bool volunteering;
  final bool announcements;
  final bool groups;
  final bool events;

  const NotificationPreferences({
    this.volunteering = true,
    this.announcements = true,
    this.groups = true,
    this.events = true,
  });

  factory NotificationPreferences.fromMap(Map<String, dynamic> map) => NotificationPreferences(
        volunteering: map['volunteering'] as bool? ?? true,
        announcements: map['announcements'] as bool? ?? true,
        groups: map['groups'] as bool? ?? true,
        events: map['events'] as bool? ?? true,
      );

  Map<String, dynamic> toMap() => {
        'volunteering': volunteering,
        'announcements': announcements,
        'groups': groups,
        'events': events,
      };

  bool allows(String category) => switch (category) {
        'volunteering' => volunteering,
        'announcements' => announcements,
        'groups' => groups,
        'events' => events,
        _ => true,
      };

  NotificationPreferences copyWithEntry(String key, bool value) {
    final map = toMap()..[key] = value;
    return NotificationPreferences.fromMap(map);
  }
}

@immutable
class AppUser {
  final String uid;
  final String email;
  final String displayName;
  final String phone;
  final String photoUrl;
  final UserRole role;
  final List<HouseholdMember> household;
  final bool directoryOptIn;
  final NotificationPreferences notificationPreferences;
  final DateTime createdAt;

  const AppUser({
    required this.uid,
    required this.email,
    required this.displayName,
    this.phone = '',
    this.photoUrl = '',
    this.role = UserRole.member,
    this.household = const [],
    this.directoryOptIn = false,
    this.notificationPreferences = const NotificationPreferences(),
    required this.createdAt,
  });

  bool get isStaff => role == UserRole.staff || role == UserRole.admin;
  bool get isAdmin => role == UserRole.admin;

  String get initial => displayName.isNotEmpty
      ? displayName[0].toUpperCase()
      : (email.isNotEmpty ? email[0].toUpperCase() : '?');

  factory AppUser.fromMap(String uid, Map<String, dynamic> map) => AppUser(
        uid: uid,
        email: map['email'] as String? ?? '',
        displayName: map['displayName'] as String? ?? '',
        phone: map['phone'] as String? ?? '',
        photoUrl: map['photoUrl'] as String? ?? '',
        role: userRoleFromString(map['role'] as String?),
        household: ((map['household'] as List<dynamic>?) ?? const [])
            .whereType<Map<dynamic, dynamic>>()
            .map((e) => HouseholdMember.fromMap(e.cast<String, dynamic>()))
            .toList(),
        directoryOptIn: map['directoryOptIn'] as bool? ?? false,
        notificationPreferences: NotificationPreferences.fromMap(
          (map['notificationPreferences'] as Map?)?.cast<String, dynamic>() ?? const {},
        ),
        createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ?? DateTime.now(),
      );

  Map<String, dynamic> toMap() => {
        'email': email,
        'displayName': displayName,
        'phone': phone,
        'photoUrl': photoUrl,
        'role': role.name,
        'household': household.map((h) => h.toMap()).toList(),
        'directoryOptIn': directoryOptIn,
        'notificationPreferences': notificationPreferences.toMap(),
        'createdAt': createdAt.toIso8601String(),
      };

  AppUser copyWith({
    String? displayName,
    String? phone,
    String? photoUrl,
    UserRole? role,
    List<HouseholdMember>? household,
    bool? directoryOptIn,
    NotificationPreferences? notificationPreferences,
  }) =>
      AppUser(
        uid: uid,
        email: email,
        displayName: displayName ?? this.displayName,
        phone: phone ?? this.phone,
        photoUrl: photoUrl ?? this.photoUrl,
        role: role ?? this.role,
        household: household ?? this.household,
        directoryOptIn: directoryOptIn ?? this.directoryOptIn,
        notificationPreferences: notificationPreferences ?? this.notificationPreferences,
        createdAt: createdAt,
      );
}
