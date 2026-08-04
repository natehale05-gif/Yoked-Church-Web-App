import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/config/tenant.dart';
import '../data/church_directory_repository.dart';
import '../domain/church_summary.dart';

/// Overridden at startup, like every other repository.
final churchDirectoryProvider = Provider<ChurchDirectoryRepository>((ref) {
  throw UnimplementedError('churchDirectoryProvider must be overridden in ProviderScope');
});

/// Every church a member could choose.
final churchesProvider = FutureProvider<List<ChurchSummary>>((ref) {
  return ref.watch(churchDirectoryProvider).fetchAll();
});

/// What the member has typed into the picker's search box.
final churchSearchProvider = StateProvider<String>((ref) => '');

/// The churches matching that search, in directory order.
final matchingChurchesProvider = Provider<List<ChurchSummary>>((ref) {
  final all = ref.watch(churchesProvider).valueOrNull ?? const <ChurchSummary>[];
  final query = ref.watch(churchSearchProvider);
  return all.where((church) => church.matches(query)).toList();
});

/// The chosen church's directory entry, for showing which one you are in.
final currentChurchProvider = Provider<ChurchSummary?>((ref) {
  final id = ref.watch(selectedChurchIdProvider);
  if (id == null) return null;
  for (final church in ref.watch(churchesProvider).valueOrNull ?? const <ChurchSummary>[]) {
    if (church.id == id) return church;
  }
  return null;
});

/// Remembers the church across restarts.
///
/// A member picks their church once, not every time they open the app.
/// Kept deliberately small - one string - because it is read on the very
/// first frame and anything heavier would delay the app opening.
class ChurchPreference {
  static const _key = 'selectedChurchId';

  /// Reads the stored choice, or null on the first ever launch.
  ///
  /// Never throws: a member whose stored preferences are unreadable
  /// should land on the picker, not on a crash.
  static Future<String?> read() async {
    try {
      return (await SharedPreferences.getInstance()).getString(_key);
    } catch (_) {
      return null;
    }
  }

  static Future<void> write(String churchId) async {
    try {
      await (await SharedPreferences.getInstance()).setString(_key, churchId);
    } catch (_) {
      // Losing the preference costs one more tap next launch, which is
      // not worth failing the church switch the member just asked for.
    }
  }

  static Future<void> clear() async {
    try {
      await (await SharedPreferences.getInstance()).remove(_key);
    } catch (_) {}
  }
}

/// Selects a church.
///
/// Synchronous on purpose. Writing [selectedChurchIdProvider] rebuilds
/// every repository, so the app *is* the new church the moment this
/// returns - there is no reason to make the member wait on a disk write
/// before the screen changes, and awaiting one here would put real I/O
/// in the middle of a tap handler.
///
/// Remembering the choice is best-effort and happens behind the tap. The
/// cost of it failing is one extra tap next launch.
void chooseChurch(WidgetRef ref, String churchId) {
  ref.read(selectedChurchIdProvider.notifier).state = churchId;
  ref.read(churchSearchProvider.notifier).state = '';
  ChurchPreference.write(churchId);
}

/// Where choosing a church should take you.
///
/// The provider and the URL are two halves of the same fact now, and the
/// only way they cannot disagree is if one function sets both. Callers
/// do `chooseChurch(...)` then `context.go(churchHome(id))`.
String churchHome(String churchId) => churchPath(churchId);
