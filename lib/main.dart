import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'config/church_config.dart';
import 'firebase_options.dart';

/// Set with `--dart-define=USE_FIREBASE_EMULATOR=true` to point the app at
/// a local Firebase Auth/Firestore emulator (`firebase emulators:start`)
/// instead of a real project - useful for local development and testing
/// without touching production data. Never set in a deployed build.
const bool _useFirebaseEmulator = bool.fromEnvironment('USE_FIREBASE_EMULATOR');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (ChurchConfig.useFirebase) {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    if (_useFirebaseEmulator) {
      await FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
      FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
    }
  }

  runApp(YokedChurchApp());
}
