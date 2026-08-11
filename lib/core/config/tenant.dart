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

/// The prefix every church-scoped route carries.
///
/// Short on purpose: it is in front of every URL a church will ever
/// print on a card or read out from the front.
const String churchPathPrefix = '/c';

/// The address of a page within a church.
///
/// `churchPath('riverside', '/sermons')` is `/c/riverside/sermons`. The
/// one place that shape is written down, so changing the prefix is a
/// one-line change rather than a search across the app.
String churchPath(String churchId, [String subPath = '/']) {
  final rest = subPath == '/' ? '' : subPath;
  return '$churchPathPrefix/$churchId$rest';
}

/// A church's whole address, as somebody would write it on a card.
///
/// [churchPath] is the part the router reasons about; this is the part
/// you can hand out. Built from [Uri.base], which on the web is the page
/// URL, so it picks up the real origin and the deploy's base path -
/// `/Yoked-Church-Web-App/` here, `/` for a fork on its own domain -
/// rather than being hardcoded to one deployment.
///
/// The `#` is included because that is the address the router answers
/// to. `web/404.html` makes it optional for anyone typing it in, but the
/// version offered for copying should be the one that works everywhere,
/// including when it is pasted somewhere that does not follow redirects.
///
/// Returns empty where there is no web address to give: a desktop or
/// mobile build's [Uri.base] is a `file:` directory with no origin, and
/// inventing one would put a URL that goes nowhere on a copy button.
String churchUrl(String churchId, {Uri? from}) {
  final base = from ?? Uri.base;
  if (base.scheme != 'http' && base.scheme != 'https') return '';

  // The directory the app is served from. A page served as
  // `.../index.html` has that on the end, and it is not part of the
  // address anyone should be given.
  var dir = base.path;
  if (!dir.endsWith('/')) dir = dir.substring(0, dir.lastIndexOf('/') + 1);

  return '${base.origin}$dir#${churchPath(churchId)}';
}

/// The church a location names, or null if it names none.
///
/// Pure, and used from two places that cannot share anything else:
/// `main()` reads it from the browser URL *before the first frame* so a
/// deep-linked visitor never sees another church's content flash past,
/// and the router reads it from every navigation afterwards.
String? churchIdFromLocation(String location) {
  final segments = Uri.parse(location).pathSegments;
  if (segments.length < 2 || '/${segments.first}' != churchPathPrefix) return null;
  final id = segments[1].trim();
  return id.isEmpty ? null : id;
}

/// Strips the church prefix, leaving the path the app reasons about.
///
/// Every route guard, feature flag and role check was written against
/// bare paths like `/admin/settings` and stays that way; only this
/// function knows the difference.
String subPathOf(String location) {
  final id = churchIdFromLocation(location);
  if (id == null) return location;
  final rest = location.substring('$churchPathPrefix/$id'.length);
  return rest.isEmpty ? '/' : rest;
}
