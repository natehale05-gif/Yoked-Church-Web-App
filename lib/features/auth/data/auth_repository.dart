import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;

import '../domain/app_user.dart';
import 'user_repository.dart';

/// Raised for any sign-in/sign-up failure, already carrying a message
/// that is safe and useful to show a member.
class AuthFailure implements Exception {
  final String message;

  const AuthFailure(this.message);

  @override
  String toString() => message;
}

abstract interface class AuthRepository {
  Stream<AppUser?> authStateChanges();

  Future<void> signIn({required String email, required String password});
  Future<void> signUp({required String email, required String password, required String displayName});
  Future<void> signInWithGoogle();
  Future<void> signInWithApple();
  Future<void> sendPasswordReset(String email);
  Future<void> signOut();

  /// False in demo mode, where there is no OAuth provider to talk to.
  bool get supportsSocialSignIn;

  /// True when running on bundled content with no real accounts. The UI
  /// uses this to offer role previews and to say plainly that nothing is
  /// being saved anywhere.
  bool get isDemo;

  /// Demo-only: preview the app as a given role. Throws elsewhere.
  Future<void> signInAsDemo(UserRole role);
}

class FirebaseAuthRepository implements AuthRepository {
  fb.FirebaseAuth get _auth => fb.FirebaseAuth.instance;
  CollectionReference<Map<String, dynamic>> get _users => FirebaseFirestore.instance.collection('users');

  @override
  bool get supportsSocialSignIn => true;

  @override
  bool get isDemo => false;

  /// Emits the signed-in member's profile, and keeps emitting when their
  /// profile document changes - so a role change by an admin takes effect
  /// without the member signing out and back in.
  @override
  Stream<AppUser?> authStateChanges() {
    return _auth.authStateChanges().asyncExpand((firebaseUser) {
      if (firebaseUser == null) return Stream<AppUser?>.value(null);
      return _ensureProfile(firebaseUser).asStream().asyncExpand(
            (_) => _users.doc(firebaseUser.uid).snapshots().map(
                  (snap) => snap.data() == null ? null : AppUser.fromMap(firebaseUser.uid, snap.data()!),
                ),
          );
    });
  }

  /// Creates the profile document on first sign-in. New accounts always
  /// start as `member`; the Firestore rules reject anything else, so a
  /// tampered client cannot self-promote.
  Future<void> _ensureProfile(fb.User firebaseUser) async {
    final ref = _users.doc(firebaseUser.uid);
    if ((await ref.get()).exists) return;

    final user = AppUser(
      uid: firebaseUser.uid,
      email: firebaseUser.email ?? '',
      displayName: firebaseUser.displayName?.trim().isNotEmpty == true
          ? firebaseUser.displayName!
          : (firebaseUser.email ?? 'Member'),
      photoUrl: firebaseUser.photoURL ?? '',
      createdAt: DateTime.now(),
    );
    await ref.set(user.toMap());
  }

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on fb.FirebaseAuthException catch (e) {
      throw AuthFailure(_friendly(e));
    }
  }

  static String _friendly(fb.FirebaseAuthException e) => switch (e.code) {
        'invalid-email' => "That doesn't look like a valid email address.",
        'user-disabled' => 'That account has been disabled. Please contact the church office.',
        'user-not-found' || 'wrong-password' || 'invalid-credential' =>
          "We couldn't sign you in with that email and password.",
        'email-already-in-use' => 'An account already exists for that email. Try signing in instead.',
        'weak-password' => 'Please choose a password of at least 6 characters.',
        'too-many-requests' => 'Too many attempts. Please wait a moment and try again.',
        'popup-closed-by-user' || 'cancelled-popup-request' => 'Sign-in was cancelled.',
        _ => e.message ?? 'Something went wrong (${e.code}).',
      };

  @override
  Future<void> signIn({required String email, required String password}) =>
      _guard(() => _auth.signInWithEmailAndPassword(email: email, password: password));

  @override
  Future<void> signUp({required String email, required String password, required String displayName}) {
    return _guard(() async {
      final credential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      await credential.user?.updateDisplayName(displayName);
      final user = credential.user;
      if (user != null) await _ensureProfile(user);
    });
  }

  // Web uses the popup flow, which needs no extra packages or native
  // config. Mobile builds should switch these to provider-based sign-in
  // once the iOS/Android OAuth clients are registered.
  @override
  Future<void> signInWithGoogle() => _guard(() => _auth.signInWithPopup(fb.GoogleAuthProvider()));

  @override
  Future<void> signInWithApple() => _guard(() => _auth.signInWithPopup(fb.OAuthProvider('apple.com')));

  @override
  Future<void> sendPasswordReset(String email) => _guard(() => _auth.sendPasswordResetEmail(email: email));

  @override
  Future<void> signOut() => _auth.signOut();

  @override
  Future<void> signInAsDemo(UserRole role) async {
    throw const AuthFailure('Demo sign-in is not available on a live backend.');
  }
}

/// In-memory auth for the zero-backend mode.
///
/// Lets a prospective church click all the way through the member portal
/// and staff dashboard - as any role - without creating a Firebase
/// project. Nothing is persisted beyond the browser session.
class LocalAuthRepository implements AuthRepository {
  final _controller = StreamController<AppUser?>.broadcast();

  /// The in-memory congregation, so a demo account can be enrolled in it
  /// on sign-in. Without this the previewing admin is not a member of
  /// their own church: announcements they send reach nobody they can see,
  /// and they never appear in the members list.
  final UserRepository? _users;

  AppUser? _current;

  LocalAuthRepository([this._users]);

  @override
  bool get supportsSocialSignIn => false;

  @override
  bool get isDemo => true;

  @override
  Stream<AppUser?> authStateChanges() async* {
    yield _current;
    yield* _controller.stream;
  }

  void _emit(AppUser? user) {
    _current = user;
    _controller.add(user);
  }

  /// Upsert into the congregation, then sign in. Ordered this way so the
  /// member exists before any screen reacts to the auth change.
  Future<void> _enrolAndEmit(AppUser user) async {
    await _users?.update(user);
    _emit(user);
  }

  AppUser _demoUser(UserRole role, {String? email, String? displayName}) {
    final label = switch (role) {
      UserRole.member => 'Demo Member',
      UserRole.staff => 'Demo Staff',
      UserRole.admin => 'Demo Admin',
    };
    return AppUser(
      uid: 'demo-${role.name}',
      email: email ?? 'demo.${role.name}@example.org',
      displayName: displayName?.trim().isNotEmpty == true ? displayName!.trim() : label,
      role: role,
      createdAt: DateTime.now(),
      household: const [HouseholdMember(name: 'Sam Demo', relationship: 'Child')],
    );
  }

  @override
  Future<void> signIn({required String email, required String password}) =>
      _enrolAndEmit(_demoUser(UserRole.member, email: email));

  @override
  Future<void> signUp({required String email, required String password, required String displayName}) =>
      _enrolAndEmit(_demoUser(UserRole.member, email: email, displayName: displayName));

  @override
  Future<void> signInWithGoogle() async =>
      throw const AuthFailure('Google sign-in needs a configured Firebase project.');

  @override
  Future<void> signInWithApple() async =>
      throw const AuthFailure('Apple sign-in needs a configured Firebase project.');

  @override
  Future<void> sendPasswordReset(String email) async {
    // No mail to send in demo mode; succeed quietly so the UI flow is
    // still walkable.
  }

  @override
  Future<void> signOut() async => _emit(null);

  @override
  Future<void> signInAsDemo(UserRole role) => _enrolAndEmit(_demoUser(role));
}
