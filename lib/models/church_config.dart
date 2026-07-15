import 'service_time.dart';
import 'social_link.dart';
import 'giving_fund.dart';

/// The full, JSON-serializable configuration that turns this generic app into
/// a specific church's branded website + app.
///
/// A seller/admin provisions a church by producing one of these objects
/// (typically exported as JSON from the "another website" mentioned in the
/// product brief) and loading it into the app.
class ChurchConfig {
  // --- Identity ---
  final String churchName;
  final String tagline;
  final String logoInitials;
  final String logoImageUrl;

  // --- Branding ---
  final String primaryColorHex;
  final String secondaryColorHex;
  final String accentColorHex;
  final String fontFamily;
  final double cornerRadius;
  final bool darkMode;

  // --- Hero ---
  final String heroTitle;
  final String heroSubtitle;
  final String heroCtaLabel;
  final String heroCtaUrl;
  final String heroImageUrl;

  // --- Welcome / About ---
  final String welcomeTitle;
  final String welcomeBody;
  final String aboutTitle;
  final String aboutBody;
  final String missionStatement;
  final List<String> beliefs;

  // --- Contact ---
  final String address;
  final String phone;
  final String email;
  final String mapUrl;

  // --- Media / Giving ---
  final String liveStreamUrl;
  final String givingTitle;
  final String givingBody;
  final String primaryGiveUrl;
  final List<GivingFund> givingFunds;

  final List<ServiceTime> serviceTimes;
  final List<SocialLink> socialLinks;

  // --- Feature toggles (which sections the church wants enabled) ---
  final bool showAbout;
  final bool showSermons;
  final bool showEvents;
  final bool showMinistries;
  final bool showGiving;
  final bool showContact;
  final bool showLiveStream;

  final String footerNote;

  const ChurchConfig({
    required this.churchName,
    this.tagline = '',
    this.logoInitials = '',
    this.logoImageUrl = '',
    this.primaryColorHex = '#FF3D5AFE',
    this.secondaryColorHex = '#FF00BFA5',
    this.accentColorHex = '#FFFFAB00',
    this.fontFamily = 'Poppins',
    this.cornerRadius = 24,
    this.darkMode = false,
    this.heroTitle = '',
    this.heroSubtitle = '',
    this.heroCtaLabel = 'Plan Your Visit',
    this.heroCtaUrl = '',
    this.heroImageUrl = '',
    this.welcomeTitle = '',
    this.welcomeBody = '',
    this.aboutTitle = '',
    this.aboutBody = '',
    this.missionStatement = '',
    this.beliefs = const [],
    this.address = '',
    this.phone = '',
    this.email = '',
    this.mapUrl = '',
    this.liveStreamUrl = '',
    this.givingTitle = 'Give',
    this.givingBody = '',
    this.primaryGiveUrl = '',
    this.givingFunds = const [],
    this.serviceTimes = const [],
    this.socialLinks = const [],
    this.showAbout = true,
    this.showSermons = true,
    this.showEvents = true,
    this.showMinistries = true,
    this.showGiving = true,
    this.showContact = true,
    this.showLiveStream = true,
    this.footerNote = '',
  });

  ChurchConfig copyWith({
    String? churchName,
    String? tagline,
    String? logoInitials,
    String? logoImageUrl,
    String? primaryColorHex,
    String? secondaryColorHex,
    String? accentColorHex,
    String? fontFamily,
    double? cornerRadius,
    bool? darkMode,
    String? heroTitle,
    String? heroSubtitle,
    String? heroCtaLabel,
    String? heroCtaUrl,
    String? heroImageUrl,
    String? welcomeTitle,
    String? welcomeBody,
    String? aboutTitle,
    String? aboutBody,
    String? missionStatement,
    List<String>? beliefs,
    String? address,
    String? phone,
    String? email,
    String? mapUrl,
    String? liveStreamUrl,
    String? givingTitle,
    String? givingBody,
    String? primaryGiveUrl,
    List<GivingFund>? givingFunds,
    List<ServiceTime>? serviceTimes,
    List<SocialLink>? socialLinks,
    bool? showAbout,
    bool? showSermons,
    bool? showEvents,
    bool? showMinistries,
    bool? showGiving,
    bool? showContact,
    bool? showLiveStream,
    String? footerNote,
  }) {
    return ChurchConfig(
      churchName: churchName ?? this.churchName,
      tagline: tagline ?? this.tagline,
      logoInitials: logoInitials ?? this.logoInitials,
      logoImageUrl: logoImageUrl ?? this.logoImageUrl,
      primaryColorHex: primaryColorHex ?? this.primaryColorHex,
      secondaryColorHex: secondaryColorHex ?? this.secondaryColorHex,
      accentColorHex: accentColorHex ?? this.accentColorHex,
      fontFamily: fontFamily ?? this.fontFamily,
      cornerRadius: cornerRadius ?? this.cornerRadius,
      darkMode: darkMode ?? this.darkMode,
      heroTitle: heroTitle ?? this.heroTitle,
      heroSubtitle: heroSubtitle ?? this.heroSubtitle,
      heroCtaLabel: heroCtaLabel ?? this.heroCtaLabel,
      heroCtaUrl: heroCtaUrl ?? this.heroCtaUrl,
      heroImageUrl: heroImageUrl ?? this.heroImageUrl,
      welcomeTitle: welcomeTitle ?? this.welcomeTitle,
      welcomeBody: welcomeBody ?? this.welcomeBody,
      aboutTitle: aboutTitle ?? this.aboutTitle,
      aboutBody: aboutBody ?? this.aboutBody,
      missionStatement: missionStatement ?? this.missionStatement,
      beliefs: beliefs ?? this.beliefs,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      mapUrl: mapUrl ?? this.mapUrl,
      liveStreamUrl: liveStreamUrl ?? this.liveStreamUrl,
      givingTitle: givingTitle ?? this.givingTitle,
      givingBody: givingBody ?? this.givingBody,
      primaryGiveUrl: primaryGiveUrl ?? this.primaryGiveUrl,
      givingFunds: givingFunds ?? this.givingFunds,
      serviceTimes: serviceTimes ?? this.serviceTimes,
      socialLinks: socialLinks ?? this.socialLinks,
      showAbout: showAbout ?? this.showAbout,
      showSermons: showSermons ?? this.showSermons,
      showEvents: showEvents ?? this.showEvents,
      showMinistries: showMinistries ?? this.showMinistries,
      showGiving: showGiving ?? this.showGiving,
      showContact: showContact ?? this.showContact,
      showLiveStream: showLiveStream ?? this.showLiveStream,
      footerNote: footerNote ?? this.footerNote,
    );
  }

  Map<String, dynamic> toJson() => {
        'churchName': churchName,
        'tagline': tagline,
        'logoInitials': logoInitials,
        'logoImageUrl': logoImageUrl,
        'primaryColorHex': primaryColorHex,
        'secondaryColorHex': secondaryColorHex,
        'accentColorHex': accentColorHex,
        'fontFamily': fontFamily,
        'cornerRadius': cornerRadius,
        'darkMode': darkMode,
        'heroTitle': heroTitle,
        'heroSubtitle': heroSubtitle,
        'heroCtaLabel': heroCtaLabel,
        'heroCtaUrl': heroCtaUrl,
        'heroImageUrl': heroImageUrl,
        'welcomeTitle': welcomeTitle,
        'welcomeBody': welcomeBody,
        'aboutTitle': aboutTitle,
        'aboutBody': aboutBody,
        'missionStatement': missionStatement,
        'beliefs': beliefs,
        'address': address,
        'phone': phone,
        'email': email,
        'mapUrl': mapUrl,
        'liveStreamUrl': liveStreamUrl,
        'givingTitle': givingTitle,
        'givingBody': givingBody,
        'primaryGiveUrl': primaryGiveUrl,
        'givingFunds': givingFunds.map((e) => e.toJson()).toList(),
        'serviceTimes': serviceTimes.map((e) => e.toJson()).toList(),
        'socialLinks': socialLinks.map((e) => e.toJson()).toList(),
        'showAbout': showAbout,
        'showSermons': showSermons,
        'showEvents': showEvents,
        'showMinistries': showMinistries,
        'showGiving': showGiving,
        'showContact': showContact,
        'showLiveStream': showLiveStream,
        'footerNote': footerNote,
      };

  factory ChurchConfig.fromJson(Map<String, dynamic> json) {
    List<T> parseList<T>(
      String key,
      T Function(Map<String, dynamic>) fromJson,
    ) {
      final raw = json[key];
      if (raw is! List) return <T>[];
      return raw
          .whereType<Map<String, dynamic>>()
          .map(fromJson)
          .toList(growable: false);
    }

    return ChurchConfig(
      churchName: json['churchName'] as String? ?? 'Your Church',
      tagline: json['tagline'] as String? ?? '',
      logoInitials: json['logoInitials'] as String? ?? '',
      logoImageUrl: json['logoImageUrl'] as String? ?? '',
      primaryColorHex: json['primaryColorHex'] as String? ?? '#FF3D5AFE',
      secondaryColorHex: json['secondaryColorHex'] as String? ?? '#FF00BFA5',
      accentColorHex: json['accentColorHex'] as String? ?? '#FFFFAB00',
      fontFamily: json['fontFamily'] as String? ?? 'Poppins',
      cornerRadius: (json['cornerRadius'] as num?)?.toDouble() ?? 24,
      darkMode: json['darkMode'] as bool? ?? false,
      heroTitle: json['heroTitle'] as String? ?? '',
      heroSubtitle: json['heroSubtitle'] as String? ?? '',
      heroCtaLabel: json['heroCtaLabel'] as String? ?? 'Plan Your Visit',
      heroCtaUrl: json['heroCtaUrl'] as String? ?? '',
      heroImageUrl: json['heroImageUrl'] as String? ?? '',
      welcomeTitle: json['welcomeTitle'] as String? ?? '',
      welcomeBody: json['welcomeBody'] as String? ?? '',
      aboutTitle: json['aboutTitle'] as String? ?? '',
      aboutBody: json['aboutBody'] as String? ?? '',
      missionStatement: json['missionStatement'] as String? ?? '',
      beliefs: (json['beliefs'] as List?)?.whereType<String>().toList() ??
          const [],
      address: json['address'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      email: json['email'] as String? ?? '',
      mapUrl: json['mapUrl'] as String? ?? '',
      liveStreamUrl: json['liveStreamUrl'] as String? ?? '',
      givingTitle: json['givingTitle'] as String? ?? 'Give',
      givingBody: json['givingBody'] as String? ?? '',
      primaryGiveUrl: json['primaryGiveUrl'] as String? ?? '',
      givingFunds: parseList('givingFunds', GivingFund.fromJson),
      serviceTimes: parseList('serviceTimes', ServiceTime.fromJson),
      socialLinks: parseList('socialLinks', SocialLink.fromJson),
      showAbout: json['showAbout'] as bool? ?? true,
      showSermons: json['showSermons'] as bool? ?? true,
      showEvents: json['showEvents'] as bool? ?? true,
      showMinistries: json['showMinistries'] as bool? ?? true,
      showGiving: json['showGiving'] as bool? ?? true,
      showContact: json['showContact'] as bool? ?? true,
      showLiveStream: json['showLiveStream'] as bool? ?? true,
      footerNote: json['footerNote'] as String? ?? '',
    );
  }
}
