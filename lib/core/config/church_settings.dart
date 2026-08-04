import 'package:flutter/material.dart';

/// Everything that differs between one church's deployment and another.
///
/// This is deliberately *runtime data*, not compile-time constants: it is
/// loaded from Firestore (`churchSettings/main`) when a backend is
/// configured, and falls back to `assets/data/church_settings.json`
/// otherwise. An admin editing these values re-brands the live site with
/// no code change and no redeploy, which is the whole premise of selling
/// this app as a customizable template.
@immutable
class ChurchSettings {
  final String churchName;
  final String tagline;
  final String logoUrl;
  final String aboutHeadline;
  final String aboutBody;
  final String beliefs;
  final String visitInfo;

  /// The `owner/repo` whose GitHub releases hold the installable apps,
  /// e.g. `natehale05-gif/yoked-church-web-app`.
  ///
  /// A setting rather than a constant because this is sold as a template:
  /// a church forks the repo and publishes its own releases, and a
  /// hardcoded slug would point every fork's download buttons at somebody
  /// else's builds. Blank hides the download page entirely, which is the
  /// right default for a church that has never cut a release.
  final String releasesRepo;

  final BrandColors colors;
  final ContactInfo contact;
  final SocialLinks social;
  final List<ServiceTime> serviceTimes;
  final FeatureFlags features;

  const ChurchSettings({
    required this.churchName,
    required this.tagline,
    this.logoUrl = '',
    this.aboutHeadline = '',
    this.aboutBody = '',
    this.beliefs = '',
    this.visitInfo = '',
    this.releasesRepo = '',
    required this.colors,
    required this.contact,
    required this.social,
    required this.serviceTimes,
    required this.features,
  });

  factory ChurchSettings.fromMap(Map<String, dynamic> map) {
    return ChurchSettings(
      churchName: map['churchName'] as String? ?? 'Our Church',
      tagline: map['tagline'] as String? ?? '',
      logoUrl: map['logoUrl'] as String? ?? '',
      aboutHeadline: map['aboutHeadline'] as String? ?? '',
      aboutBody: map['aboutBody'] as String? ?? '',
      beliefs: map['beliefs'] as String? ?? '',
      visitInfo: map['visitInfo'] as String? ?? '',
      releasesRepo: map['releasesRepo'] as String? ?? '',
      colors: BrandColors.fromMap(_sub(map['colors'])),
      contact: ContactInfo.fromMap(_sub(map['contact'])),
      social: SocialLinks.fromMap(_sub(map['social'])),
      serviceTimes: ((map['serviceTimes'] as List<dynamic>?) ?? const [])
          .whereType<Map<dynamic, dynamic>>()
          .map((e) => ServiceTime.fromMap(e.cast<String, dynamic>()))
          .toList(),
      features: FeatureFlags.fromMap(_sub(map['features'])),
    );
  }

  Map<String, dynamic> toMap() => {
        'churchName': churchName,
        'tagline': tagline,
        'logoUrl': logoUrl,
        'aboutHeadline': aboutHeadline,
        'aboutBody': aboutBody,
        'beliefs': beliefs,
        'visitInfo': visitInfo,
        'releasesRepo': releasesRepo,
        'colors': colors.toMap(),
        'contact': contact.toMap(),
        'social': social.toMap(),
        'serviceTimes': serviceTimes.map((s) => s.toMap()).toList(),
        'features': features.toMap(),
      };

  ChurchSettings copyWith({
    String? churchName,
    String? tagline,
    String? logoUrl,
    String? aboutHeadline,
    String? aboutBody,
    String? beliefs,
    String? visitInfo,
    String? releasesRepo,
    BrandColors? colors,
    ContactInfo? contact,
    SocialLinks? social,
    List<ServiceTime>? serviceTimes,
    FeatureFlags? features,
  }) {
    return ChurchSettings(
      churchName: churchName ?? this.churchName,
      tagline: tagline ?? this.tagline,
      logoUrl: logoUrl ?? this.logoUrl,
      aboutHeadline: aboutHeadline ?? this.aboutHeadline,
      aboutBody: aboutBody ?? this.aboutBody,
      beliefs: beliefs ?? this.beliefs,
      visitInfo: visitInfo ?? this.visitInfo,
      releasesRepo: releasesRepo ?? this.releasesRepo,
      colors: colors ?? this.colors,
      contact: contact ?? this.contact,
      social: social ?? this.social,
      serviceTimes: serviceTimes ?? this.serviceTimes,
      features: features ?? this.features,
    );
  }

  /// Last-resort defaults, used only if even the bundled asset fails to
  /// load. Keeps the app renderable rather than crashing on a bad deploy.
  static const ChurchSettings fallback = ChurchSettings(
    churchName: 'Yoked Church',
    tagline: 'Take my yoke upon you, and learn from me.',
    colors: BrandColors.fallback,
    contact: ContactInfo.fallback,
    social: SocialLinks.fallback,
    serviceTimes: [],
    features: FeatureFlags.fallback,
  );

  static Map<String, dynamic> _sub(Object? value) =>
      value is Map ? value.cast<String, dynamic>() : const <String, dynamic>{};
}

@immutable
class BrandColors {
  final Color primary;
  final Color accent;
  final Color background;

  const BrandColors({required this.primary, required this.accent, required this.background});

  factory BrandColors.fromMap(Map<String, dynamic> map) {
    return BrandColors(
      primary: _color(map['primary'], fallback.primary),
      accent: _color(map['accent'], fallback.accent),
      background: _color(map['background'], fallback.background),
    );
  }

  Map<String, dynamic> toMap() => {
        'primary': _hex(primary),
        'accent': _hex(accent),
        'background': _hex(background),
      };

  static const BrandColors fallback = BrandColors(
    primary: Color(0xFF1B3A4B),
    accent: Color(0xFFC9A24B),
    background: Color(0xFFF7F5F0),
  );

  /// Accepts `"#RRGGBB"`, `"RRGGBB"`, `"#AARRGGBB"`, or a raw int, so a
  /// non-technical admin can paste a hex code from a brand guide.
  static Color _color(Object? raw, Color fallback) {
    if (raw is int) return Color(raw);
    if (raw is! String) return fallback;
    var hex = raw.trim().replaceFirst('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    final value = int.tryParse(hex, radix: 16);
    return value == null ? fallback : Color(value);
  }

  static String _hex(Color color) =>
      '#${(color.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';
}

@immutable
class ContactInfo {
  final String address;
  final String phone;
  final String email;
  final String mapUrl;

  const ContactInfo({required this.address, required this.phone, required this.email, required this.mapUrl});

  factory ContactInfo.fromMap(Map<String, dynamic> map) => ContactInfo(
        address: map['address'] as String? ?? '',
        phone: map['phone'] as String? ?? '',
        email: map['email'] as String? ?? '',
        mapUrl: map['mapUrl'] as String? ?? '',
      );

  Map<String, dynamic> toMap() => {'address': address, 'phone': phone, 'email': email, 'mapUrl': mapUrl};

  static const ContactInfo fallback = ContactInfo(address: '', phone: '', email: '', mapUrl: '');
}

@immutable
class SocialLinks {
  final String facebook;
  final String instagram;
  final String youtube;
  final String givingUrl;
  final String liveStreamUrl;

  /// The church's YouTube channel id, e.g. `UCxxxxxxxxxxxxxxxxxxxxxx`.
  ///
  /// Not a URL and not a handle: the scheduled poller reads the channel's
  /// RSS feed, which is keyed by id. Empty means this church is not
  /// polled at all, which is the right default - a church that never
  /// streams should cost nothing.
  final String youtubeChannelId;

  /// An existing feed on Anchor, Buzzsprout, Spotify, wherever. A
  /// podcast feed has to be static XML at a fixed URL that Apple and
  /// Spotify poll on a schedule; a client-side build on static hosting
  /// cannot serve one, so this links out rather than pretending.
  final String podcastUrl;

  const SocialLinks({
    required this.facebook,
    required this.instagram,
    required this.youtube,
    required this.givingUrl,
    required this.liveStreamUrl,
    this.youtubeChannelId = '',
    this.podcastUrl = '',
  });

  factory SocialLinks.fromMap(Map<String, dynamic> map) => SocialLinks(
        facebook: map['facebook'] as String? ?? '',
        instagram: map['instagram'] as String? ?? '',
        youtube: map['youtube'] as String? ?? '',
        givingUrl: map['givingUrl'] as String? ?? '',
        liveStreamUrl: map['liveStreamUrl'] as String? ?? '',
        youtubeChannelId: map['youtubeChannelId'] as String? ?? '',
        podcastUrl: map['podcastUrl'] as String? ?? '',
      );

  Map<String, dynamic> toMap() => {
        'facebook': facebook,
        'instagram': instagram,
        'youtube': youtube,
        'givingUrl': givingUrl,
        'liveStreamUrl': liveStreamUrl,
        'youtubeChannelId': youtubeChannelId,
        'podcastUrl': podcastUrl,
      };

  static const SocialLinks fallback =
      SocialLinks(facebook: '', instagram: '', youtube: '', givingUrl: '', liveStreamUrl: '');
}

@immutable
class ServiceTime {
  final String day;
  final String time;
  final String label;

  const ServiceTime({required this.day, required this.time, required this.label});

  factory ServiceTime.fromMap(Map<String, dynamic> map) => ServiceTime(
        day: map['day'] as String? ?? '',
        time: map['time'] as String? ?? '',
        label: map['label'] as String? ?? '',
      );

  Map<String, dynamic> toMap() => {'day': day, 'time': time, 'label': label};
}

/// Per-church on/off switches. A church that doesn't run, say, kids
/// check-in simply never sees it - no code change, no dead nav links.
@immutable
class FeatureFlags {
  final bool sermons;
  final bool events;
  final bool giving;
  final bool connect;
  final bool groups;
  final bool volunteering;
  final bool prayerWall;
  final bool readingPlans;
  final bool devotionals;
  final bool resources;
  final bool kidsCheckIn;
  final bool roomBooking;
  final bool attendance;
  final bool forms;

  /// The download page for the installable macOS, Windows, Linux and
  /// Android builds. Off for a church that only ever wants the website.
  final bool appDownloads;

  const FeatureFlags({
    this.sermons = true,
    this.events = true,
    this.giving = true,
    this.connect = true,
    this.groups = true,
    this.volunteering = true,
    this.prayerWall = true,
    this.readingPlans = true,
    this.devotionals = true,
    this.resources = true,
    this.kidsCheckIn = true,
    this.roomBooking = true,
    this.attendance = true,
    this.forms = true,
    this.appDownloads = true,
  });

  factory FeatureFlags.fromMap(Map<String, dynamic> map) => FeatureFlags(
        sermons: map['sermons'] as bool? ?? true,
        events: map['events'] as bool? ?? true,
        giving: map['giving'] as bool? ?? true,
        connect: map['connect'] as bool? ?? true,
        groups: map['groups'] as bool? ?? true,
        volunteering: map['volunteering'] as bool? ?? true,
        prayerWall: map['prayerWall'] as bool? ?? true,
        readingPlans: map['readingPlans'] as bool? ?? true,
        devotionals: map['devotionals'] as bool? ?? true,
        resources: map['resources'] as bool? ?? true,
        kidsCheckIn: map['kidsCheckIn'] as bool? ?? true,
        roomBooking: map['roomBooking'] as bool? ?? true,
        attendance: map['attendance'] as bool? ?? true,
        forms: map['forms'] as bool? ?? true,
        appDownloads: map['appDownloads'] as bool? ?? true,
      );

  Map<String, dynamic> toMap() => {
        'sermons': sermons,
        'events': events,
        'giving': giving,
        'connect': connect,
        'groups': groups,
        'volunteering': volunteering,
        'prayerWall': prayerWall,
        'readingPlans': readingPlans,
        'devotionals': devotionals,
        'resources': resources,
        'kidsCheckIn': kidsCheckIn,
        'roomBooking': roomBooking,
        'attendance': attendance,
        'forms': forms,
        'appDownloads': appDownloads,
      };

  FeatureFlags copyWithEntry(String key, bool value) {
    final map = toMap()..[key] = value;
    return FeatureFlags.fromMap(map);
  }

  static const FeatureFlags fallback = FeatureFlags();
}
