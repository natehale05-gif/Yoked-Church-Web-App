String _sid() =>
    '${DateTime.now().microsecondsSinceEpoch}_${DateTime.now().microsecond}';

/// A serving team members can volunteer for (e.g. Worship, Kids, Hospitality).
class ServingTeam {
  final String id;
  final String name;
  final String description;
  final String iconKey;

  ServingTeam({
    String? id,
    required this.name,
    required this.description,
    required this.iconKey,
  }) : id = id ?? _sid();

  ServingTeam copyWith({String? name, String? description, String? iconKey}) =>
      ServingTeam(
        id: id,
        name: name ?? this.name,
        description: description ?? this.description,
        iconKey: iconKey ?? this.iconKey,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'iconKey': iconKey,
      };

  factory ServingTeam.fromJson(Map<String, dynamic> j) => ServingTeam(
        id: j['id'],
        name: j['name'] ?? '',
        description: j['description'] ?? '',
        iconKey: j['iconKey'] ?? 'handshake',
      );
}

/// A specific serving opportunity/slot on a date that members sign up for.
class ServingSlot {
  final String id;
  final String teamId;
  final String title;
  final DateTime date;
  final String time;
  final int needed;
  final List<String> memberIds;

  ServingSlot({
    String? id,
    required this.teamId,
    required this.title,
    required this.date,
    required this.time,
    this.needed = 1,
    List<String>? memberIds,
  })  : id = id ?? _sid(),
        memberIds = memberIds ?? const [];

  int get filled => memberIds.length;
  int get remaining => (needed - filled).clamp(0, needed);
  bool get isFull => filled >= needed;

  ServingSlot copyWith({
    String? teamId,
    String? title,
    DateTime? date,
    String? time,
    int? needed,
    List<String>? memberIds,
  }) =>
      ServingSlot(
        id: id,
        teamId: teamId ?? this.teamId,
        title: title ?? this.title,
        date: date ?? this.date,
        time: time ?? this.time,
        needed: needed ?? this.needed,
        memberIds: memberIds ?? this.memberIds,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'teamId': teamId,
        'title': title,
        'date': date.toIso8601String(),
        'time': time,
        'needed': needed,
        'memberIds': memberIds,
      };

  factory ServingSlot.fromJson(Map<String, dynamic> j) => ServingSlot(
        id: j['id'],
        teamId: j['teamId'] ?? '',
        title: j['title'] ?? '',
        date: DateTime.tryParse(j['date'] ?? '') ?? DateTime.now(),
        time: j['time'] ?? '',
        needed: (j['needed'] ?? 1) as int,
        memberIds:
            (j['memberIds'] as List?)?.map((e) => e.toString()).toList() ?? [],
      );
}
