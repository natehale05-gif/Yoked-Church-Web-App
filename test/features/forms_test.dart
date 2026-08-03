import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yoked_church_app/app/app.dart';
import 'package:yoked_church_app/app/router.dart';
import 'package:yoked_church_app/features/auth/application/auth_providers.dart';
import 'package:yoked_church_app/features/forms/application/form_providers.dart';
import 'package:yoked_church_app/features/forms/data/form_repository.dart';
import 'package:yoked_church_app/features/forms/domain/church_form.dart';
import 'package:yoked_church_app/features/forms/domain/form_submission.dart';
import 'package:yoked_church_app/features/forms/domain/submission_csv.dart';
import 'package:yoked_church_app/features/notifications/application/notification_providers.dart';

import '../fakes/fake_repositories.dart';

/// The conditional rules are the part of a form builder that goes wrong
/// quietly: a branch closes and its answer is still in the record, or a
/// hidden question is still required and nobody can work out why the
/// submit button refuses.
void main() {
  const attending = FormFieldDef(
    id: 'f1',
    label: 'Are you coming?',
    type: FormFieldType.radio,
    required: true,
    options: ['Yes', 'No'],
  );
  const whichWeek = FormFieldDef(
    id: 'f2',
    label: 'Which week?',
    type: FormFieldType.dropdown,
    required: true,
    options: ['Week 1', 'Week 2'],
    showIf: FieldCondition(fieldId: 'f1', equals: 'Yes'),
  );
  const cabin = FormFieldDef(
    id: 'f3',
    label: 'Cabin preference',
    showIf: FieldCondition(fieldId: 'f2', equals: 'Week 1'),
  );

  const camp = FormDefinition(
    id: 'camp',
    title: 'Camp',
    slug: 'camp',
    published: true,
    fields: [attending, whichWeek, cabin],
  );

  group('visibleFields', () {
    test('a branch stays closed until its question is answered', () {
      expect(camp.visibleFields({}).map((f) => f.id), ['f1']);
    });

    test('answering opens exactly the matching branch', () {
      expect(camp.visibleFields({'f1': 'Yes'}).map((f) => f.id), ['f1', 'f2']);
      expect(camp.visibleFields({'f1': 'No'}).map((f) => f.id), ['f1']);
    });

    test('a nested branch opens only when its own condition matches', () {
      expect(
        camp.visibleFields({'f1': 'Yes', 'f2': 'Week 1'}).map((f) => f.id),
        ['f1', 'f2', 'f3'],
      );
      expect(
        camp.visibleFields({'f1': 'Yes', 'f2': 'Week 2'}).map((f) => f.id),
        ['f1', 'f2'],
      );
    });

    test('closing a parent closes everything hanging off it', () {
      // Stale answers to f2/f3 are still in the map - the member changed
      // their mind after filling the branch in.
      final answers = {'f1': 'No', 'f2': 'Week 1', 'f3': 'Lakeside'};
      expect(camp.visibleFields(answers).map((f) => f.id), ['f1']);
    });

    test('a condition pointing at a deleted question leaves the field visible', () {
      const orphaned = FormDefinition(
        id: 'x',
        title: 'X',
        slug: 'x',
        fields: [FormFieldDef(id: 'f9', label: 'Orphan', showIf: FieldCondition(fieldId: 'gone', equals: 'Yes'))],
      );
      expect(orphaned.visibleFields({}), hasLength(1));
    });
  });

  group('required', () {
    test('a hidden question is never required', () {
      // f2 is required, but invisible while f1 says No - otherwise the
      // form could never be submitted.
      expect(camp.missingRequired({'f1': 'No'}), isEmpty);
    });

    test('a visible required question is still required', () {
      expect(camp.missingRequired({'f1': 'Yes'}).map((f) => f.id), ['f2']);
    });

    test('whitespace is not an answer', () {
      expect(camp.missingRequired({'f1': '   '}).map((f) => f.id), ['f1']);
    });
  });

  group('prune', () {
    test('drops the answers to questions the member cannot see', () {
      final answers = {'f1': 'No', 'f2': 'Week 1', 'f3': 'Lakeside'};
      expect(camp.prune(answers), {'f1': 'No'});
    });

    test('keeps a branch that is genuinely open', () {
      final answers = {'f1': 'Yes', 'f2': 'Week 1', 'f3': 'Lakeside'};
      expect(camp.prune(answers), {'f1': 'Yes', 'f2': 'Week 1', 'f3': 'Lakeside'});
    });

    test('drops empty answers rather than storing blank columns', () {
      expect(camp.prune({'f1': 'Yes', 'f2': ''}), {'f1': 'Yes'});
    });
  });

  group('pages', () {
    test('a single-page form still counts as one page', () {
      expect(camp.pageCount, 1);
      expect(const FormDefinition(title: 'Empty', slug: 'e').pageCount, 1);
    });

    test('page count comes from the highest page any field sits on', () {
      const multi = FormDefinition(
        title: 'Multi',
        slug: 'm',
        fields: [
          FormFieldDef(id: 'a', label: 'A'),
          FormFieldDef(id: 'b', label: 'B', page: 2),
        ],
      );
      expect(multi.pageCount, 3);
    });
  });

  group('slugs', () {
    test('are url-safe and readable', () {
      expect(slugify('Summer Camp 2026!'), 'summer-camp-2026');
      expect(slugify('  Men\'s   Breakfast  '), 'men-s-breakfast');
    });

    test('a title with nothing url-safe in it still yields a usable slug', () async {
      final container = ProviderContainer(overrides: fakeOverrides());
      addTearDown(container.dispose);
      expect(await container.read(formControllerProvider).uniqueSlug('!!!'), 'form');
    });

    test('a second form with the same title gets its own address', () async {
      final container = ProviderContainer(
        overrides: fakeOverrides(forms: const [
          FormDefinition(id: 'a', title: 'Camp Registration', slug: 'camp-registration'),
        ]),
      );
      addTearDown(container.dispose);
      final controller = container.read(formControllerProvider);
      expect(await controller.uniqueSlug('Camp Registration'), 'camp-registration-2');
    });

    test('a form editing itself keeps its own slug', () async {
      final container = ProviderContainer(
        overrides: fakeOverrides(forms: const [
          FormDefinition(id: 'a', title: 'Camp Registration', slug: 'camp-registration'),
        ]),
      );
      addTearDown(container.dispose);
      final controller = container.read(formControllerProvider);
      expect(await controller.uniqueSlug('Camp Registration', exceptId: 'a'), 'camp-registration');
    });
  });

  group('submitting', () {
    Future<ProviderContainer> containerWith(List<FormDefinition> forms) async {
      final container = ProviderContainer(
        overrides: fakeOverrides(forms: forms, signedInAs: testMember(displayName: 'Hannah Brooks')),
      );
      addTearDown(container.dispose);
      await container.read(authStateProvider.future);
      return container;
    }

    test('stores only the answers that were actually visible', () async {
      final container = await containerWith([camp]);
      final failure = await container.read(formControllerProvider).submit(
            form: camp,
            answers: {'f1': 'No', 'f2': 'Week 1'},
          );

      expect(failure, isNull);
      final stored = (await container.read(allSubmissionsProvider.future)).single;
      expect(stored.answers, {'f1': 'No'});
      expect(stored.formTitle, 'Camp');
      expect(stored.submitterName, 'Hannah Brooks');
    });

    test('refuses when a visible required question is unanswered', () async {
      final container = await containerWith([camp]);
      final failure = await container.read(formControllerProvider).submit(
            form: camp,
            answers: {'f1': 'Yes'},
          );

      expect(failure, isA<MissingAnswers>());
      expect((failure! as MissingAnswers).fields.single.id, 'f2');
      expect(await container.read(allSubmissionsProvider.future), isEmpty);
    });

    test('a form past its deadline refuses, not merely hides its button', () async {
      final closed = camp.copyWith(closesAt: DateTime.now().subtract(const Duration(days: 1)));
      final container = await containerWith([closed]);

      final failure = await container.read(formControllerProvider).submit(
            form: closed,
            answers: {'f1': 'No'},
          );

      expect(failure, isA<FormClosed>());
      expect(await container.read(allSubmissionsProvider.future), isEmpty);
    });

    test('a deadline later today is still open', () async {
      final open = camp.copyWith(closesAt: DateTime.now().add(const Duration(hours: 2)));
      final container = await containerWith([open]);
      expect(open.hasClosed, isFalse);
      expect(
        await container.read(formControllerProvider).submit(form: open, answers: {'f1': 'No'}),
        isNull,
      );
    });

    test('an unpublished form refuses even when someone has the id', () async {
      final draft = camp.copyWith(published: false);
      final container = await containerWith([draft]);
      expect(
        await container.read(formControllerProvider).submit(form: draft, answers: {'f1': 'No'}),
        isA<FormNotAcceptingSubmissions>(),
      );
    });
  });

  group('who can see which forms', () {
    Future<ProviderContainer> containerFor({bool signedIn = false}) async {
      final container = ProviderContainer(
        overrides: fakeOverrides(
          signedInAs: signedIn ? testMember() : null,
          forms: const [
            FormDefinition(id: 'a', title: 'Public', slug: 'public', published: true),
            FormDefinition(id: 'b', title: 'Members', slug: 'members', published: true, membersOnly: true),
            FormDefinition(id: 'c', title: 'Draft', slug: 'draft'),
          ],
        ),
      );
      addTearDown(container.dispose);
      await container.read(authStateProvider.future);
      await container.read(formsProvider.future);
      return container;
    }

    test('a visitor sees only published public forms', () async {
      final container = await containerFor();
      expect(container.read(visibleFormsProvider).map((f) => f.id), ['a']);
    });

    test('a member also sees the members-only ones, but never a draft', () async {
      final container = await containerFor(signedIn: true);
      // Ordered by title, so assert on the set rather than the sequence.
      expect(container.read(visibleFormsProvider).map((f) => f.id).toSet(), {'a', 'b'});
    });
  });

  group('the public form page', () {
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

    testWidgets('renders the first page and hides the closed branch', (tester) async {
      final container = await pumpApp(tester, fakeOverrides(forms: const [camp]));
      container.read(routerProvider).go('/forms/camp');
      await tester.pumpAndSettle();

      expect(find.text('Are you coming? *'), findsOneWidget);
      expect(find.text('Which week? *'), findsNothing);
    });

    testWidgets('an answer on one page does not bleed into the next', (tester) async {
      // Two text questions in the same slot on consecutive pages. Without
      // a key per field, Flutter reuses the first one's State - and its
      // text controller - for the second, so page 2 opens pre-filled with
      // page 1's answer.
      const twoPages = FormDefinition(
        id: 'p',
        title: 'Two pages',
        slug: 'two-pages',
        published: true,
        fields: [
          FormFieldDef(id: 'a', label: 'Phone'),
          FormFieldDef(id: 'b', label: 'Notes', page: 1),
        ],
      );

      final container = await pumpApp(tester, fakeOverrides(forms: const [twoPages]));
      container.read(routerProvider).go('/forms/two-pages');
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), '(555) 010-2233');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      expect(find.text('Notes'), findsOneWidget);
      expect(find.text('(555) 010-2233'), findsNothing);
    });

    testWidgets('a draft is not browsable by anyone who guesses the URL', (tester) async {
      final container = await pumpApp(
        tester,
        fakeOverrides(forms: [camp.copyWith(published: false)]),
      );
      container.read(routerProvider).go('/forms/camp');
      await tester.pumpAndSettle();

      expect(find.text("That form isn't available."), findsOneWidget);
      expect(find.text('Are you coming? *'), findsNothing);
    });

    testWidgets('a members-only form is closed to a signed-out visitor', (tester) async {
      final container = await pumpApp(
        tester,
        fakeOverrides(forms: [camp.copyWith(membersOnly: true)]),
      );
      container.read(routerProvider).go('/forms/camp');
      await tester.pumpAndSettle();

      expect(find.text("That form isn't available."), findsOneWidget);
    });

    testWidgets('an unknown slug says so rather than rendering nothing', (tester) async {
      final container = await pumpApp(tester, fakeOverrides(forms: const [camp]));
      container.read(routerProvider).go('/forms/no-such-form');
      await tester.pumpAndSettle();

      expect(find.text("We couldn't find that form."), findsOneWidget);
    });

    testWidgets('the index lists open forms and marks closed ones', (tester) async {
      final container = await pumpApp(
        tester,
        fakeOverrides(forms: [
          camp,
          camp.copyWith(
            id: 'past',
            title: 'Last Year',
            slug: 'last-year',
            closesAt: DateTime(2026, 1, 1),
          ),
        ]),
      );
      container.read(routerProvider).go('/forms');
      await tester.pumpAndSettle();

      expect(find.text('Camp'), findsOneWidget);
      expect(find.text('Last Year'), findsOneWidget);
      expect(find.text('Closed'), findsOneWidget);
    });
  });

  testWidgets('a list read and a lookup racing each other both see the data', (tester) async {
    // The bug this pins down: seeding used to flip a flag *before* the
    // asset finished loading, so whichever read arrived second sailed
    // past an empty map. Opening /forms/:slug does exactly this - the
    // page watches the collection and looks one document up at once -
    // and the form reported itself missing.
    final repo = LocalFormRepository();
    final results = await Future.wait<Object?>([repo.fetchAll(), repo.bySlug('summer-camp')]);

    expect(results[0] as List<FormDefinition>, isNotEmpty);
    expect(results[1], isNotNull, reason: 'the lookup must not lose the race to the list read');
  });

  test('a form document round-trips through its map', () {
    final restored = FormDefinition.fromMap('camp', camp.toMap());
    expect(restored.fields, hasLength(3));
    expect(restored.fields[1].showIf!.fieldId, 'f1');
    expect(restored.fields[1].options, ['Week 1', 'Week 2']);
    expect(restored.published, isTrue);
    expect(restored.closesAt, isNull);
  });

  test('a new field id never collides with one already in use', () {
    expect(newFieldId(const ['f1', 'f2']), isNot(anyOf('f1', 'f2')));
    expect(newFieldId(const ['f1', 'f2', 'f3']), isNot(anyOf('f1', 'f2', 'f3')));
  });

  group('CSV export', () {
    FormSubmission row(Map<String, String> answers, {String name = 'Hannah Brooks'}) => FormSubmission(
          id: 'x',
          formId: 'camp',
          formTitle: 'Camp',
          submitterName: name,
          submitterEmail: 'hannah@example.org',
          answers: answers,
          submittedAt: DateTime(2026, 7, 26, 9, 30),
        );

    test('columns follow the form, not whatever keys the data happens to have', () {
      final csv = submissionsToCsv(camp, [row({'f1': 'Yes', 'f2': 'Week 1'})]);
      final header = csv.split('\r\n').first;
      expect(header, 'Submitted,Name,Email,Are you coming?,Which week?,Cabin preference');
    });

    test('quotes a comma so later columns do not shift', () {
      final csv = submissionsToCsv(camp, [row({'f1': 'Yes', 'f3': 'Peanut, tree nut'})]);
      expect(csv, contains('"Peanut, tree nut"'));
      // Three schema columns plus the three fixed ones, on both rows.
      for (final line in csv.split('\r\n')) {
        expect(_columns(line), 6, reason: 'a stray comma must not add a column');
      }
    });

    test('doubles an embedded quote rather than ending the field early', () {
      final csv = submissionsToCsv(camp, [row({'f1': 'Yes', 'f3': 'She said "no nuts"'})]);
      expect(csv, contains('"She said ""no nuts"""'));
    });

    test('a pasted line break stays inside its cell', () {
      final csv = submissionsToCsv(camp, [row({'f1': 'Yes', 'f3': 'line one\nline two'})]);
      expect(csv, contains('"line one\nline two"'));
    });

    test('an answer whose question was deleted is carried, not dropped', () {
      final csv = submissionsToCsv(camp, [row({'f1': 'Yes', 'gone': 'Something typed last year'})]);
      expect(csv.split('\r\n').first, endsWith('Other answers'));
      expect(csv, contains('gone: Something typed last year'));
    });

    test('no orphaned answers means no spare column', () {
      final csv = submissionsToCsv(camp, [row({'f1': 'Yes'})]);
      expect(csv.split('\r\n').first, isNot(contains('Other answers')));
    });

    test('the filename says which form and which day', () {
      expect(csvFileName(camp, DateTime(2026, 7, 4)), 'camp-2026-07-04.csv');
    });
  });

  group('notification routing', () {
    test('a submission notifies exactly the staff the form names', () async {
      final container = ProviderContainer(
        overrides: fakeOverrides(
          forms: [camp.copyWith(notifyUids: ['staff-1', 'staff-2'])],
        ),
      );
      addTearDown(container.dispose);
      await container.read(authStateProvider.future);

      await container.read(formControllerProvider).submit(
            form: camp.copyWith(notifyUids: ['staff-1', 'staff-2']),
            answers: {'f1': 'No'},
          );

      final sent = await container.read(notificationRepositoryProvider).fetchAll();
      expect(sent.map((n) => n.uid).toSet(), {'staff-1', 'staff-2'});
      expect(sent.first.title, 'New response: Camp');
      expect(sent.first.linkPath, '/admin/forms/camp/responses');
    });

    test('a form with nobody to notify sends nothing', () async {
      final container = ProviderContainer(overrides: fakeOverrides(forms: const [camp]));
      addTearDown(container.dispose);
      await container.read(authStateProvider.future);

      await container.read(formControllerProvider).submit(form: camp, answers: {'f1': 'No'});
      expect(await container.read(notificationRepositoryProvider).fetchAll(), isEmpty);
    });

    test('a refused submission notifies nobody', () async {
      final withStaff = camp.copyWith(notifyUids: ['staff-1']);
      final container = ProviderContainer(overrides: fakeOverrides(forms: [withStaff]));
      addTearDown(container.dispose);
      await container.read(authStateProvider.future);

      // Missing the required "which week" behind the open branch.
      await container.read(formControllerProvider).submit(form: withStaff, answers: {'f1': 'Yes'});
      expect(await container.read(notificationRepositoryProvider).fetchAll(), isEmpty);
    });
  });

  group('file answers', () {
    test('two uploads of the same filename do not overwrite each other', () async {
      final storage = FakeFileStorage();
      final container = ProviderContainer(overrides: fakeOverrides(storage: storage));
      addTearDown(container.dispose);

      final controller = container.read(formControllerProvider);
      for (var i = 0; i < 2; i++) {
        await controller.uploadAnswerFile(
          formId: 'camp',
          fileName: 'photo.jpg',
          bytes: Uint8List.fromList([1, 2, 3]),
          contentType: 'image/jpeg',
        );
      }
      expect(storage.stored.keys, hasLength(2));
    });

    test('a crafted filename cannot escape the form prefix', () async {
      final storage = FakeFileStorage();
      final container = ProviderContainer(overrides: fakeOverrides(storage: storage));
      addTearDown(container.dispose);

      await container.read(formControllerProvider).uploadAnswerFile(
            formId: '../../secrets',
            fileName: '../../../etc/passwd',
            bytes: Uint8List.fromList([1]),
            contentType: 'text/plain',
          );

      // Slashes are what a traversal needs, and the sanitiser removes
      // them - so `..` can never become a path segment of its own.
      final path = storage.stored.keys.single;
      final segments = path.split('/');
      expect(segments.first, 'formUploads');
      expect(segments, hasLength(3));
      expect(segments, isNot(contains('..')));
    });

    test('a church with no storage says so rather than offering a broken button', () {
      final container = ProviderContainer(
        overrides: fakeOverrides(storage: FakeFileStorage(uploadsSupported: false)),
      );
      addTearDown(container.dispose);
      expect(container.read(formControllerProvider).canUploadAnswers, isFalse);
    });
  });

}

/// Counts top-level columns, respecting RFC 4180 quoting.
int _columns(String line) {
  var count = 1;
  var inQuotes = false;
  for (var i = 0; i < line.length; i++) {
    final ch = line[i];
    if (ch == '"') {
      inQuotes = !inQuotes;
    } else if (ch == ',' && !inQuotes) {
      count++;
    }
  }
  return count;
}
