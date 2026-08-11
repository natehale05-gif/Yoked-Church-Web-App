import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../../core/config/settings_providers.dart';
import '../domain/release_check.dart';

/// Overridden in tests so no test ever depends on GitHub being up.
final httpClientProvider = Provider<http.Client>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return client;
});

/// How long to wait before deciding we do not know.
///
/// Short, because the answer only ever removes buttons. Someone on a slow
/// connection should get the download page, not a spinner.
const Duration releaseCheckTimeout = Duration(seconds: 6);

/// Asks GitHub whether [repo] has a release, and what is attached to it.
///
/// Unauthenticated, which is both fine and necessary - this runs in a
/// member's browser, and the endpoint is public and CORS-permitted. The
/// unauthenticated rate limit is per client IP, and hitting it returns
/// [ReleaseCheck.unknown], which shows the buttons.
Future<ReleaseCheck> fetchReleaseCheck(http.Client client, String repo) async {
  final slug = repo.trim().replaceAll(RegExp(r'^/+|/+$'), '');
  if (slug.isEmpty) return ReleaseCheck.unknown;

  try {
    final response = await client
        .get(
          Uri.parse('https://api.github.com/repos/$slug/releases/latest'),
          headers: const {'Accept': 'application/vnd.github+json'},
        )
        .timeout(releaseCheckTimeout);

    // 404 is the honest answer to both "no release yet" and "no such
    // repository". They are the same fact to whoever is looking at the
    // page: there is nothing to download from the address configured.
    if (response.statusCode == 404) return ReleaseCheck.none;
    if (response.statusCode != 200) return ReleaseCheck.unknown;

    return ReleaseCheck.fromResponseBody(response.body);
  } catch (_) {
    // Offline, DNS, TLS, timeout, a proxy in the way. All of them mean
    // the same thing here, and none of them should hide a download.
    return ReleaseCheck.unknown;
  }
}

/// The check for the church's configured releases repository.
///
/// Not auto-disposed: the answer does not change while somebody reads the
/// page, and re-fetching on every visit spends the rate limit for nothing.
final releaseCheckProvider = FutureProvider<ReleaseCheck>((ref) {
  final repo = ref.watch(settingsProvider.select((s) => s.releasesRepo));
  return fetchReleaseCheck(ref.watch(httpClientProvider), repo);
});
