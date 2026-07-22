import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:yoked_church_app/providers/auth_provider.dart';
import 'package:yoked_church_app/screens/auth/sign_in_screen.dart';
import 'package:yoked_church_app/screens/auth/sign_up_screen.dart';

Widget _wrap(Widget child) {
  final router = GoRouter(routes: [
    GoRoute(path: '/', builder: (context, state) => child),
  ]);
  return ChangeNotifierProvider<AuthProvider>(
    create: (_) => AuthProvider(),
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  testWidgets('SignInScreen shows validation errors on empty submit', (tester) async {
    await tester.pumpWidget(_wrap(const SignInScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);

    await tester.tap(find.text('Sign In'));
    await tester.pumpAndSettle();

    expect(find.text('Enter your email'), findsOneWidget);
    expect(find.text('Enter your password'), findsOneWidget);
  });

  testWidgets('SignUpScreen shows validation errors on empty submit', (tester) async {
    await tester.pumpWidget(_wrap(const SignUpScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Full name'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);

    await tester.tap(find.text('Create Account'));
    await tester.pumpAndSettle();

    expect(find.text('Enter your name'), findsOneWidget);
    expect(find.text('Enter your email'), findsOneWidget);
    expect(find.text('At least 6 characters'), findsOneWidget);
  });
}
