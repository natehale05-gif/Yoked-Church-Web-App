import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' show User, FirebaseAuthException;
import 'package:flutter/foundation.dart';

import '../config/church_config.dart';
import '../models/app_user.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';

/// Central auth/session state, exposed to the widget tree via
/// `ChangeNotifierProvider` and also passed as `go_router`'s
/// `refreshListenable` so route guards react to sign-in/out.
///
/// When [ChurchConfig.useFirebase] is false, this stays permanently
/// signed-out and never touches Firebase - the zero-backend demo mode
/// is unaffected.
class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();

  StreamSubscription<User?>? _authSub;
  StreamSubscription<AppUser?>? _profileSub;

  AppUser? _currentUser;
  bool _isLoading = ChurchConfig.useFirebase;

  AppUser? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isSignedIn => _currentUser != null;

  AuthProvider() {
    if (ChurchConfig.useFirebase) {
      _authSub = _authService.authStateChanges().listen(_onAuthChanged);
    }
  }

  Future<void> _onAuthChanged(User? firebaseUser) async {
    await _profileSub?.cancel();
    _profileSub = null;

    if (firebaseUser == null) {
      _currentUser = null;
      _isLoading = false;
      notifyListeners();
      return;
    }

    final profile = await _userService.ensureUserDoc(firebaseUser);
    _currentUser = profile;
    _isLoading = false;
    notifyListeners();

    _profileSub = _userService.watchUser(firebaseUser.uid).listen((updated) {
      _currentUser = updated;
      notifyListeners();
    });
  }

  Future<String?> signUp({required String email, required String password, required String displayName}) =>
      _guard(() => _authService.signUp(email: email, password: password, displayName: displayName));

  Future<String?> signIn({required String email, required String password}) =>
      _guard(() => _authService.signIn(email: email, password: password));

  Future<String?> signInWithGoogle() => _guard(_authService.signInWithGoogle);

  Future<String?> signInWithApple() => _guard(_authService.signInWithApple);

  Future<String?> sendPasswordResetEmail(String email) => _guard(() => _authService.sendPasswordResetEmail(email));

  Future<void> signOut() => _authService.signOut();

  /// Runs a Firebase auth call, translating [FirebaseAuthException] into a
  /// human-readable message. Returns null on success, an error message on
  /// failure - callers show the message rather than throwing.
  Future<String?> _guard(Future<void> Function() action) async {
    try {
      await action();
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message ?? 'Something went wrong (${e.code}).';
    }
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _profileSub?.cancel();
    super.dispose();
  }
}
