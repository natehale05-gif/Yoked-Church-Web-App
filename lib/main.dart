import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'state/auth_controller.dart';
import 'state/site_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final site = SiteController();
  final auth = AuthController();

  // Load persisted config/content and admin session before first frame.
  await Future.wait([site.load(), auth.load()]);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<SiteController>.value(value: site),
        ChangeNotifierProvider<AuthController>.value(value: auth),
      ],
      child: const YokedApp(),
    ),
  );
}
