import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' show User;

import '../models/app_user.dart';

/// Reads/writes the `users/{uid}` Firestore profile that backs [AppUser].
class UserService {
  CollectionReference<Map<String, dynamic>> get _users => FirebaseFirestore.instance.collection('users');

  /// Creates the profile doc on first sign-in (defaults to the `member`
  /// role) or returns the existing one.
  Future<AppUser> ensureUserDoc(User firebaseUser) async {
    final ref = _users.doc(firebaseUser.uid);
    final snapshot = await ref.get();
    if (snapshot.exists) {
      return AppUser.fromMap(firebaseUser.uid, snapshot.data()!);
    }

    final newUser = AppUser(
      uid: firebaseUser.uid,
      email: firebaseUser.email ?? '',
      displayName: firebaseUser.displayName ?? (firebaseUser.email ?? 'Member'),
      photoUrl: firebaseUser.photoURL ?? '',
      role: UserRole.member,
      household: const [],
      directoryOptIn: false,
      createdAt: DateTime.now(),
    );
    await ref.set(newUser.toMap());
    return newUser;
  }

  Stream<AppUser?> watchUser(String uid) {
    return _users.doc(uid).snapshots().map((snap) => snap.exists ? AppUser.fromMap(uid, snap.data()!) : null);
  }

  Future<void> updateProfile(AppUser user) {
    return _users.doc(user.uid).update(user.toMap());
  }

  Future<List<AppUser>> fetchDirectory() async {
    final snapshot = await _users.where('directoryOptIn', isEqualTo: true).get();
    return snapshot.docs.map((doc) => AppUser.fromMap(doc.id, doc.data())).toList();
  }
}
