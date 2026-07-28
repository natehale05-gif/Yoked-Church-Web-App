import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yoked_church_app/app/app.dart';
import 'package:yoked_church_app/app/router.dart';
import 'package:yoked_church_app/features/auth/domain/app_user.dart';
import 'package:yoked_church_app/features/sermon_notes/application/sermon_note_providers.dart';
import 'package:yoked_church_app/features/sermons/application/sermon_providers.dart';
import 'package:yoked_church_app/features/sermon_notes/domain/sermon_note.dart';

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

  Future<List<SermonNote>> notesOf(ProviderContainer c) => c.read(myNotesProvider.future);

  SermonNote noteFor({
    String uid = 'u1',
    String sermonId = 's1',
    String body = 'Something worth remembering.',
    String title = 'Test Sermon',
  }) =>
      SermonNote(
        id: sermonNoteId(sermonId, uid),
        uid: uid,
        sermonId: sermonId,
        sermonTitle: title,
        sermonDate: DateTime(2026, 7, 19),
        body: body,
        updatedAt: DateTime(2026, 7, 20),
      );

  group('writing notes', () {
    testWidgets('saving stores one note per sermon per member', (tester) async {
      final container = await pumpApp(
        tester,
        fakeOverrides(signedInAs: testMember(uid: 'u1'), sermons: [testSermon()]),
      );
      final controller = container.read(sermonNoteControllerProvider);

      await controller.save(sermon: testSermon(), body: 'First pass');
      await controller.save(sermon: testSermon(), body: 'Revised');
      await tester.pumpAndSettle();

      final notes = await notesOf(container);
      expect(notes, hasLength(1), reason: 'the deterministic id upserts rather than duplicating');
      expect(notes.single.body, 'Revised');
      expect(notes.single.sermonId, 's1');
    });

    testWidgets('the sermon title and date are stored with the note', (tester) async {
      final container = await pumpApp(
        tester,
        fakeOverrides(signedInAs: testMember(uid: 'u1'), sermons: [testSermon(title: 'Rest for the Weary')]),
      );

      await container.read(sermonNoteControllerProvider).save(
            sermon: testSermon(title: 'Rest for the Weary'),
            body: 'Notes',
          );
      await tester.pumpAndSettle();

      // Denormalised, so the notes list renders without loading sermons
      // and still reads correctly if the sermon is later deleted.
      final note = (await notesOf(container)).single;
      expect(note.sermonTitle, 'Rest for the Weary');
      expect(note.sermonDate, DateTime(2026, 7, 19));
    });

    testWidgets('clearing the text deletes the note rather than storing a blank one', (tester) async {
      final container = await pumpApp(
        tester,
        fakeOverrides(signedInAs: testMember(uid: 'u1'), sermons: [testSermon()]),
      );
      final controller = container.read(sermonNoteControllerProvider);

      await controller.save(sermon: testSermon(), body: 'Something');
      await tester.pumpAndSettle();
      expect(await notesOf(container), hasLength(1));

      await controller.save(sermon: testSermon(), body: '   ');
      await tester.pumpAndSettle();

      expect(await notesOf(container), isEmpty);
      final raw = await container.read(sermonNoteRepositoryProvider).forMember('u1');
      expect(raw, isEmpty, reason: 'the record is removed, not left blank');
    });

    testWidgets('a signed-out visitor cannot write a note', (tester) async {
      final container = await pumpApp(tester, fakeOverrides(sermons: [testSermon()]));

      await container.read(sermonNoteControllerProvider).save(sermon: testSermon(), body: 'Nope');
      await tester.pumpAndSettle();

      expect(await notesOf(container), isEmpty);
    });

    testWidgets('deleting removes only that sermon note', (tester) async {
      final container = await pumpApp(
        tester,
        fakeOverrides(
          signedInAs: testMember(uid: 'u1'),
          sermonNotes: [
            noteFor(sermonId: 's1', body: 'On s1'),
            noteFor(sermonId: 's2', body: 'On s2'),
          ],
        ),
      );

      await container.read(sermonNoteControllerProvider).delete('s1');
      await tester.pumpAndSettle();

      final notes = await notesOf(container);
      expect(notes.map((n) => n.sermonId), ['s2']);
    });
  });

  group('privacy', () {
    testWidgets("a member never sees another member's notes", (tester) async {
      final container = await pumpApp(
        tester,
        fakeOverrides(
          signedInAs: testMember(uid: 'u1'),
          sermonNotes: [
            noteFor(uid: 'u1', sermonId: 's1', body: 'Mine'),
            noteFor(uid: 'u2', sermonId: 's1', body: 'Someone else'),
            noteFor(uid: 'u2', sermonId: 's2', body: 'Also theirs'),
          ],
        ),
      );

      final notes = await notesOf(container);
      expect(notes.map((n) => n.body), ['Mine']);
    });

    testWidgets('staff have no special access to member notes', (tester) async {
      final container = await pumpApp(
        tester,
        fakeOverrides(
          signedInAs: testMember(uid: 'pastor', role: UserRole.admin),
          sermonNotes: [noteFor(uid: 'u1', body: 'Private')],
        ),
      );

      // Deliberate: an admin's own notes list is their own, and there is
      // no screen anywhere that reads another member's.
      expect(await notesOf(container), isEmpty);
    });

    testWidgets('two members can hold notes on the same sermon without collision', (tester) async {
      final container = await pumpApp(
        tester,
        fakeOverrides(
          signedInAs: testMember(uid: 'u1'),
          sermons: [testSermon()],
          sermonNotes: [noteFor(uid: 'u2', sermonId: 's1', body: 'Theirs')],
        ),
      );

      await container.read(sermonNoteControllerProvider).save(sermon: testSermon(), body: 'Mine');
      await tester.pumpAndSettle();

      expect((await notesOf(container)).single.body, 'Mine');
      final all = await container.read(sermonNoteRepositoryProvider).fetchAll();
      expect(all, hasLength(2), reason: "u2's note is untouched");
    });
  });

  group('the sermon page', () {
    testWidgets('offers a private notes panel to a signed-in member', (tester) async {
      final container = await pumpApp(
        tester,
        fakeOverrides(signedInAs: testMember(uid: 'u1'), sermons: [testSermon()]),
      );
      container.read(routerProvider).go('/sermons/s1');
      await tester.pumpAndSettle();

      expect(find.text('My Notes'), findsWidgets);
      expect(find.text('What stood out to you?'), findsOneWidget);
    });

    testWidgets('asks a signed-out visitor to sign in instead', (tester) async {
      final container = await pumpApp(tester, fakeOverrides(sermons: [testSermon()]));
      container.read(routerProvider).go('/sermons/s1');
      await tester.pumpAndSettle();

      expect(find.text('My Notes'), findsWidgets);
      expect(find.text('What stood out to you?'), findsNothing);
      expect(find.textContaining('Sign in to keep your own notes'), findsOneWidget);
    });

    testWidgets("the church's published outline is separate from the member's notes", (tester) async {
      final container = await pumpApp(
        tester,
        fakeOverrides(signedInAs: testMember(uid: 'u1'), sermons: [testSermon()]),
      );

      // Sermon.notes is the church's outline, shown to everyone; the
      // member's own notes are a different collection entirely.
      await container.read(sermonRepositoryProvider).update(
            testSermon().copyWith(notes: 'Point one. Point two.'),
          );
      container.read(routerProvider).go('/sermons/s1');
      await tester.pumpAndSettle();

      expect(find.text('Sermon Notes'), findsOneWidget);
      expect(find.text('Point one. Point two.'), findsOneWidget);
      expect(find.text('My Notes'), findsWidgets);
    });
  });

  group('my notes list', () {
    testWidgets('shows the notes and links back to the sermon', (tester) async {
      final container = await pumpApp(
        tester,
        fakeOverrides(
          signedInAs: testMember(uid: 'u1'),
          sermonNotes: [noteFor(body: 'The yoke is shared.', title: 'Rest for the Weary')],
        ),
      );
      container.read(routerProvider).go('/account/notes');
      await tester.pumpAndSettle();

      expect(find.text('Rest for the Weary'), findsOneWidget);
      expect(find.text('The yoke is shared.'), findsOneWidget);
    });

    testWidgets('an empty note never appears in the list', (tester) async {
      final container = await pumpApp(
        tester,
        fakeOverrides(signedInAs: testMember(uid: 'u1'), sermonNotes: [noteFor(body: '   ')]),
      );

      expect(await notesOf(container), isEmpty);
    });
  });

  group('excerpts', () {
    test('cut on a word boundary and mark the elision', () {
      final note = noteFor(body: 'alpha ' * 60);
      expect(note.excerpt.length, lessThanOrEqualTo(141));
      expect(note.excerpt, endsWith('…'));
    });

    test('a short note is shown whole, with no ellipsis', () {
      final note = noteFor(body: 'Short and complete.');
      expect(note.excerpt, 'Short and complete.');
    });
  });
}
