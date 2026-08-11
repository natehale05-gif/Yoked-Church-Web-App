import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// What a link to this site looks like before anyone clicks it.
///
/// The app renders into a canvas, so none of this comes from Dart - it is
/// `web/index.html`, one static file serving every church, and nothing in
/// the build fails if it drifts. A missing card file or a size that
/// disagrees with the tags is invisible until somebody pastes a link
/// somewhere and gets a bare URL.
void main() {
  final indexHtml = File('web/index.html').readAsStringSync();
  final manifest = File('web/manifest.json').readAsStringSync();

  String? metaContent(String selector, String name) {
    final match = RegExp(
      '<meta\\s+$selector="${RegExp.escape(name)}"\\s+content="([^"]*)"',
    ).firstMatch(indexHtml);
    return match?.group(1);
  }

  String? property(String name) => metaContent('property', name);
  String? named(String name) => metaContent('name', name);

  group('a pasted link renders as something', () {
    test('the tags a preview is built from are all there', () {
      // Every one of these is load-bearing in at least one client:
      // og:title and og:description in Facebook and WhatsApp, twitter:card
      // for the large image on X, og:image everywhere.
      for (final tag in ['og:type', 'og:site_name', 'og:title', 'og:description', 'og:image']) {
        expect(property(tag), isNotNull, reason: '$tag is missing from index.html');
        expect(property(tag), isNotEmpty);
      }

      expect(named('twitter:card'), 'summary_large_image');
      expect(named('twitter:title'), isNotNull);
      expect(named('twitter:image'), isNotNull);
    });

    test('the image is an absolute URL', () {
      // Crawlers do not resolve <base href>, and a relative og:image is
      // simply dropped - which looks identical to having no card at all.
      for (final url in [property('og:image'), named('twitter:image')]) {
        expect(url, startsWith('https://'), reason: 'a relative og:image is ignored');
      }
    });

    test('the card exists, and is the size the tags promise', () {
      final card = File('web/social-card.png');
      expect(
        card.existsSync(),
        isTrue,
        reason: 'regenerate it with `node web/tools/build_social_card.mjs`',
      );

      final bytes = card.readAsBytesSync();
      expect(bytes.sublist(1, 4), [0x50, 0x4E, 0x47], reason: 'not a PNG');

      // IHDR puts width and height as big-endian 32-bit ints at offsets
      // 16 and 20. Cheaper than a decoder for the one fact worth knowing.
      int intAt(int offset) =>
          (bytes[offset] << 24) | (bytes[offset + 1] << 16) | (bytes[offset + 2] << 8) | bytes[offset + 3];

      expect(intAt(16).toString(), property('og:image:width'));
      expect(intAt(20).toString(), property('og:image:height'));
    });

    test('the og:image filename matches what the generator writes', () {
      final generator = File('web/tools/build_social_card.mjs').readAsStringSync();
      final written = RegExp(r"'web', '([^']+)'").firstMatch(generator)?.group(1);

      expect(written, isNotNull, reason: 'the generator no longer names its output file');
      expect(property('og:image'), endsWith('/$written'));
    });
  });

  /// One static file serves every church, so it has to describe the
  /// product. It used to say "Yoked Church" - the demo church - which
  /// meant every church's tab, bookmark and installed app opened with
  /// somebody else's name on it.
  group('the static page describes the product, not a church', () {
    test('nothing left in index.html is named after one congregation', () {
      final title = RegExp(r'<title>([^<]*)</title>').firstMatch(indexHtml)?.group(1);

      expect(title, 'Yoked');
      expect(named('apple-mobile-web-app-title'), 'Yoked');

      // Comments stripped first: they are allowed to explain what this
      // used to say, and the claim being made is about what a browser or
      // a crawler reads, not about the source.
      final rendered = indexHtml.replaceAll(RegExp(r'<!--.*?-->', dotAll: true), '');
      expect(
        rendered,
        isNot(contains('Yoked Church')),
        reason: 'Yoked Church is the demo church in churches.json, not this product',
      );
    });

    test('nor in the manifest, which names the installed app', () {
      expect(manifest, contains('"name": "Yoked"'));
      expect(manifest, isNot(contains('Yoked Church')));
    });

    test('there is a theme-color for the runtime branding to overwrite', () {
      // Absent entirely before this, so Android drew default grey chrome
      // for every church. `document_branding_web.dart` creates it when
      // missing, but shipping it means the first paint is right too.
      expect(named('theme-color'), isNotNull);
    });
  });
}
