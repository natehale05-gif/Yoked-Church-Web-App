import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:yoked_church/data/default_site_data.dart';
import 'package:yoked_church/models/church_config.dart';
import 'package:yoked_church/models/site_data.dart';

void main() {
  test('ChurchConfig round-trips through JSON', () {
    const config = ChurchConfig(
      churchName: 'Test Church',
      tagline: 'Hello',
      primaryColorHex: '#FF112233',
      cornerRadius: 12,
      showEvents: false,
    );

    final json = jsonEncode(config.toJson());
    final restored = ChurchConfig.fromJson(
        jsonDecode(json) as Map<String, dynamic>);

    expect(restored.churchName, 'Test Church');
    expect(restored.tagline, 'Hello');
    expect(restored.primaryColorHex, '#FF112233');
    expect(restored.cornerRadius, 12);
    expect(restored.showEvents, isFalse);
  });

  test('Default site data round-trips through SiteData JSON', () {
    final data = DefaultSiteData.build();
    final json = jsonEncode(data.toJson());
    final restored =
        SiteData.fromJson(jsonDecode(json) as Map<String, dynamic>);

    expect(restored.config.churchName, data.config.churchName);
    expect(restored.sermons.length, data.sermons.length);
    expect(restored.events.length, data.events.length);
    expect(restored.ministries.length, data.ministries.length);
    expect(restored.staff.length, data.staff.length);
  });

  test('Bare config JSON is accepted and defaults fill the rest', () {
    final restored = ChurchConfig.fromJson({'churchName': 'Only Name'});
    expect(restored.churchName, 'Only Name');
    expect(restored.showGiving, isTrue);
    expect(restored.givingFunds, isEmpty);
  });
}
