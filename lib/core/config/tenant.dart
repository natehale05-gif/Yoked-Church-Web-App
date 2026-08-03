import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The church the app is currently acting as.
///
/// This is the single value that turns one binary into any church's app.
/// Every Firestore repository is built from it (see `lib/app/backend.dart`),
/// so changing it rebuilds the whole data layer and the app re-themes and
/// re-reads without a restart.
///
/// Overridden at startup with whatever was last chosen, and written by the
/// church picker. Null means nobody has chosen yet, which the router turns
/// into the picker.
final selectedChurchIdProvider = StateProvider<String?>((ref) => null);

/// The church id repositories should use right now.
///
/// Falls back to [demoChurchId] rather than throwing: the zero-backend
/// build has no picker to go through, and a null here would otherwise
/// mean every repository had to handle "no church yet" separately.
final currentChurchIdProvider = Provider<String>((ref) {
  return ref.watch(selectedChurchIdProvider) ?? demoChurchId;
});

/// The church the bundled sample content describes.
///
/// Also the id a single-church deployment can use if it never wants a
/// picker at all - point every member at this one and the app behaves
/// exactly as it did before it learned about tenancy.
const String demoChurchId = 'yoked-demo';
