import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yoked_church_app/app/app.dart';
import 'package:yoked_church_app/app/router.dart';
import 'package:yoked_church_app/core/config/tenant.dart';
import 'package:yoked_church_app/features/auth/application/auth_providers.dart';
import 'package:yoked_church_app/features/churches/application/church_providers.dart';
import 'package:yoked_church_app/features/churches/data/church_directory_repository.dart';
import 'package:yoked_church_app/features/churches/domain/church_slug.dart';
import 'package:yoked_church_app/features/churches/domain/church_summary.dart';
import 'package:yoked_church_app/features/connect/data/connect_repository.dart';
import 'package:yoked_church_app/features/events/data/event_repository.dart';
import 'package:yoked_church_app/features/sermons/data/sermon_repository.dart';

import '../fakes/fake_repositories.dart';

/// Signing up: the thing that decides whether this is a product or a
/// template you fork.
///
/// Before this, creating a church meant an operator writing a Firestore
/// document and then setting a role by hand in the Firebase console.
void main() {
  // Two things at once, both about the same static cache.
  //
  // Reset, because a church created in demo mode is held in a static -
  // right for the product, where everything that looks a church up has
  // to see it, and wrong between tests, where it would turn "Grace
  // Chapel" into `grace-chapel-4` by the fourth one.
  //
  // Then warmed, because filling it means reading a bundled asset, and
  // real I/O never completes inside the fake clock a widget test runs
  // on. Left cold, the first signup hangs on the asset rather than
  // failing on anything to do with signing up. `setUp` runs outside
  // that clock, so here it simply works.
  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    LocalChurchDirectoryRepository.reset();
    await LocalChurchDirectoryRepository.load();
  });

  Future<ProviderContainer> pumpStart(WidgetTester tester, {Size size = const Size(1200, 2000)}) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final container = ProviderContainer(overrides: fakeOverrides(churchId: null));
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const YokedChurchApp()),
    );
    await tester.pumpAndSettle();
    container.read(routerProvider).go('/start');
    await tester.pumpAndSettle();
    return container;
  }

  String pathOf(ProviderContainer c) =>
      c.read(routerProvider).routerDelegate.currentConfiguration.uri.path;

  Future<void> fillIn(WidgetTester tester, {String church = 'Grace Chapel'}) async {
    await tester.enterText(find.widgetWithText(TextFormField, 'Church name'), church);
    await tester.enterText(find.widgetWithText(TextFormField, 'Your name'), 'Pat Reyes');
    await tester.enterText(find.widgetWithText(TextFormField, 'Email'), 'pat@example.org');
    await tester.enterText(find.widgetWithText(TextFormField, 'Password'), 'correct-horse');
    await tester.pumpAndSettle();
  }

  group('the address', () {
    test('is derived from the name the way a person would write it', () {
      expect(slugify('Grace Chapel'), 'grace-chapel');
      expect(slugify("St Mary's"), 'st-marys');
      expect(slugify('St. Mary’s Church, Riverside'), 'st-marys-church-riverside');
      expect(slugify('Hope & Anchor'), 'hope-anchor');
    });

    test('says why it cannot be used, in a sentence', () {
      expect(slugProblem('ab'), contains('at least'));
      expect(slugProblem('admin'), contains('taken'));
      expect(slugProblem('grace-chapel'), isNull);
    });

    test('the second church of the same name still gets one', () {
      expect(availableSlug('grace-chapel', {'grace-chapel'}), 'grace-chapel-2');
    });

    test('agrees with the copy the Cloud Function runs', () {
      // Duplicated deliberately - the client shows a person their address
      // as they type, the server is the one that may be trusted with it -
      // so these cases are the contract. functions/test/church.test.js
      // asserts the same answers.
      expect(slugify('The 99'), 'the-99');
      expect(slugify('  Spaced   Out  '), 'spaced-out');
      expect(reservedSlugs.contains('c'), isTrue, reason: 'c is the route prefix');
    });
  });

  group('the signup form', () {
    testWidgets('shows the address as you type it', (tester) async {
      // It is permanent, so this is the only moment a church can decide
      // they would rather be something else.
      await pumpStart(tester);

      await tester.enterText(find.widgetWithText(TextFormField, 'Church name'), 'Grace Chapel');
      await tester.pumpAndSettle();

      expect(find.textContaining('/c/grace-chapel'), findsOneWidget);
    });

    testWidgets('asks for nothing that is not needed', (tester) async {
      await pumpStart(tester);

      expect(find.widgetWithText(TextFormField, 'Church name'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Your name'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Email'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Password'), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(4), reason: 'four fields, no plan, no card');
    });

    testWidgets('will not submit an empty form', (tester) async {
      await pumpStart(tester);

      await tester.tap(find.widgetWithText(ElevatedButton, 'Create my church'));
      await tester.pumpAndSettle();

      expect(find.text('What is your church called?'), findsOneWidget);
      expect(pathOf(container(tester)), '/start');
    });

    testWidgets('a name too short to be an address is refused with a reason', (tester) async {
      await pumpStart(tester);
      await fillIn(tester, church: 'A');

      await tester.tap(find.widgetWithText(ElevatedButton, 'Create my church'));
      await tester.pumpAndSettle();

      expect(find.textContaining('at least'), findsWidgets);
    });
  });

  group('creating one', () {
    testWidgets('lands you in your own dashboard, as its admin', (tester) async {
      final c = await pumpStart(tester);

      await fillIn(tester);
      await tester.tap(find.widgetWithText(ElevatedButton, 'Create my church'));
      await tester.pumpAndSettle();

      expect(pathOf(c), '/c/grace-chapel/admin', reason: 'straight to the thing they came to use');
      expect(c.read(selectedChurchIdProvider), 'grace-chapel');
      expect(c.read(isAdminProvider), isTrue, reason: 'nobody else exists yet to promote them');
    });

    testWidgets('the new church is in the directory, so members can find it', (tester) async {
      final c = await pumpStart(tester);

      await fillIn(tester);
      await tester.tap(find.widgetWithText(ElevatedButton, 'Create my church'));
      await tester.pumpAndSettle();

      final churches = await c.read(churchDirectoryProvider).fetchAll();
      expect(churches.map((x) => x.id), contains('grace-chapel'));
      expect(
        churches.firstWhere((x) => x.id == 'grace-chapel').name,
        'Grace Chapel',
        reason: 'the picker shows the name they typed, not their slug',
      );
    });

    testWidgets('a second church of the same name gets its own address', (tester) async {
      final c = await pumpStart(tester);
      await c.read(churchDirectoryProvider).create(name: 'Grace Chapel', desiredSlug: 'grace-chapel');

      await fillIn(tester);
      await tester.tap(find.widgetWithText(ElevatedButton, 'Create my church'));
      await tester.pumpAndSettle();

      expect(
        pathOf(c),
        '/c/grace-chapel-2/admin',
        reason: 'turning away the second Grace Chapel is losing a customer over another\'s name',
      );
    });
  });

  group('whose content is whose', () {
    // Asserted against the real local repositories rather than through
    // the app, because the widget harness swaps in fakes that are seeded
    // empty - so a "starts empty" assertion there would pass whatever
    // the rule did, and prove nothing.
    setUp(TestWidgetsFlutterBinding.ensureInitialized);

    test('a church someone just made starts empty', () async {
      // The zero-backend mode used to share one set of collections
      // between every church. That was invisible while the only churches
      // were the bundled ones, and became a lie the moment a person
      // could create their own: signing up and landing on a dashboard
      // reporting two unread messages you have never seen is not a demo
      // of a product, it is a demo of a bug.
      LocalChurchDirectoryRepository.reset();
      final id = await LocalChurchDirectoryRepository()
          .create(name: 'Grace Chapel', desiredSlug: 'grace-chapel');

      expect(await LocalSermonRepository(id).fetchAll(), isEmpty);
      expect(await LocalEventRepository(id).fetchAll(), isEmpty);
      expect(await LocalConnectRepository(id).fetchAll(), isEmpty);
    });

    test('the sample churches keep the sample content', () async {
      // The other half of the same rule. An empty demo would make the
      // picker prove nothing.
      LocalChurchDirectoryRepository.reset();

      expect(await LocalSermonRepository(demoChurchId).fetchAll(), isNotEmpty);
      expect(
        await LocalSermonRepository('riverside-fellowship').fetchAll(),
        isNotEmpty,
        reason: 'all three bundled churches are meant to be walkable',
      );
    });
  });

  group('what the server says when it says no', _messageTests);

  group('when it goes wrong', () {
    testWidgets('the reason is on screen, and the form still holds what was typed', (tester) async {
      final container = ProviderContainer(
        overrides: [
          ...fakeOverrides(churchId: null),
          churchDirectoryProvider.overrideWithValue(const _RefusingDirectory()),
        ],
      );
      addTearDown(container.dispose);

      tester.view.physicalSize = const Size(1200, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        UncontrolledProviderScope(container: container, child: const YokedChurchApp()),
      );
      await tester.pumpAndSettle();
      container.read(routerProvider).go('/start');
      await tester.pumpAndSettle();

      await fillIn(tester, church: 'Hope Chapel');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Create my church'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Something went wrong at our end'), findsOneWidget);
      expect(
        pathOf(container),
        '/start',
        reason: 'a failed signup that navigates anyway strands someone in a church that does not exist',
      );
      expect(
        find.widgetWithText(TextFormField, 'Hope Chapel'),
        findsOneWidget,
        reason: 'making someone retype it all is how you lose them on the second try',
      );
    });
  });
}

/// What a person is told when the server says no.
///
/// The mapping lives in [FirestoreChurchDirectoryRepository], which
/// cannot be constructed without a Firebase app, so these go at the
/// function that decides - reached through the same public surface the
/// screen sees.
void _messageTests() {
  String reasonFor(String code, [String message = '']) {
    try {
      throw FirebaseFunctionsException(code: code, message: message);
    } on FirebaseFunctionsException catch (e) {
      return churchCreationMessageFor(e);
    }
  }

  test('a refusal the function wrote is passed through untouched', () {
    // "That address is taken. Try adding your town." is already a
    // sentence for a person; rewriting it here would only make it worse.
    expect(
      reasonFor('invalid-argument', 'That address is taken. Try adding your town.'),
      'That address is taken. Try adding your town.',
    );
    expect(
      reasonFor('resource-exhausted', 'One account can set up 3 churches.'),
      'One account can set up 3 churches.',
    );
  });

  test('a function that was never deployed says so, and how to fix it', () {
    // The failure mode this exists for. An undeployed callable raises
    // not-found with an empty message, and "please try again" in front
    // of it is advice that can never work.
    final message = reasonFor('not-found');

    expect(message, contains('firebase deploy'));
    expect(message, isNot(contains('try again')));
  });

  test('a raw code is never shown to anyone', () {
    // FirebaseFunctionsException carries NOT_FOUND / INTERNAL as the
    // message for transport failures. Nobody signing up for a church
    // site should read that.
    for (final code in ['not-found', 'internal', 'unavailable', 'permission-denied']) {
      final message = reasonFor(code, code.toUpperCase().replaceAll('-', '_'));
      expect(message, isNot(contains('_')), reason: '$code leaked a raw code');
      expect(message.trim(), isNotEmpty);
    }
  });

  test('a genuinely transient failure is the one place "try again" is honest', () {
    for (final code in ['unavailable', 'deadline-exceeded']) {
      expect(reasonFor(code), contains('try again'));
    }
  });

  test('an unknown code still says something rather than nothing', () {
    expect(reasonFor('something-new-in-the-sdk').trim(), isNotEmpty);
  });
}

/// Reaches the same failure a server refusal produces.
class _RefusingDirectory implements ChurchDirectoryRepository {
  const _RefusingDirectory();

  @override
  Future<List<ChurchSummary>> fetchAll() async => const [];

  @override
  Future<ChurchSummary?> fetchById(String id) async => null;

  @override
  Future<String> create({required String name, required String desiredSlug}) async {
    throw const ChurchCreationFailure('Something went wrong at our end. Please try again.');
  }
}

/// The container behind the currently pumped app.
ProviderContainer container(WidgetTester tester) => ProviderScope.containerOf(
      tester.element(find.byType(YokedChurchApp)),
    );
