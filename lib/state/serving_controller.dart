import 'package:flutter/foundation.dart';

import '../data/local_store.dart';
import '../data/seed.dart';
import '../models/serving.dart';

class ServingController extends ChangeNotifier {
  ServingController(this._store) {
    if (_store.contains(_teamsKey)) {
      _teams = _store.readList(_teamsKey).map(ServingTeam.fromJson).toList();
    } else {
      _teams = defaultServingTeams();
      _persistTeams();
    }
    if (_store.contains(_slotsKey)) {
      _slots = _store.readList(_slotsKey).map(ServingSlot.fromJson).toList();
    } else {
      _slots = defaultServingSlots();
      _persistSlots();
    }
  }

  static const _teamsKey = 'serving_teams';
  static const _slotsKey = 'serving_slots';
  final LocalStore _store;
  late List<ServingTeam> _teams;
  late List<ServingSlot> _slots;

  List<ServingTeam> get teams => List.unmodifiable(_teams);

  ServingTeam? teamById(String id) {
    for (final t in _teams) {
      if (t.id == id) return t;
    }
    return null;
  }

  /// Upcoming slots (today onward), earliest first.
  List<ServingSlot> get upcomingSlots {
    final today = DateTime.now().subtract(const Duration(days: 1));
    final list = _slots.where((s) => s.date.isAfter(today)).toList();
    list.sort((a, b) => a.date.compareTo(b.date));
    return list;
  }

  List<ServingSlot> slotsForTeam(String teamId) {
    final list = _slots.where((s) => s.teamId == teamId).toList();
    list.sort((a, b) => a.date.compareTo(b.date));
    return list;
  }

  List<ServingSlot> slotsForMember(String memberId) {
    final list =
        _slots.where((s) => s.memberIds.contains(memberId)).toList();
    list.sort((a, b) => a.date.compareTo(b.date));
    return list;
  }

  int get openSlotCount =>
      upcomingSlots.fold<int>(0, (a, s) => a + s.remaining);

  // --- Teams ---
  Future<void> upsertTeam(ServingTeam team) async {
    final i = _teams.indexWhere((t) => t.id == team.id);
    if (i >= 0) {
      _teams[i] = team;
    } else {
      _teams.add(team);
    }
    await _persistTeams();
    notifyListeners();
  }

  Future<void> removeTeam(String id) async {
    _teams.removeWhere((t) => t.id == id);
    _slots.removeWhere((s) => s.teamId == id);
    await _persistTeams();
    await _persistSlots();
    notifyListeners();
  }

  // --- Slots ---
  Future<void> upsertSlot(ServingSlot slot) async {
    final i = _slots.indexWhere((s) => s.id == slot.id);
    if (i >= 0) {
      _slots[i] = slot;
    } else {
      _slots.add(slot);
    }
    await _persistSlots();
    notifyListeners();
  }

  Future<void> removeSlot(String id) async {
    _slots.removeWhere((s) => s.id == id);
    await _persistSlots();
    notifyListeners();
  }

  Future<void> toggleSignup(String slotId, String memberId) async {
    final i = _slots.indexWhere((s) => s.id == slotId);
    if (i < 0) return;
    final slot = _slots[i];
    final ids = [...slot.memberIds];
    if (ids.contains(memberId)) {
      ids.remove(memberId);
    } else {
      if (slot.isFull) return;
      ids.add(memberId);
    }
    _slots[i] = slot.copyWith(memberIds: ids);
    await _persistSlots();
    notifyListeners();
  }

  Future<void> _persistTeams() =>
      _store.writeList(_teamsKey, _teams.map((t) => t.toJson()).toList());
  Future<void> _persistSlots() =>
      _store.writeList(_slotsKey, _slots.map((s) => s.toJson()).toList());
}
