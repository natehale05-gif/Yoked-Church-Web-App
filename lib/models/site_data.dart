import 'church_config.dart';
import 'sermon.dart';
import 'church_event.dart';
import 'ministry.dart';
import 'staff_member.dart';

/// The complete data payload for a provisioned church: branding/config plus all
/// editable content. This is what gets exported/imported as a single JSON blob
/// so a church can be set up (and sold) from an external admin website.
class SiteData {
  final ChurchConfig config;
  final List<Sermon> sermons;
  final List<ChurchEvent> events;
  final List<Ministry> ministries;
  final List<StaffMember> staff;

  const SiteData({
    required this.config,
    this.sermons = const [],
    this.events = const [],
    this.ministries = const [],
    this.staff = const [],
  });

  SiteData copyWith({
    ChurchConfig? config,
    List<Sermon>? sermons,
    List<ChurchEvent>? events,
    List<Ministry>? ministries,
    List<StaffMember>? staff,
  }) {
    return SiteData(
      config: config ?? this.config,
      sermons: sermons ?? this.sermons,
      events: events ?? this.events,
      ministries: ministries ?? this.ministries,
      staff: staff ?? this.staff,
    );
  }

  Map<String, dynamic> toJson() => {
        'version': 1,
        'config': config.toJson(),
        'sermons': sermons.map((e) => e.toJson()).toList(),
        'events': events.map((e) => e.toJson()).toList(),
        'ministries': ministries.map((e) => e.toJson()).toList(),
        'staff': staff.map((e) => e.toJson()).toList(),
      };

  factory SiteData.fromJson(Map<String, dynamic> json) {
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

    return SiteData(
      config: ChurchConfig.fromJson(
        (json['config'] as Map?)?.cast<String, dynamic>() ?? const {},
      ),
      sermons: parseList('sermons', Sermon.fromJson),
      events: parseList('events', ChurchEvent.fromJson),
      ministries: parseList('ministries', Ministry.fromJson),
      staff: parseList('staff', StaffMember.fromJson),
    );
  }
}
