import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'app/backend.dart';
import 'core/config/tenant.dart';
import 'features/churches/application/church_providers.dart';
import 'firebase_options.dart';

/// Set with `--dart-define=USE_FIREBASE_EMULATOR=true` to point at a local
/// Firebase emulator (`firebase emulators:start`) instead of a real
/// project. Never set this in a deployed build.
const bool _useEmulator = bool.fromEnvironment('USE_FIREBASE_EMULATOR');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final backend = await _initBackend();

  // Which church, decided before the first frame.
  //
  // The URL wins: someone opening a link to /c/riverside/sermons is
  // asking for Riverside, whoever they last visited. Resolving it here
  // rather than after the app is up is the difference between a deep
  // link working and a deep link showing the previous church's content
  // and colours while it corrects itself.
  //
  // Falls back to what they chose last time, so a returning member never
  // sees the picker flash past on the way to their own church.
  final savedChurchId = _churchFromUrl() ?? await ChurchPreference.read();

  runApp(
    ProviderScope(
      overrides: [
        ...overridesFor(backend),
        if (savedChurchId != null)
          selectedChurchIdProvider.overrideWith((ref) => savedChurchId),
      ],
      child: const YokedChurchApp(),
    ),
  );
}

/// The church named in the address the app was opened at, if any.
///
/// Reads [Uri.base], which on the web is the page URL. The app routes on
/// the fragment, so the path lives there; the non-fragment path is
/// checked too for a build served without the hash strategy. Off the web
/// [Uri.base] is the working directory, which matches neither, so this
/// is null and the saved preference decides - correctly, since a desktop
/// or phone build has no address bar to have been deep-linked from.
String? _churchFromUrl() {
  final fragment = Uri.base.fragment;
  return churchIdFromLocation(fragment.isEmpty ? Uri.base.path : fragment);
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
