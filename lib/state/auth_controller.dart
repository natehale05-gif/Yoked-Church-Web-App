import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Lightweight admin authentication for the customization panel.
///
/// NOTE: This is a client-side gate suitable for a demo / single-tenant
/// deployment. Credentials are stored locally (hashed). A production, multi
/// tenant "sell from another website" flow should verify the admin against a
/// backend and provision the config server-side. The import/export JSON hooks
/// in [SiteController] are designed to plug into exactly that flow.
class AuthController extends ChangeNotifier {
  static const _userKey = 'yoked_admin_user_v1';
  static const _hashKey = 'yoked_admin_hash_v1';
  static const _sessionKey = 'yoked_admin_session_v1';

  static const defaultUsername = 'admin';
  static const defaultPassword = 'yoked-admin';

  bool _signedIn = false;
  String _username = defaultUsername;

  bool get isSignedIn => _signedIn;
  String get username => _username;

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _username = prefs.getString(_userKey) ?? defaultUsername;
      if (!prefs.containsKey(_hashKey)) {
        await prefs.setString(_hashKey, _hash(defaultPassword));
      }
      _signedIn = prefs.getBool(_sessionKey) ?? false;
    } catch (e) {
      debugPrint('AuthController.load failed: $e');
    }
    notifyListeners();
  }

  Future<bool> signIn(String username, String password) async {
    final prefs = await SharedPreferences.getInstance();
    final storedUser = prefs.getString(_userKey) ?? defaultUsername;
    final storedHash = prefs.getString(_hashKey) ?? _hash(defaultPassword);
    final ok = username.trim() == storedUser && _hash(password) == storedHash;
    if (ok) {
      _signedIn = true;
      _username = storedUser;
      await prefs.setBool(_sessionKey, true);
      notifyListeners();
    }
    return ok;
  }

  Future<void> signOut() async {
    _signedIn = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_sessionKey, false);
    notifyListeners();
  }

  Future<void> updateCredentials({
    required String username,
    String? newPassword,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    _username = username.trim().isEmpty ? _username : username.trim();
    await prefs.setString(_userKey, _username);
    if (newPassword != null && newPassword.isNotEmpty) {
      await prefs.setString(_hashKey, _hash(newPassword));
    }
    notifyListeners();
  }

  /// A tiny, dependency-free hash. Not cryptographically strong — see the class
  /// docs; adequate only to avoid storing the password in plain text locally.
  String _hash(String input) {
    const salt = 'yoked::v1::';
    final bytes = utf8.encode('$salt$input');
    var hash = 0x811c9dc5;
    for (final b in bytes) {
      hash ^= b;
      hash = (hash * 0x01000193) & 0xFFFFFFFF;
    }
    return hash.toRadixString(16).padLeft(8, '0');
  }
}
