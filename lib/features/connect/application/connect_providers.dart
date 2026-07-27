import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/connect_repository.dart';
import '../domain/connect_submission.dart';

final connectRepositoryProvider = Provider<ConnectRepository>((ref) {
  throw UnimplementedError('connectRepositoryProvider must be overridden in ProviderScope');
});

/// Staff inbox of everything submitted from the Connect page.
final submissionsProvider = StreamProvider<List<ConnectSubmission>>((ref) {
  return ref.watch(connectRepositoryProvider).watchAll();
});

final openSubmissionsCountProvider = Provider<int>((ref) {
  return ref.watch(submissionsProvider).valueOrNull?.where((s) => s.status == SubmissionStatus.open).length ?? 0;
});

/// Handles the submit action and exposes its progress to the form.
class ConnectFormController extends StateNotifier<AsyncValue<bool>> {
  final Ref _ref;

  ConnectFormController(this._ref) : super(const AsyncValue.data(false));

  Future<void> submit(ConnectSubmission submission) async {
    state = const AsyncValue.loading();
    try {
      await _ref.read(connectRepositoryProvider).create(submission);
      state = const AsyncValue.data(true);
    } catch (error, stack) {
      state = AsyncValue.error(error, stack);
    }
  }

  void reset() => state = const AsyncValue.data(false);
}

final connectFormControllerProvider =
    StateNotifierProvider<ConnectFormController, AsyncValue<bool>>((ref) => ConnectFormController(ref));
