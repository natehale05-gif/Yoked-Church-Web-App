import 'package:flutter/foundation.dart';

import '../data/auth_hash.dart';
import '../data/local_store.dart';
import '../data/seed.dart';
import '../models/app_user.dart';

class AuthController extends ChangeNotifier {
  AuthController(this._store) {
    if (_store.contains(_usersKey)) {
      _users = _store.readList(_usersKey).map(AppUser.fromJson).toList();
    } else {
      _users = defaultUsers();
      _persistUsers();
    }
    final sessionId = _store.readMap(_sessionKey)?['userId'] as String?;
    if (sessionId != null) {
      _current = _byId(sessionId);
    }
  }

  static const _usersKey = 'users';
  static const _sessionKey = 'session';
  final LocalStore _store;
  late List<AppUser> _users;
  AppUser? _current;

  AppUser? get currentUser => _current;
  bool get isSignedIn => _current != null;
  bool get isStaff => _current?.role == UserRole.staff;
  bool get isMember => _current?.role == UserRole.member;

  AppUser? _byId(String id) {
    for (final u in _users) {
      if (u.id == id) return u;
    }
    return null;
  }

  AppUser? _byEmail(String email) {
    final e = email.trim().toLowerCase();
    for (final u in _users) {
      if (u.email.toLowerCase() == e) return u;
    }
    return null;
  }

  bool emailExists(String email) => _byEmail(email) != null;

  /// Returns null on success, or an error message on failure.
  Future<String?> signIn(String email, String password) async {
    final user = _byEmail(email);
    if (user == null) return 'We could not find an account with that email.';
    if (!verifyPassword(password, user.passwordHash)) {
      return 'That password does not match. Please try again.';
    }
    _current = user;
    await _store.writeMap(_sessionKey, {'userId': user.id});
    notifyListeners();
    return null;
  }

  /// Registers a new member account. Returns the created user, or null if the
  /// email is already taken.
  Future<AppUser?> registerMember({
    required String name,
    required String email,
    required String password,
    required String memberId,
  }) async {
    if (emailExists(email)) return null;
    final user = AppUser(
      name: name,
      email: email.trim(),
      role: UserRole.member,
      passwordHash: hashPassword(password),
      memberId: memberId,
    );
    _users.add(user);
    _current = user;
    await _persistUsers();
    await _store.writeMap(_sessionKey, {'userId': user.id});
    notifyListeners();
    return user;
  }

  Future<void> signOut() async {
    _current = null;
    await _store.remove(_sessionKey);
    notifyListeners();
  }

  Future<void> _persistUsers() =>
      _store.writeList(_usersKey, _users.map((u) => u.toJson()).toList());
}
