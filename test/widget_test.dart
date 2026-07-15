// Smoke test for the church platform.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:yoked_church/data/local_store.dart';
import 'package:yoked_church/main.dart';

void main() {
  testWidgets('App builds and shows the church name', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final store = await LocalStore.create();

    await tester.pumpWidget(YokedChurchApp(store: store));
    await tester.pump();

    // The default church name appears in the public site navigation.
    expect(find.text('Grace City Church'), findsWidgets);
  });
}
