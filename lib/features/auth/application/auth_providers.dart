import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/auth_repository.dart';
import '../data/user_repository.dart';
import '../domain/app_user.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  throw UnimplementedError('authRepositoryProvider must be overridden in ProviderScope');
});

final userRepositoryProvider = Provider<UserRepository>((ref) {
  throw UnimplementedError('userRepositoryProvider must be overridden in ProviderScope');
});

/// The signed-in member, or null. Drives both the UI and the route guards.
final authStateProvider = StreamProvider<AppUser?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges();
});

final currentUserProvider = Provider<AppUser?>((ref) => ref.watch(authStateProvider).valueOrNull);

final isSignedInProvider = Provider<bool>((ref) => ref.watch(currentUserProvider) != null);

final isStaffProvider = Provider<bool>((ref) => ref.watch(currentUserProvider)?.isStaff ?? false);

final isAdminProvider = Provider<bool>((ref) => ref.watch(currentUserProvider)?.isAdmin ?? false);

/// True until the first auth emission arrives, so route guards don't
/// bounce a signed-in member to the login page during startup.
final authLoadingProvider = Provider<bool>((ref) => ref.watch(authStateProvider).isLoading);

final memberDirectoryProvider = FutureProvider<List<AppUser>>((ref) {
  // Re-read whenever the signed-in user changes (e.g. after opting in).
  ref.watch(currentUserProvider);
  return ref.watch(userRepositoryProvider).fetchDirectory();
});

final allMembersProvider = StreamProvider<List<AppUser>>((ref) {
  return ref.watch(userRepositoryProvider).watchAll();
});

/// Drives the sign-in/sign-up forms: exposes busy state and surfaces
/// failures as messages rather than thrown exceptions.
class AuthController extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;

  AuthController(this._ref) : super(const AsyncValue.data(null));

  AuthRepository get _repo => _ref.read(authRepositoryProvider);

  Future<bool> signIn(String email, String password) =>
      _run(() => _repo.signIn(email: email, password: password));

  Future<bool> signUp(String email, String password, String displayName) =>
      _run(() => _repo.signUp(email: email, password: password, displayName: displayName));

  Future<bool> signInWithGoogle() => _run(_repo.signInWithGoogle);

  Future<bool> signInWithApple() => _run(_repo.signInWithApple);

  Future<bool> sendPasswordReset(String email) => _run(() => _repo.sendPasswordReset(email));

  Future<bool> signInAsDemo(UserRole role) => _run(() => _repo.signInAsDemo(role));

  Future<void> signOut() => _repo.signOut();

  /// Returns true on success; on failure the error is held in [state] for
  /// the form to display.
  Future<bool> _run(Future<void> Function() action) async {
    state = const AsyncValue.loading();
    try {
      await action();
      state = const AsyncValue.data(null);
      return true;
    } catch (error, stack) {
      state = AsyncValue.error(error, stack);
      return false;
    }
  }
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AsyncValue<void>>((ref) => AuthController(ref));

/// Saves profile edits made by the member themselves.
final profileControllerProvider = Provider<ProfileController>((ref) => ProfileController(ref));

class ProfileController {
  final Ref _ref;

  ProfileController(this._ref);

  Future<void> save(AppUser user) => _ref.read(userRepositoryProvider).update(user);
}
