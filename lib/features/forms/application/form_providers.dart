import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_providers.dart';
import '../data/form_repository.dart';
import '../domain/church_form.dart';
import '../domain/form_submission.dart';

final formRepositoryProvider = Provider<FormRepository>((ref) {
  throw UnimplementedError('formRepositoryProvider must be overridden in ProviderScope');
});

final submissionRepositoryProvider = Provider<SubmissionRepository>((ref) {
  throw UnimplementedError('submissionRepositoryProvider must be overridden in ProviderScope');
});

final formsProvider = StreamProvider<List<FormDefinition>>((ref) {
  return ref.watch(formRepositoryProvider).watchAll();
});

/// What a given visitor may actually open. Drafts never appear, and a
/// members-only form stays off the public index - the route guard
/// enforces the same rule for anyone who has the URL.
final visibleFormsProvider = Provider<List<FormDefinition>>((ref) {
  final signedIn = ref.watch(isSignedInProvider);
  final all = ref.watch(formsProvider).valueOrNull ?? const <FormDefinition>[];
  return all.where((f) => f.published && (signedIn || !f.membersOnly)).toList();
});

final formBySlugProvider = FutureProvider.family<FormDefinition?, String>((ref, slug) {
  ref.watch(formsProvider);
  return ref.watch(formRepositoryProvider).bySlug(slug);
});

final submissionRefreshProvider = StateProvider<int>((ref) => 0);

final allSubmissionsProvider = FutureProvider<List<FormSubmission>>((ref) {
  ref.watch(submissionRefreshProvider);
  return ref.watch(submissionRepositoryProvider).fetchAll();
});

final submissionsForFormProvider =
    FutureProvider.family<List<FormSubmission>, String>((ref, formId) async {
  ref.watch(submissionRefreshProvider);
  final list = await ref.watch(submissionRepositoryProvider).forForm(formId);
  return list..sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
});

/// Why a submission was refused. A closed form and a half-filled one are
/// different problems, and the member needs to be told which.
sealed class SubmitFailure {
  const SubmitFailure();
}

class FormClosed extends SubmitFailure {
  final DateTime? closedAt;

  const FormClosed(this.closedAt);
}

class FormNotAcceptingSubmissions extends SubmitFailure {
  const FormNotAcceptingSubmissions();
}

class MissingAnswers extends SubmitFailure {
  final List<FormFieldDef> fields;

  const MissingAnswers(this.fields);
}

final formControllerProvider = Provider<FormController>((ref) => FormController(ref));

class FormController {
  final Ref _ref;

  FormController(this._ref);

  /// Returns null on success.
  ///
  /// The deadline is enforced here rather than by hiding the button:
  /// a member can have the page open when the form closes, and the tab
  /// that has been sitting there since Tuesday must not still get in.
  Future<SubmitFailure?> submit({
    required FormDefinition form,
    required Map<String, String> answers,
    String submitterName = '',
    String submitterEmail = '',
  }) async {
    if (form.hasClosed) return FormClosed(form.closesAt);
    if (!form.published) return const FormNotAcceptingSubmissions();

    final missing = form.missingRequired(answers);
    if (missing.isNotEmpty) return MissingAnswers(missing);

    final user = _ref.read(currentUserProvider);
    await _ref.read(submissionRepositoryProvider).create(FormSubmission(
          formId: form.id,
          formTitle: form.title,
          uid: user?.uid ?? '',
          submitterName: submitterName.trim().isEmpty ? (user?.displayName ?? '') : submitterName.trim(),
          submitterEmail: submitterEmail.trim().isEmpty ? (user?.email ?? '') : submitterEmail.trim(),
          answers: form.prune(answers),
          submittedAt: DateTime.now(),
        ));
    _ref.read(submissionRefreshProvider.notifier).state++;
    return null;
  }

  Future<void> save(FormDefinition form) async {
    final repo = _ref.read(formRepositoryProvider);
    if (form.id.isEmpty) {
      await repo.create(form);
    } else {
      await repo.update(form);
    }
    _ref.invalidate(formsProvider);
  }

  Future<void> deleteForm(String id) async {
    await _ref.read(formRepositoryProvider).delete(id);
    _ref.invalidate(formsProvider);
  }

  /// A slug is a public URL, so a collision would silently point two
  /// forms at one address. Suffixes rather than refuses - a church
  /// running "Camp Registration" two years running should not have to
  /// invent a new title.
  Future<String> uniqueSlug(String desired, {String exceptId = ''}) async {
    final base = slugify(desired).isEmpty ? 'form' : slugify(desired);
    final existing = await _ref.read(formRepositoryProvider).fetchAll();
    final taken = {
      for (final f in existing)
        if (f.id != exceptId) f.slug,
    };
    if (!taken.contains(base)) return base;
    var n = 2;
    while (taken.contains('$base-$n')) {
      n++;
    }
    return '$base-$n';
  }
}
