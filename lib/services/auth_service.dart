import 'package:firebase_auth/firebase_auth.dart';

/// Thin wrapper around [FirebaseAuth]. Only ever constructed/used when
/// [ChurchConfig.useFirebase] is true - see [AuthProvider].
class AuthService {
  // A getter, not a field initializer, so constructing AuthService never
  // touches Firebase until a method is actually called - AuthProvider
  // always constructs one, even when ChurchConfig.useFirebase is false.
  FirebaseAuth get _auth => FirebaseAuth.instance;

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<UserCredential> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
    await credential.user?.updateDisplayName(displayName);
    return credential;
  }

  Future<UserCredential> signIn({required String email, required String password}) {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<UserCredential> signInWithGoogle() {
    return _auth.signInWithPopup(GoogleAuthProvider());
  }

  Future<UserCredential> signInWithApple() {
    return _auth.signInWithPopup(OAuthProvider('apple.com'));
  }

  Future<void> sendPasswordResetEmail(String email) {
    return _auth.sendPasswordResetEmail(email: email);
  }

  Future<void> signOut() => _auth.signOut();
}
