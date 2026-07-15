import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data/local_store.dart';
import 'router/app_router.dart';
import 'state/attendance_controller.dart';
import 'state/auth_controller.dart';
import 'state/members_controller.dart';
import 'state/serving_controller.dart';
import 'state/site_content_controller.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = await LocalStore.create();
  runApp(YokedChurchApp(store: store));
}

class YokedChurchApp extends StatefulWidget {
  final LocalStore store;
  const YokedChurchApp({super.key, required this.store});

  @override
  State<YokedChurchApp> createState() => _YokedChurchAppState();
}

class _YokedChurchAppState extends State<YokedChurchApp> {
  late final AuthController _auth = AuthController(widget.store);
  late final SiteContentController _content =
      SiteContentController(widget.store);
  late final MembersController _members = MembersController(widget.store);
  late final AttendanceController _attendance =
      AttendanceController(widget.store);
  late final ServingController _serving = ServingController(widget.store);
  late final _router = buildRouter(_auth);

  @override
  void dispose() {
    _auth.dispose();
    _content.dispose();
    _members.dispose();
    _attendance.dispose();
    _serving.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _auth),
        ChangeNotifierProvider.value(value: _content),
        ChangeNotifierProvider.value(value: _members),
        ChangeNotifierProvider.value(value: _attendance),
        ChangeNotifierProvider.value(value: _serving),
      ],
      child: MaterialApp.router(
        title: 'Church Website Builder',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        routerConfig: _router,
        builder: (context, child) {
          final media = MediaQuery.of(context);
          final clamped = media.textScaler.clamp(
            minScaleFactor: 1.0,
            maxScaleFactor: 1.25,
          );
          return MediaQuery(
            data: media.copyWith(textScaler: clamped),
            child: child!,
          );
        },
      ),
    );
  }
}
