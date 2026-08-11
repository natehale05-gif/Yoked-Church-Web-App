import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// A church's address is the product's whole pitch - hand this link out,
/// print it on a card - and on GitHub Pages that address is
/// `.../Yoked-Church-Web-App/#/c/grace-chapel`, because the app routes on
/// the URL fragment. Typed from memory it arrives without the `#`, reaches
/// no file, and Pages serves `web/404.html`.
///
/// That file turns the request back into the hash form. It cannot be
/// exercised from Dart - it is a few lines of JavaScript that only run in
/// a browser - so what is pinned here is the coupling that would silently
/// break it: how much of the path belongs to the site rather than to the
/// route. `deploy.yml` decides that with `--base-href`; `404.html` has to
/// agree, and nothing fails in between if they drift.
void main() {
  final redirect = File('web/404.html').readAsStringSync();
  final deploy = File('.github/workflows/deploy.yml').readAsStringSync();

  group('the Pages redirect and the deploy agree on where the site lives', () {
    /// The `--base-href` the site is built with, e.g. `/Yoked-Church-Web-App/`.
    String baseHref() {
      final match = RegExp(r'--base-href\s+"([^"]+)"').firstMatch(deploy);
      expect(match, isNotNull, reason: 'deploy.yml no longer sets a base href');
      return match!.group(1)!;
    }

    /// The constant `404.html` strips before treating the rest as a route.
    int segmentsInBase() {
      final match = RegExp(r'PATH_SEGMENTS_IN_BASE\s*=\s*(\d+)').firstMatch(redirect);
      expect(match, isNotNull, reason: '404.html no longer names how much of the path is the base');
      return int.parse(match!.group(1)!);
    }

    test('the base href is one path segment, so the redirect strips one', () {
      final segments = baseHref().split('/').where((s) => s.isNotEmpty).length;

      expect(
        segmentsInBase(),
        segments,
        reason: 'strip too few and the church id lands in the base; strip too '
            'many and the deep link is thrown away',
      );
    });

    test('the redirect rebuilds the address in the form the router reads', () {
      // Hash routing, not path routing. A redirect that dropped the `#`
      // would send the request straight back to this same 404.
      expect(redirect, contains("'#/'"));
      expect(redirect, contains('l.replace('));
    });

    test('it carries the deep link through rather than landing on the home page', () {
      // Somebody sent `/c/grace-chapel/events` for a reason. Redirecting
      // every miss to the front door would be a fix that loses the point.
      expect(redirect, contains('l.search'));
      expect(redirect, contains('segments.slice(PATH_SEGMENTS_IN_BASE)'));
    });

    test('a miss on the base itself is left alone rather than looped', () {
      // Nothing under the base means index.html is genuinely missing - a
      // broken deploy. Redirecting would bounce between the two forever.
      expect(redirect, contains('route.length === 0'));
    });
  });

  test('the redirect ships with the site', () {
    // Everything in web/ other than index.html is copied verbatim into
    // build/web, and `deploy.yml` uploads that directory whole. A file
    // that is not there is a file Pages never serves.
    expect(File('web/404.html').existsSync(), isTrue);
    expect(deploy, contains('path: build/web'));
  });
}
