class Ministry {
  final String id;
  final String name;
  final String description;

  /// Material icon name used for display (see [ministryIcons]).
  final String icon;
  final String leader;
  final String contactUrl;

  const Ministry({
    required this.id,
    required this.name,
    this.description = '',
    this.icon = 'groups',
    this.leader = '',
    this.contactUrl = '',
  });

  Ministry copyWith({
    String? name,
    String? description,
    String? icon,
    String? leader,
    String? contactUrl,
  }) {
    return Ministry(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      leader: leader ?? this.leader,
      contactUrl: contactUrl ?? this.contactUrl,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'icon': icon,
        'leader': leader,
        'contactUrl': contactUrl,
      };

  factory Ministry.fromJson(Map<String, dynamic> json) => Ministry(
        id: json['id'] as String,
        name: json['name'] as String? ?? '',
        description: json['description'] as String? ?? '',
        icon: json['icon'] as String? ?? 'groups',
        leader: json['leader'] as String? ?? '',
        contactUrl: json['contactUrl'] as String? ?? '',
      );
}
