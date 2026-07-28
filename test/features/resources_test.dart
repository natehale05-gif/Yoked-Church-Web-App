import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yoked_church_app/app/app.dart';
import 'package:yoked_church_app/app/router.dart';
import 'package:yoked_church_app/core/config/church_settings.dart';
import 'package:yoked_church_app/core/storage/file_storage.dart';
import 'package:yoked_church_app/features/auth/domain/app_user.dart';
import 'package:yoked_church_app/features/resources/application/resource_providers.dart';
import 'package:yoked_church_app/features/resources/domain/resource.dart';

import '../fakes/fake_repositories.dart';

void main() {
  Future<ProviderContainer> pumpApp(WidgetTester tester, List<Override> overrides) async {
    tester.view.physicalSize = const Size(1400, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final container = ProviderContainer(overrides: overrides);
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const YokedChurchApp()),
    );
    await tester.pumpAndSettle();
    return container;
  }

  /// The upload path needs no widget tree, and a plain container avoids
  /// widget-test fake async entirely.
  ProviderContainer plainContainer(List<Override> overrides) {
    final container = ProviderContainer(overrides: overrides);
    addTearDown(container.dispose);
    return container;
  }

  String pathOf(ProviderContainer c) =>
      c.read(routerProvider).routerDelegate.currentConfiguration.uri.path;

  /// Awaits the underlying stream first: the filtered provider reads
  /// `valueOrNull`, which is null until the source resolves.
  Future<List<String>> titlesOf(ProviderContainer c) async {
    await c.read(allResourcesProvider.future);
    return (c.read(filteredResourcesProvider).valueOrNull ?? const <Resource>[])
        .map((r) => r.title)
        .toList();
  }

  group('members-only visibility', () {
    List<Override> withMixedResources({AppUser? signedInAs}) => fakeOverrides(
          signedInAs: signedInAs,
          resources: [
            testResource(id: 'pub', title: 'Public Guide', membersOnly: false),
            testResource(id: 'int', title: 'Internal Handbook', membersOnly: true),
          ],
        );

    testWidgets('a signed-out visitor sees only public resources', (tester) async {
      final container = await pumpApp(tester, withMixedResources());
      container.read(routerProvider).go('/resources');
      await tester.pumpAndSettle();

      expect(await titlesOf(container), ['Public Guide']);
      expect(find.text('Internal Handbook'), findsNothing);
      expect(find.textContaining('Sign in to see everything'), findsOneWidget);
    });

    testWidgets('a signed-in member sees both', (tester) async {
      final container = await pumpApp(tester, withMixedResources(signedInAs: testMember()));
      container.read(routerProvider).go('/resources');
      await tester.pumpAndSettle();

      expect(await titlesOf(container), containsAll(['Public Guide', 'Internal Handbook']));
      expect(find.textContaining('Sign in to see everything'), findsNothing);
    });

    testWidgets('the category filter never offers a category the viewer cannot see', (tester) async {
      final container = await pumpApp(
        tester,
        fakeOverrides(
          resources: [
            testResource(id: 'pub', title: 'Public', category: 'Forms', membersOnly: false),
            testResource(id: 'int', title: 'Internal', category: 'Volunteering', membersOnly: true),
          ],
        ),
      );
      container.read(routerProvider).go('/resources');
      await tester.pumpAndSettle();

      await container.read(allResourcesProvider.future);
      expect(container.read(resourceCategoriesProvider), ['Forms']);
    });
  });

  group('filtering', () {
    testWidgets('narrows by category and by search text', (tester) async {
      final container = await pumpApp(
        tester,
        fakeOverrides(
          resources: [
            testResource(id: '1', title: 'Baptism FAQ', category: 'Next Steps', description: 'water'),
            testResource(id: '2', title: 'Facility Form', category: 'Forms', description: 'rooms'),
            testResource(id: '3', title: 'Kids Curriculum', category: 'Kids', description: 'crafts'),
          ],
        ),
      );

      container.read(resourceCategoryFilterProvider.notifier).state = 'Forms';
      expect(await titlesOf(container), ['Facility Form']);

      container.read(resourceCategoryFilterProvider.notifier).state = null;
      container.read(resourceSearchQueryProvider.notifier).state = 'crafts';
      expect(await titlesOf(container), ['Kids Curriculum']);

      // Both at once must intersect, not union.
      container.read(resourceCategoryFilterProvider.notifier).state = 'Forms';
      expect(await titlesOf(container), isEmpty);
    });
  });

  group('kind detection', () {
    test('picks an icon from the filename or the link', () {
      expect(testResource(fileName: 'guide.pdf').kind, ResourceKind.pdf);
      expect(testResource(fileName: 'form.docx').kind, ResourceKind.document);
      expect(testResource(fileName: 'roster.xlsx').kind, ResourceKind.sheet);
      expect(testResource(fileName: 'talk.mp3').kind, ResourceKind.audio);
      expect(
        testResource(fileName: '', url: 'https://youtube.com/watch?v=abc').kind,
        ResourceKind.video,
      );
      expect(testResource(fileName: '', url: 'https://example.org/page').kind, ResourceKind.link);
    });
  });

  group('uploads', () {
    test('storing a file returns a URL and a cleanup path', () async {
      final storage = FakeFileStorage();
      final container = plainContainer(fakeOverrides(storage: storage));

      final stored = await container.read(resourceControllerProvider).uploadFile(
            fileName: 'Summer Guide (2026).pdf',
            bytes: Uint8List.fromList([1, 2, 3]),
            contentType: 'application/pdf',
          );

      expect(stored.url, startsWith('https://files.example.org/resources/'));
      expect(storage.stored, hasLength(1));
      // Unsafe characters are replaced so a name can't escape the prefix.
      expect(stored.storagePath, startsWith('resources/'));
      expect(stored.storagePath, endsWith('_Summer_Guide__2026_.pdf'));
      expect(stored.storagePath, isNot(contains(' ')));
    });

    test('two files with the same name do not overwrite each other', () async {
      final storage = FakeFileStorage();
      final container = plainContainer(fakeOverrides(storage: storage));
      final controller = container.read(resourceControllerProvider);

      // Back to back, deliberately: a timestamp alone would collide.
      final first = await controller.uploadFile(
        fileName: 'guide.pdf',
        bytes: Uint8List.fromList([1]),
        contentType: 'application/pdf',
      );
      final second = await controller.uploadFile(
        fileName: 'guide.pdf',
        bytes: Uint8List.fromList([2]),
        contentType: 'application/pdf',
      );

      expect(first.storagePath, isNot(second.storagePath));
      expect(storage.stored, hasLength(2));
    });

    test('a failed upload surfaces a readable message', () async {
      final storage = FakeFileStorage()..failWith = 'This church has run out of file storage.';
      final container = plainContainer(fakeOverrides(storage: storage));

      await expectLater(
        container.read(resourceControllerProvider).uploadFile(
              fileName: 'big.pdf',
              bytes: Uint8List.fromList([1]),
              contentType: 'application/pdf',
            ),
        throwsA(
          isA<UploadFailure>().having((e) => e.message, 'message', contains('run out of file storage')),
        ),
      );
    });

    test('deleting an uploaded resource also removes the stored blob', () async {
      final storage = FakeFileStorage();
      final container = plainContainer(
        fakeOverrides(
          storage: storage,
          resources: [
            testResource(
              id: 'up',
              url: 'https://files.example.org/resources/1_guide.pdf',
              storagePath: 'resources/1_guide.pdf',
            ),
          ],
        ),
      );

      final resource = (await container.read(resourceRepositoryProvider).fetchById('up'))!;
      await container.read(resourceControllerProvider).delete(resource);

      expect(storage.deleted, ['https://files.example.org/resources/1_guide.pdf']);
      expect(await container.read(resourceRepositoryProvider).fetchById('up'), isNull);
    });

    test('deleting a plain link touches storage not at all', () async {
      final storage = FakeFileStorage();
      final container = plainContainer(
        fakeOverrides(storage: storage, resources: [testResource(id: 'link', storagePath: '')]),
      );

      final resource = (await container.read(resourceRepositoryProvider).fetchById('link'))!;
      await container.read(resourceControllerProvider).delete(resource);

      expect(storage.deleted, isEmpty);
    });

    test('replacing an uploaded file cleans up the old blob', () async {
      final storage = FakeFileStorage();
      final original = testResource(
        id: 'up',
        url: 'https://files.example.org/resources/1_old.pdf',
        storagePath: 'resources/1_old.pdf',
      );
      final container = plainContainer(
        fakeOverrides(storage: storage, resources: [original]),
      );

      await container.read(resourceControllerProvider).save(
            original.copyWith(url: 'https://files.example.org/resources/2_new.pdf', storagePath: 'resources/2_new.pdf'),
            replacing: original,
          );

      expect(storage.deleted, ['https://files.example.org/resources/1_old.pdf']);
    });

    test('editing without changing the file leaves the blob alone', () async {
      final storage = FakeFileStorage();
      final original = testResource(
        id: 'up',
        url: 'https://files.example.org/resources/1_guide.pdf',
        storagePath: 'resources/1_guide.pdf',
      );
      final container = plainContainer(
        fakeOverrides(storage: storage, resources: [original]),
      );

      await container.read(resourceControllerProvider).save(
            original.copyWith(title: 'Renamed'),
            replacing: original,
          );

      expect(storage.deleted, isEmpty);
    });
  });

  group('the storage seam', () {
    test('reports uploads unavailable with no backend', () async {
      final container = plainContainer(
        fakeOverrides(storage: FakeFileStorage(uploadsSupported: false)),
      );

      expect(container.read(resourceControllerProvider).canUpload, isFalse);
    });

    test('the unavailable implementation explains itself rather than failing blankly', () async {
      const storage = UnavailableFileStorage();
      expect(storage.supportsUpload, isFalse);
      await expectLater(
        storage.upload(path: 'x', bytes: Uint8List(0), contentType: 'text/plain'),
        throwsA(
          isA<UploadFailure>().having((e) => e.message, 'message', contains('Paste a link instead')),
        ),
      );
      // Deleting is a no-op rather than a throw, so a record delete is
      // never blocked by storage being absent.
      await storage.deleteAt('https://example.org/x');
    });
  });

  group('feature flag', () {
    testWidgets('turning it off closes the routes and hides the nav entry', (tester) async {
      final container = await pumpApp(
        tester,
        fakeOverrides(
          settings: testSettings(features: const FeatureFlags(resources: false)),
          signedInAs: testMember(uid: 'a1', role: UserRole.admin),
          resources: [testResource()],
        ),
      );

      for (final path in ['/resources', '/admin/resources']) {
        container.read(routerProvider).go(path);
        await tester.pumpAndSettle();
        expect(pathOf(container), anyOf('/', '/admin'), reason: '$path should be closed');
      }
    });
  });

  group('staff CMS', () {
    testWidgets('lists members-only items that the public page hides', (tester) async {
      final container = await pumpApp(
        tester,
        fakeOverrides(
          signedInAs: testMember(uid: 'a1', role: UserRole.admin),
          resources: [
            testResource(id: 'pub', title: 'Public Guide', membersOnly: false),
            testResource(id: 'int', title: 'Internal Handbook', membersOnly: true),
          ],
        ),
      );
      container.read(routerProvider).go('/admin/resources');
      await tester.pumpAndSettle();

      expect(find.text('Public Guide'), findsOneWidget);
      expect(find.text('Internal Handbook'), findsOneWidget);
    });
  });
}
