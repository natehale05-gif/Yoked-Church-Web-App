class ChurchGroup {
  final String id;
  final String name;
  final String description;
  final String category;
  final String meetingDay;
  final String meetingTime;
  final String location;
  final String leaderName;
  final String imageUrl;

  const ChurchGroup({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.meetingDay,
    required this.meetingTime,
    required this.location,
    required this.leaderName,
    this.imageUrl = '',
  });

  factory ChurchGroup.fromMap(String id, Map<String, dynamic> map) {
    return ChurchGroup(
      id: id,
      name: map['name'] as String? ?? '',
      description: map['description'] as String? ?? '',
      category: map['category'] as String? ?? '',
      meetingDay: map['meetingDay'] as String? ?? '',
      meetingTime: map['meetingTime'] as String? ?? '',
      location: map['location'] as String? ?? '',
      leaderName: map['leaderName'] as String? ?? '',
      imageUrl: map['imageUrl'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'description': description,
        'category': category,
        'meetingDay': meetingDay,
        'meetingTime': meetingTime,
        'location': location,
        'leaderName': leaderName,
        'imageUrl': imageUrl,
      };
}
