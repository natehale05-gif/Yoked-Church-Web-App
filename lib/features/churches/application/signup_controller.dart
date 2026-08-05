import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_providers.dart';
import '../data/church_directory_repository.dart';
import 'church_providers.dart';

/// Creating an account and a church in one go.
///
/// Two steps that have to look like one. A person filling in this form
/// is not thinking "first I make an account, then a tenant" - they are
/// thinking "I am setting up our church" - so a failure at either step
/// has to leave them with something they can act on rather than half a
/// setup and a stack trace.
class SignupController extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;

  SignupController(this._ref) : super(const AsyncValue.data(null));

  /// Returns the new church's id on success, or null with the reason
  /// held in [state] for the form to show.
  Future<String?> createChurch({
    required String churchName,
    required String yourName,
    required String email,
    required String password,
    required String desiredSlug,
  }) async {
    state = const AsyncValue.loading();
    try {
      // The account first: creating a church means writing yourself in
      // as its admin, and the server needs to know who you are to do
      // that. Signing up when already signed in is not an error - a
      // pastor adding a second church is a real thing - so an
      // already-in-use email is only a problem if it is not *this*
      // account.
      if (!_ref.read(isSignedInProvider)) {
        await _ref.read(authControllerProvider.notifier).signUp(email, password, yourName);
        final failure = _ref.read(authControllerProvider).error;
        if (failure != null) {
          state = AsyncValue.error(failure, StackTrace.current);
          return null;
        }
      }

      final id = await _ref
          .read(churchDirectoryProvider)
          .create(name: churchName, desiredSlug: desiredSlug);

      // Whoever sets up a church runs it - there is nobody else yet to
      // promote them. On a real backend the server already did this in
      // the same transaction that created the church; with no backend
      // this is where it happens.
      await _ref.read(authRepositoryProvider).becomeFounder(id);

      // Read it back into the picker so the church exists everywhere
      // before the browser lands on it.
      _ref.invalidate(churchesProvider);
      state = const AsyncValue.data(null);
      return id;
    } on ChurchCreationFailure catch (error, stack) {
      state = AsyncValue.error(error, stack);
      return null;
    } catch (error, stack) {
      state = AsyncValue.error(error, stack);
      return null;
    }
  }
}

final signupControllerProvider =
    StateNotifierProvider<SignupController, AsyncValue<void>>((ref) => SignupController(ref));
