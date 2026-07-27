// Placeholder Firebase configuration.
//
// The app does NOT require Firebase: with the values below left as
// `REPLACE_ME`, [DefaultFirebaseOptions.isConfigured] is false and the app
// runs entirely on bundled sample content (see lib/app/backend.dart).
//
// To connect a real Firebase project:
//   1. Create a project at https://console.firebase.google.com
//   2. Enable Firestore and Authentication (Email/Password, Google, Apple)
//   3. dart pub global activate flutterfire_cli
//   4. flutterfire configure      <-- overwrites this file with real values
//   5. firebase deploy --only firestore:rules,firestore:indexes
//
// No code change is needed to "turn Firebase on" - the app detects a real
// configuration at startup.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  const DefaultFirebaseOptions._();

  static const String _unset = 'REPLACE_ME';

  /// True once `flutterfire configure` has filled in real values.
  static bool get isConfigured => currentPlatform.projectId != _unset && currentPlatform.projectId.isNotEmpty;

  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return ios;
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
        return web;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: _unset,
    appId: _unset,
    messagingSenderId: _unset,
    projectId: _unset,
    authDomain: '$_unset.firebaseapp.com',
    storageBucket: '$_unset.appspot.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: _unset,
    appId: _unset,
    messagingSenderId: _unset,
    projectId: _unset,
    storageBucket: '$_unset.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: _unset,
    appId: _unset,
    messagingSenderId: _unset,
    projectId: _unset,
    storageBucket: '$_unset.appspot.com',
    iosBundleId: 'com.yokedchurch.yokedChurchApp',
  );
}
