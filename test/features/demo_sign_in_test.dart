import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yoked_church_app/core/config/tenant.dart';
import 'package:yoked_church_app/app/app.dart';
import 'package:yoked_church_app/app/router.dart';
import 'package:yoked_church_app/features/auth/application/auth_providers.dart';
import 'package:yoked_church_app/features/auth/data/auth_repository.dart';
import 'package:yoked_church_app/features/auth/data/user_repository.dart';
import 'package:yoked_church_app/features/auth/domain/app_user.dart';

import '../fakes/fake_repositories.dart';

/// The three "Preview mode" buttons on the sign-in page.
///
/// With no Firebase project configured these are the *only* way into the
/// member portal and the admin dashboard, so if they do nothing the
/// deployed site has no signed-in half at all. `demo_mode_test.dart`
/// covers the repository in isolation against a fake congregation; this
/// covers the thing a person actually touches, wired the way
/// `localOverrides()` wires it - the real [LocalAuthRepository] over the
/// real [LocalUserRepository], which seeds itself from a bundled asset.
void main() {
  late LocalUserRepository users;

  /// The production zero-backend auth wiring, dropped into an otherwise
  /// faked app. Mirrors `localOverrides()` in lib/app/backend.dart: one
  /// congregation, shared between auth and everything that reads members.
  List<Override> withRealDemoAuth() => [
        ...fakeOverrides(),
        authRepositoryProvider.overrideWithValue(LocalAuthRepository(users)),
        userRepositoryProvider.overrideWithValue(users),
      ];

  Future<ProviderContainer> pumpSignIn(
    WidgetTester tester, {
    Size size = const Size(390, 844),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    users = LocalUserRepository();

    final container = ProviderContainer(overrides: withRealDemoAuth());
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const YokedChurchApp()),
    );
    await tester.pumpAndSettle();

    container.read(routerProvider).go('/sign-in');
    await tester.pumpAndSettle();
    return container;
  }

  String pathOf(ProviderContainer c) =>
      subPathOf(c.read(routerProvider).routerDelegate.currentConfiguration.uri.path);

  /// Taps a role button and lets the app react.
  ///
  /// The tap runs inside [WidgetTester.runAsync] because signing in
  /// touches a bundled asset, and real I/O never completes under the fake
  /// clock a widget test normally runs on - which would hang the tap for
  /// reasons that have nothing to do with the app.
  ///
  /// The frames afterwards are pumped a bounded number of times rather
  /// than settled: a sign-in that never finishes leaves a progress
  /// spinner turning, and `pumpAndSettle` would report that as a timeout
  /// that says nothing about the cause.
  Future<void> preview(WidgetTester tester, String label) async {
    final button = find.widgetWithText(OutlinedButton, label);
    await tester.ensureVisible(button);
    await tester.pump();

    await tester.runAsync(() async {
      await tester.tap(button);
      await Future<void>.delayed(const Duration(milliseconds: 200));
    });

    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  group('previewing a role from the sign-in page', () {
    testWidgets('the three role buttons are offered', (tester) async {
      await pumpSignIn(tester);

      expect(find.text('Preview mode'), findsOneWidget);
      for (final label in ['As member', 'As staff', 'As admin']) {
        expect(find.widgetWithText(OutlinedButton, label), findsOneWidget);
      }
    });

    testWidgets('as member lands in the member portal', (tester) async {
      final container = await pumpSignIn(tester);

      await preview(tester, 'As member');

      expect(
        container.read(authControllerProvider).isLoading,
        isFalse,
        reason: 'the sign-in never finished; the button is still spinning',
      );
      expect(container.read(isSignedInProvider), isTrue, reason: 'the tap must sign someone in');
      expect(pathOf(container), '/account');
    });

    testWidgets('as staff lands in the dashboard', (tester) async {
      final container = await pumpSignIn(tester);

      await preview(tester, 'As staff');

      expect(pathOf(container), '/admin');
    });

    testWidgets('as admin lands in the dashboard', (tester) async {
      final container = await pumpSignIn(tester);

      await preview(tester, 'As admin');

      expect(pathOf(container), '/admin');
      expect(container.read(isAdminProvider), isTrue);
    });

    testWidgets('nothing is left showing an error', (tester) async {
      // A failure here surfaces as the inline banner rather than an
      // exception, so a route assertion alone could pass while the
      // person sees "Something went wrong".
      final container = await pumpSignIn(tester);

      await preview(tester, 'As admin');

      expect(container.read(authControllerProvider).hasError, isFalse);
    });

    testWidgets('the previewing admin is enrolled in the congregation', (tester) async {
      await pumpSignIn(tester);

      await preview(tester, 'As admin');

      final enrolled = await tester.runAsync(() => users.fetchById('demo-admin'));
      expect(enrolled, isNotNull, reason: 'an admin who is not a member cannot see their own church');
      expect(enrolled!.role, UserRole.admin);
    });
  });

  group('on a phone', () {
    testWidgets('the way in is reachable without hunting for it', (tester) async {
      // The buttons sit at the bottom of a scrolling column. On a 390x844
      // screen they landed below the fold, which on the only sign-in path
      // this build has means the app looks like it has no way in at all.
      await pumpSignIn(tester);

      final button = find.widgetWithText(OutlinedButton, 'As admin');
      final bottom = tester.getRect(button).bottom;

      expect(
        bottom,
        lessThanOrEqualTo(844.0),
        reason: 'the demo buttons start $bottom px down a 844px screen',
      );
    });
  });
}
