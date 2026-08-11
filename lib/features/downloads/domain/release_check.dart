import 'dart:convert';

import 'package:flutter/foundation.dart';

/// What a look at the repository's latest release told us.
enum ReleaseState {
  /// There is a published release, and [ReleaseCheck.assets] names what
  /// is actually attached to it.
  published,

  /// GitHub answered clearly: there is nothing to download. Either no
  /// release has been cut, or the configured repository does not exist.
  none,

  /// We could not find out - offline, rate-limited, or an answer in a
  /// shape we did not expect.
  ///
  /// Not an error state and never shown as one. See [offers].
  unknown,
}

/// The answer to "is there actually anything behind these buttons?".
///
/// The download buttons link to GitHub's `releases/latest/download/<asset>`
/// redirect, which is what lets one deploy of the site keep working across
/// every future release. The cost of that is that a repository with no
/// release - a fresh fork of this template, or a church that filled in its
/// releases repository before publishing anything - shows four confident
/// buttons that all 404, and a member cannot tell that from the app being
/// broken.
@immutable
class ReleaseCheck {
  final ReleaseState state;

  /// The tag of the latest release, e.g. `v1.0.0`. Empty unless
  /// [state] is [ReleaseState.published].
  final String tag;

  /// Asset file names attached to that release.
  final Set<String> assets;

  const ReleaseCheck._(this.state, this.tag, this.assets);

  /// The state to hold while the check is in flight, and to fall back to
  /// whenever it fails. See [offers] for why this is the default.
  static const ReleaseCheck unknown = ReleaseCheck._(ReleaseState.unknown, '', {});

  static const ReleaseCheck none = ReleaseCheck._(ReleaseState.none, '', {});

  /// Reads GitHub's `releases/latest` response.
  ///
  /// A body we cannot make sense of comes back [unknown] rather than
  /// [none]: "we did not understand the answer" and "there is nothing
  /// there" are different facts, and only one of them should take the
  /// buttons away.
  factory ReleaseCheck.fromResponseBody(String body) {
    try {
      final json = jsonDecode(body);
      if (json is! Map<String, dynamic>) return unknown;

      final assets = <String>{
        for (final asset in (json['assets'] as List<dynamic>? ?? const []))
          if (asset is Map<String, dynamic> && asset['name'] is String) asset['name'] as String,
      };

      // A release with nothing attached is far more likely to mean we
      // read the shape wrong than that somebody published an empty
      // release, and guessing wrong here hides working downloads.
      if (assets.isEmpty) return unknown;

      return ReleaseCheck._(
        ReleaseState.published,
        json['tag_name'] as String? ?? '',
        assets,
      );
    } catch (_) {
      return unknown;
    }
  }

  /// Whether to offer a download button for [asset].
  ///
  /// Everything except a confident "that file is not there". The
  /// asymmetry is deliberate and is the whole design of this feature: a
  /// working download hidden behind a check that failed is a worse
  /// outcome than the dead button this exists to prevent. Rate limits and
  /// flaky connections are common; a repository with no release is a
  /// one-time condition somebody fixes and never sees again.
  bool offers(String asset) => switch (state) {
        ReleaseState.published => assets.contains(asset),
        ReleaseState.none => false,
        ReleaseState.unknown => true,
      };

  /// Whether to say, in as many words, that there is nothing here yet.
  bool get isEmpty => state == ReleaseState.none;

  /// Whether some builds are missing from a release that does exist -
  /// one platform failed in CI while the rest published.
  bool missingAny(Iterable<String> wanted) =>
      state == ReleaseState.published && wanted.any((a) => !assets.contains(a));
}
