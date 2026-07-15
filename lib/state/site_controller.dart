import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/default_site_data.dart';
import '../models/church_config.dart';
import '../models/church_event.dart';
import '../models/giving_fund.dart';
import '../models/ministry.dart';
import '../models/sermon.dart';
import '../models/service_time.dart';
import '../models/site_data.dart';
import '../models/social_link.dart';
import '../models/staff_member.dart';

/// Owns the entire church [SiteData] and persists every change locally.
///
/// All UI reads from here, so any edit an admin makes instantly re-brands and
/// re-populates the public app.
class SiteController extends ChangeNotifier {
  static const _prefsKey = 'yoked_site_data_v1';

  SiteData _data = DefaultSiteData.build();
  bool _loaded = false;

  SiteData get data => _data;
  ChurchConfig get config => _data.config;
  List<Sermon> get sermons => _data.sermons;
  List<ChurchEvent> get events => _data.events;
  List<Ministry> get ministries => _data.ministries;
  List<StaffMember> get staff => _data.staff;
  bool get isLoaded => _loaded;

  List<ChurchEvent> get upcomingEvents {
    final now = DateTime.now();
    final list = _data.events
        .where((e) => (e.end ?? e.start).isAfter(now))
        .toList()
      ..sort((a, b) => a.start.compareTo(b.start));
    return list;
  }

  List<Sermon> get sermonsByNewest {
    final list = List<Sermon>.from(_data.sermons)
      ..sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw != null && raw.isNotEmpty) {
        final json = jsonDecode(raw) as Map<String, dynamic>;
        _data = SiteData.fromJson(json);
      }
    } catch (e) {
      debugPrint('SiteController.load failed, using defaults: $e');
      _data = DefaultSiteData.build();
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> _persist() async {
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, jsonEncode(_data.toJson()));
    } catch (e) {
      debugPrint('SiteController.persist failed: $e');
    }
  }

  // --- Config ---------------------------------------------------------------
  Future<void> updateConfig(ChurchConfig config) async {
    _data = _data.copyWith(config: config);
    await _persist();
  }

  // --- Import / export / reset ---------------------------------------------
  String exportJson() =>
      const JsonEncoder.withIndent('  ').convert(_data.toJson());

  /// Returns null on success or an error message on failure.
  Future<String?> importJson(String raw) async {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        return 'Expected a JSON object.';
      }
      // Accept either a full SiteData payload or a bare ChurchConfig.
      if (decoded.containsKey('config')) {
        _data = SiteData.fromJson(decoded);
      } else if (decoded.containsKey('churchName')) {
        _data = _data.copyWith(config: ChurchConfig.fromJson(decoded));
      } else {
        return 'Unrecognized configuration format.';
      }
      await _persist();
      return null;
    } catch (e) {
      return 'Could not parse JSON: $e';
    }
  }

  Future<void> resetToDefault() async {
    _data = DefaultSiteData.build();
    await _persist();
  }

  Future<void> clearAll() async {
    _data = SiteData(
      config: const ChurchConfig(churchName: 'Your Church'),
    );
    await _persist();
  }

  // --- Sermons --------------------------------------------------------------
  Future<void> upsertSermon(Sermon sermon) async {
    final list = List<Sermon>.from(_data.sermons);
    final i = list.indexWhere((s) => s.id == sermon.id);
    if (i >= 0) {
      list[i] = sermon;
    } else {
      list.add(sermon);
    }
    _data = _data.copyWith(sermons: list);
    await _persist();
  }

  Future<void> deleteSermon(String id) async {
    _data = _data.copyWith(
      sermons: _data.sermons.where((s) => s.id != id).toList(),
    );
    await _persist();
  }

  // --- Events ---------------------------------------------------------------
  Future<void> upsertEvent(ChurchEvent event) async {
    final list = List<ChurchEvent>.from(_data.events);
    final i = list.indexWhere((e) => e.id == event.id);
    if (i >= 0) {
      list[i] = event;
    } else {
      list.add(event);
    }
    _data = _data.copyWith(events: list);
    await _persist();
  }

  Future<void> deleteEvent(String id) async {
    _data = _data.copyWith(
      events: _data.events.where((e) => e.id != id).toList(),
    );
    await _persist();
  }

  // --- Ministries -----------------------------------------------------------
  Future<void> upsertMinistry(Ministry ministry) async {
    final list = List<Ministry>.from(_data.ministries);
    final i = list.indexWhere((m) => m.id == ministry.id);
    if (i >= 0) {
      list[i] = ministry;
    } else {
      list.add(ministry);
    }
    _data = _data.copyWith(ministries: list);
    await _persist();
  }

  Future<void> deleteMinistry(String id) async {
    _data = _data.copyWith(
      ministries: _data.ministries.where((m) => m.id != id).toList(),
    );
    await _persist();
  }

  // --- Staff ----------------------------------------------------------------
  Future<void> upsertStaff(StaffMember member) async {
    final list = List<StaffMember>.from(_data.staff);
    final i = list.indexWhere((s) => s.id == member.id);
    if (i >= 0) {
      list[i] = member;
    } else {
      list.add(member);
    }
    _data = _data.copyWith(staff: list);
    await _persist();
  }

  Future<void> deleteStaff(String id) async {
    _data = _data.copyWith(
      staff: _data.staff.where((s) => s.id != id).toList(),
    );
    await _persist();
  }

  // --- Config sub-collections ----------------------------------------------
  Future<void> setServiceTimes(List<ServiceTime> times) =>
      updateConfig(_data.config.copyWith(serviceTimes: times));

  Future<void> setSocialLinks(List<SocialLink> links) =>
      updateConfig(_data.config.copyWith(socialLinks: links));

  Future<void> setGivingFunds(List<GivingFund> funds) =>
      updateConfig(_data.config.copyWith(givingFunds: funds));
}
