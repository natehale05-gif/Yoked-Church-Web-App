import 'package:flutter_test/flutter_test.dart';

import 'package:yoked_church_app/app.dart';

void main() {
  testWidgets('Home page renders church name and nav links', (WidgetTester tester) async {
    await tester.pumpWidget(YokedChurchApp());
    await tester.pumpAndSettle();

    expect(find.text('Yoked Church'), findsWidgets);
    expect(find.text('Sermons'), findsWidgets);
    expect(find.text('Events'), findsWidgets);
    expect(find.text('Connect'), findsWidgets);
  });
}
