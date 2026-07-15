import 'dart:ui';

/// Editable content models for the public website. Everything here can be
/// changed in the built-in Site Editor and is persisted, so the whole public
/// site is data-driven (a lightweight CMS).

String _newId() =>
    DateTime.now().microsecondsSinceEpoch.toString() +
    (1000 + (DateTime.now().microsecond % 9000)).toString();

class ServiceTime {
  final String day;
  final String time;
  final String label;
  const ServiceTime({required this.day, required this.time, required this.label});

  ServiceTime copyWith({String? day, String? time, String? label}) =>
      ServiceTime(
        day: day ?? this.day,
        time: time ?? this.time,
        label: label ?? this.label,
      );

  Map<String, dynamic> toJson() => {'day': day, 'time': time, 'label': label};
  factory ServiceTime.fromJson(Map<String, dynamic> j) => ServiceTime(
        day: j['day'] ?? '',
        time: j['time'] ?? '',
        label: j['label'] ?? '',
      );
}

class ValuePoint {
  final String iconKey;
  final String title;
  final String body;
  const ValuePoint({
    required this.iconKey,
    required this.title,
    required this.body,
  });

  ValuePoint copyWith({String? iconKey, String? title, String? body}) =>
      ValuePoint(
        iconKey: iconKey ?? this.iconKey,
        title: title ?? this.title,
        body: body ?? this.body,
      );

  Map<String, dynamic> toJson() =>
      {'iconKey': iconKey, 'title': title, 'body': body};
  factory ValuePoint.fromJson(Map<String, dynamic> j) => ValuePoint(
        iconKey: j['iconKey'] ?? 'star',
        title: j['title'] ?? '',
        body: j['body'] ?? '',
      );
}

class Ministry {
  final String id;
  final String name;
  final String forWho;
  final String description;
  final String iconKey;
  Ministry({
    String? id,
    required this.name,
    required this.forWho,
    required this.description,
    required this.iconKey,
  }) : id = id ?? _newId();

  Ministry copyWith({
    String? name,
    String? forWho,
    String? description,
    String? iconKey,
  }) =>
      Ministry(
        id: id,
        name: name ?? this.name,
        forWho: forWho ?? this.forWho,
        description: description ?? this.description,
        iconKey: iconKey ?? this.iconKey,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'forWho': forWho,
        'description': description,
        'iconKey': iconKey,
      };
  factory Ministry.fromJson(Map<String, dynamic> j) => Ministry(
        id: j['id'],
        name: j['name'] ?? '',
        forWho: j['forWho'] ?? '',
        description: j['description'] ?? '',
        iconKey: j['iconKey'] ?? 'groups',
      );
}

class Person {
  final String id;
  final String name;
  final String role;
  final String bio;
  final String? imageUrl;
  Person({
    String? id,
    required this.name,
    required this.role,
    required this.bio,
    this.imageUrl,
  }) : id = id ?? _newId();

  Person copyWith({String? name, String? role, String? bio, String? imageUrl}) =>
      Person(
        id: id,
        name: name ?? this.name,
        role: role ?? this.role,
        bio: bio ?? this.bio,
        imageUrl: imageUrl ?? this.imageUrl,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'role': role,
        'bio': bio,
        'imageUrl': imageUrl,
      };
  factory Person.fromJson(Map<String, dynamic> j) => Person(
        id: j['id'],
        name: j['name'] ?? '',
        role: j['role'] ?? '',
        bio: j['bio'] ?? '',
        imageUrl: j['imageUrl'],
      );
}

class Sermon {
  final String id;
  final String title;
  final String series;
  final String speaker;
  final String date;
  final String description;
  Sermon({
    String? id,
    required this.title,
    required this.series,
    required this.speaker,
    required this.date,
    required this.description,
  }) : id = id ?? _newId();

  Sermon copyWith({
    String? title,
    String? series,
    String? speaker,
    String? date,
    String? description,
  }) =>
      Sermon(
        id: id,
        title: title ?? this.title,
        series: series ?? this.series,
        speaker: speaker ?? this.speaker,
        date: date ?? this.date,
        description: description ?? this.description,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'series': series,
        'speaker': speaker,
        'date': date,
        'description': description,
      };
  factory Sermon.fromJson(Map<String, dynamic> j) => Sermon(
        id: j['id'],
        title: j['title'] ?? '',
        series: j['series'] ?? '',
        speaker: j['speaker'] ?? '',
        date: j['date'] ?? '',
        description: j['description'] ?? '',
      );
}

class ChurchEvent {
  final String id;
  final String title;
  final String date;
  final String time;
  final String location;
  final String description;
  ChurchEvent({
    String? id,
    required this.title,
    required this.date,
    required this.time,
    required this.location,
    required this.description,
  }) : id = id ?? _newId();

  ChurchEvent copyWith({
    String? title,
    String? date,
    String? time,
    String? location,
    String? description,
  }) =>
      ChurchEvent(
        id: id,
        title: title ?? this.title,
        date: date ?? this.date,
        time: time ?? this.time,
        location: location ?? this.location,
        description: description ?? this.description,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'date': date,
        'time': time,
        'location': location,
        'description': description,
      };
  factory ChurchEvent.fromJson(Map<String, dynamic> j) => ChurchEvent(
        id: j['id'],
        title: j['title'] ?? '',
        date: j['date'] ?? '',
        time: j['time'] ?? '',
        location: j['location'] ?? '',
        description: j['description'] ?? '',
      );
}

/// The full editable site. A single object drives the entire public website.
class SiteContent {
  final String churchName;
  final String shortName;
  final String tagline;
  final String heroHeadline;
  final String heroSubhead;

  final String addressLine1;
  final String addressLine2;
  final String phone;
  final String email;
  final String mapUrl;
  final String giveUrl;

  final String instagramUrl;
  final String facebookUrl;
  final String youtubeUrl;

  /// Brand accent color stored as an ARGB int so it survives JSON.
  final int accentColor;

  final List<ServiceTime> serviceTimes;
  final List<ValuePoint> whatToExpect;
  final List<ValuePoint> values;
  final List<Ministry> ministries;
  final List<Person> leaders;
  final List<Sermon> sermons;
  final List<ChurchEvent> events;

  const SiteContent({
    required this.churchName,
    required this.shortName,
    required this.tagline,
    required this.heroHeadline,
    required this.heroSubhead,
    required this.addressLine1,
    required this.addressLine2,
    required this.phone,
    required this.email,
    required this.mapUrl,
    required this.giveUrl,
    required this.instagramUrl,
    required this.facebookUrl,
    required this.youtubeUrl,
    required this.accentColor,
    required this.serviceTimes,
    required this.whatToExpect,
    required this.values,
    required this.ministries,
    required this.leaders,
    required this.sermons,
    required this.events,
  });

  Color get accent => Color(accentColor);

  SiteContent copyWith({
    String? churchName,
    String? shortName,
    String? tagline,
    String? heroHeadline,
    String? heroSubhead,
    String? addressLine1,
    String? addressLine2,
    String? phone,
    String? email,
    String? mapUrl,
    String? giveUrl,
    String? instagramUrl,
    String? facebookUrl,
    String? youtubeUrl,
    int? accentColor,
    List<ServiceTime>? serviceTimes,
    List<ValuePoint>? whatToExpect,
    List<ValuePoint>? values,
    List<Ministry>? ministries,
    List<Person>? leaders,
    List<Sermon>? sermons,
    List<ChurchEvent>? events,
  }) {
    return SiteContent(
      churchName: churchName ?? this.churchName,
      shortName: shortName ?? this.shortName,
      tagline: tagline ?? this.tagline,
      heroHeadline: heroHeadline ?? this.heroHeadline,
      heroSubhead: heroSubhead ?? this.heroSubhead,
      addressLine1: addressLine1 ?? this.addressLine1,
      addressLine2: addressLine2 ?? this.addressLine2,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      mapUrl: mapUrl ?? this.mapUrl,
      giveUrl: giveUrl ?? this.giveUrl,
      instagramUrl: instagramUrl ?? this.instagramUrl,
      facebookUrl: facebookUrl ?? this.facebookUrl,
      youtubeUrl: youtubeUrl ?? this.youtubeUrl,
      accentColor: accentColor ?? this.accentColor,
      serviceTimes: serviceTimes ?? this.serviceTimes,
      whatToExpect: whatToExpect ?? this.whatToExpect,
      values: values ?? this.values,
      ministries: ministries ?? this.ministries,
      leaders: leaders ?? this.leaders,
      sermons: sermons ?? this.sermons,
      events: events ?? this.events,
    );
  }

  Map<String, dynamic> toJson() => {
        'churchName': churchName,
        'shortName': shortName,
        'tagline': tagline,
        'heroHeadline': heroHeadline,
        'heroSubhead': heroSubhead,
        'addressLine1': addressLine1,
        'addressLine2': addressLine2,
        'phone': phone,
        'email': email,
        'mapUrl': mapUrl,
        'giveUrl': giveUrl,
        'instagramUrl': instagramUrl,
        'facebookUrl': facebookUrl,
        'youtubeUrl': youtubeUrl,
        'accentColor': accentColor,
        'serviceTimes': serviceTimes.map((e) => e.toJson()).toList(),
        'whatToExpect': whatToExpect.map((e) => e.toJson()).toList(),
        'values': values.map((e) => e.toJson()).toList(),
        'ministries': ministries.map((e) => e.toJson()).toList(),
        'leaders': leaders.map((e) => e.toJson()).toList(),
        'sermons': sermons.map((e) => e.toJson()).toList(),
        'events': events.map((e) => e.toJson()).toList(),
      };

  factory SiteContent.fromJson(Map<String, dynamic> j) => SiteContent(
        churchName: j['churchName'] ?? '',
        shortName: j['shortName'] ?? '',
        tagline: j['tagline'] ?? '',
        heroHeadline: j['heroHeadline'] ?? '',
        heroSubhead: j['heroSubhead'] ?? '',
        addressLine1: j['addressLine1'] ?? '',
        addressLine2: j['addressLine2'] ?? '',
        phone: j['phone'] ?? '',
        email: j['email'] ?? '',
        mapUrl: j['mapUrl'] ?? '',
        giveUrl: j['giveUrl'] ?? '',
        instagramUrl: j['instagramUrl'] ?? '',
        facebookUrl: j['facebookUrl'] ?? '',
        youtubeUrl: j['youtubeUrl'] ?? '',
        accentColor: j['accentColor'] ?? 0xFFC6A15B,
        serviceTimes: _list(j['serviceTimes'], ServiceTime.fromJson),
        whatToExpect: _list(j['whatToExpect'], ValuePoint.fromJson),
        values: _list(j['values'], ValuePoint.fromJson),
        ministries: _list(j['ministries'], Ministry.fromJson),
        leaders: _list(j['leaders'], Person.fromJson),
        sermons: _list(j['sermons'], Sermon.fromJson),
        events: _list(j['events'], ChurchEvent.fromJson),
      );

  static List<T> _list<T>(
    dynamic raw,
    T Function(Map<String, dynamic>) from,
  ) {
    if (raw is! List) return [];
    return raw
        .whereType<Map>()
        .map((e) => from(Map<String, dynamic>.from(e)))
        .toList();
  }
}
