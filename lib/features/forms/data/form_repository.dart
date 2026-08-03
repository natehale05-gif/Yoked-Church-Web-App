import '../../../core/firestore/crud_repository.dart';
import '../domain/church_form.dart';
import '../domain/form_submission.dart';

abstract interface class FormRepository implements CrudRepository<FormDefinition> {
  Future<FormDefinition?> bySlug(String slug);
}

abstract interface class SubmissionRepository implements CrudRepository<FormSubmission> {
  Future<List<FormSubmission>> forForm(String formId);
}

mixin _FormCodec implements EntityCodec<FormDefinition> {
  @override
  FormDefinition fromMap(String id, Map<String, dynamic> map) => FormDefinition.fromMap(id, map);
  @override
  Map<String, dynamic> toMap(FormDefinition entity) => entity.toMap();
  @override
  String idOf(FormDefinition entity) => entity.id;
}

mixin _SubmissionCodec implements EntityCodec<FormSubmission> {
  @override
  FormSubmission fromMap(String id, Map<String, dynamic> map) => FormSubmission.fromMap(id, map);
  @override
  Map<String, dynamic> toMap(FormSubmission entity) => entity.toMap();
  @override
  String idOf(FormSubmission entity) => entity.id;
}

class FirestoreFormRepository extends FirestoreCrudRepository<FormDefinition>
    with _FormCodec
    implements FormRepository {
  @override
  String get collectionPath => 'formDefinitions';
  @override
  String? get orderByField => 'title';

  @override
  Future<FormDefinition?> bySlug(String slug) async {
    final matches = await fetchWhere('slug', slug);
    return matches.isEmpty ? null : matches.first;
  }
}

class LocalFormRepository extends LocalCrudRepository<FormDefinition>
    with _FormCodec
    implements FormRepository {
  @override
  String? get seedAsset => 'assets/data/forms.json';
  @override
  int Function(FormDefinition, FormDefinition)? get sorter => (a, b) => a.title.compareTo(b.title);

  @override
  Future<FormDefinition?> bySlug(String slug) async {
    final matches = await fetchWhere((f) => f.slug == slug);
    return matches.isEmpty ? null : matches.first;
  }
}

class FirestoreSubmissionRepository extends FirestoreCrudRepository<FormSubmission>
    with _SubmissionCodec
    implements SubmissionRepository {
  @override
  String get collectionPath => 'formSubmissions';
  @override
  String? get orderByField => 'submittedAt';
  @override
  bool get descending => true;

  @override
  Future<List<FormSubmission>> forForm(String formId) => fetchWhere('formId', formId);
}

class LocalSubmissionRepository extends LocalCrudRepository<FormSubmission>
    with _SubmissionCodec
    implements SubmissionRepository {
  @override
  String? get seedAsset => 'assets/data/form_submissions.json';

  @override
  int Function(FormSubmission, FormSubmission)? get sorter =>
      (a, b) => b.submittedAt.compareTo(a.submittedAt);

  @override
  Future<List<FormSubmission>> forForm(String formId) => fetchWhere((s) => s.formId == formId);
}
