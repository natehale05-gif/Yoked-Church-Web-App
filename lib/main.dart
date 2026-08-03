import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'app/backend.dart';
import 'firebase_options.dart';

/// Set with `--dart-define=USE_FIREBASE_EMULATOR=true` to point at a local
/// Firebase emulator (`firebase emulators:start`) instead of a real
/// project. Never set this in a deployed build.
const bool _useEmulator = bool.fromEnvironment('USE_FIREBASE_EMULATOR');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final backend = await _initBackend();

  runApp(
    ProviderScope(
      overrides: overridesFor(backend),
      child: const YokedChurchApp(),
    ),
  );
}

/// Chooses the data source once, at startup.
///
/// If Firebase isn't configured - or fails to initialize for any reason -
/// the app degrades to bundled content rather than showing a broken site.
/// That matters for a church website: a backend outage should still leave
/// service times and directions on screen.
Future<Backend> _initBackend() async {
  if (!DefaultFirebaseOptions.isConfigured) return Backend.local;

  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    if (_useEmulator) {
      await FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
      FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
    }
    return Backend.firestore;
  } catch (error, stack) {
    debugPrint('Firebase init failed, falling back to bundled content: $error');
    debugPrintStack(stackTrace: stack);
    return Backend.local;
  }
}
