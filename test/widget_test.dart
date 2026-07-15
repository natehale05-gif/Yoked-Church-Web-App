// Smoke test for the church website.

import 'package:flutter_test/flutter_test.dart';

import 'package:yoked_church/config/site_config.dart';
import 'package:yoked_church/main.dart';

void main() {
  testWidgets('App builds and shows the church name', (tester) async {
    await tester.pumpWidget(const YokedChurchApp());
    await tester.pump();

    // The church name appears in the top navigation wordmark.
    expect(find.text(SiteConfig.churchName), findsWidgets);
  });
}
