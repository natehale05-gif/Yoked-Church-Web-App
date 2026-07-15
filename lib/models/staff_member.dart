class StaffMember {
  final String id;
  final String name;
  final String role;
  final String bio;
  final String photoUrl;
  final String email;

  const StaffMember({
    required this.id,
    required this.name,
    required this.role,
    this.bio = '',
    this.photoUrl = '',
    this.email = '',
  });

  StaffMember copyWith({
    String? name,
    String? role,
    String? bio,
    String? photoUrl,
    String? email,
  }) {
    return StaffMember(
      id: id,
      name: name ?? this.name,
      role: role ?? this.role,
      bio: bio ?? this.bio,
      photoUrl: photoUrl ?? this.photoUrl,
      email: email ?? this.email,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'role': role,
        'bio': bio,
        'photoUrl': photoUrl,
        'email': email,
      };

  factory StaffMember.fromJson(Map<String, dynamic> json) => StaffMember(
        id: json['id'] as String,
        name: json['name'] as String? ?? '',
        role: json['role'] as String? ?? '',
        bio: json['bio'] as String? ?? '',
        photoUrl: json['photoUrl'] as String? ?? '',
        email: json['email'] as String? ?? '',
      );
}
