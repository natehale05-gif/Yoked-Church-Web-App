import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yoked_church/app.dart';
import 'package:yoked_church/state/auth_controller.dart';
import 'package:yoked_church/state/site_controller.dart';

void main() {
  testWidgets('App boots and shows the church name in the shell',
      (tester) async {
    SharedPreferences.setMockInitialValues({});

    final site = SiteController();
    final auth = AuthController();
    await site.load();
    await auth.load();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<SiteController>.value(value: site),
          ChangeNotifierProvider<AuthController>.value(value: auth),
        ],
        child: const YokedApp(),
      ),
    );
    await tester.pump();

    // The default demo church name should render somewhere in the shell.
    expect(find.text('Circle Church'), findsWidgets);
  });
}
