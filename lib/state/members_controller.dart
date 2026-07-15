import 'package:flutter/foundation.dart';

import '../data/local_store.dart';
import '../data/seed.dart';
import '../models/member.dart';

class MembersController extends ChangeNotifier {
  MembersController(this._store) {
    if (_store.contains(_key)) {
      _members = _store.readList(_key).map(Member.fromJson).toList();
    } else {
      _members = defaultMembers();
      _persist();
    }
  }

  static const _key = 'members';
  final LocalStore _store;
  late List<Member> _members;

  List<Member> get members {
    final list = [..._members];
    list.sort((a, b) => a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()));
    return list;
  }

  int get count => _members.length;
  int countByStatus(MemberStatus status) =>
      _members.where((m) => m.status == status).length;

  Member? byId(String? id) {
    if (id == null) return null;
    for (final m in _members) {
      if (m.id == id) return m;
    }
    return null;
  }

  Future<void> upsert(Member member) async {
    final i = _members.indexWhere((m) => m.id == member.id);
    if (i >= 0) {
      _members[i] = member;
    } else {
      _members.add(member);
    }
    await _persist();
    notifyListeners();
  }

  Future<void> remove(String id) async {
    _members.removeWhere((m) => m.id == id);
    await _persist();
    notifyListeners();
  }

  Future<void> _persist() =>
      _store.writeList(_key, _members.map((m) => m.toJson()).toList());
}
