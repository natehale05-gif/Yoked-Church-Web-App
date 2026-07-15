class ServiceTime {
  final String id;
  final String name;
  final String day;
  final String time;
  final String location;

  const ServiceTime({
    required this.id,
    required this.name,
    required this.day,
    required this.time,
    this.location = '',
  });

  ServiceTime copyWith({
    String? name,
    String? day,
    String? time,
    String? location,
  }) {
    return ServiceTime(
      id: id,
      name: name ?? this.name,
      day: day ?? this.day,
      time: time ?? this.time,
      location: location ?? this.location,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'day': day,
        'time': time,
        'location': location,
      };

  factory ServiceTime.fromJson(Map<String, dynamic> json) => ServiceTime(
        id: json['id'] as String,
        name: json['name'] as String? ?? '',
        day: json['day'] as String? ?? '',
        time: json['time'] as String? ?? '',
        location: json['location'] as String? ?? '',
      );
}
