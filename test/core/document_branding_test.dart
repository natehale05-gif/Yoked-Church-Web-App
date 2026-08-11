import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yoked_church_app/core/branding/document_branding.dart';
import 'package:yoked_church_app/core/config/church_settings.dart';

import '../fakes/fake_repositories.dart';

/// The page's own identity - the description, the browser chrome colour,
/// the label under a home-screen icon - lives in `index.html`, which is
/// one static file serving every church. Left alone it tells a member of
/// Riverside Fellowship they are looking at Yoked Church.
///
/// These cover the decisions. The four DOM writes they feed can only run
/// in a browser, and are checked there instead.
void main() {
  group('what a church puts in the page', () {
    test('the description is the church\'s own sentence about itself', () {
      final branding = DocumentBranding.of(
        testSettings(churchName: 'Riverside Fellowship', tagline: 'A place at the table for everyone.'),
      );

      expect(branding.description, 'Riverside Fellowship - A place at the table for everyone.');
    });

    test('a church with no tagline still gets a description naming it', () {
      // The generic sentence on its own could belong to any church, which
      // is barely worth having as a description.
      final branding = DocumentBranding.of(
        testSettings(churchName: 'Riverside Fellowship', tagline: '   '),
      );

      expect(branding.description, startsWith('Riverside Fellowship'));
      expect(branding.description, contains('sermons'));
    });

    test('the theme colour is the church\'s primary, as a hex the browser reads', () {
      final branding = DocumentBranding.of(
        testSettings(
          colors: const BrandColors(
            primary: Color(0xFF2F5D50),
            accent: Color(0xFFE07A3F),
            background: Color(0xFFF7F5F0),
          ),
        ),
      );

      expect(branding.themeColor, '#2F5D50');
    });

    test('the iOS home-screen label is the church name, not the product', () {
      // Flutter never touches this one, and iOS reads it at the moment
      // somebody taps Share -> Add to Home Screen. On an iPhone that is
      // the only way to get this app at all, so the label it leaves
      // behind is the whole result.
      expect(
        DocumentBranding.of(testSettings(churchName: "St Augustine's")).appleTitle,
        "St Augustine's",
      );
    });

    test('a church with no logo leaves the bundled icon alone', () {
      // Rather than pointing the icon at an empty href, which would leave
      // a blank square on somebody's home screen.
      expect(DocumentBranding.of(testSettings()).iconUrl, isEmpty);
      expect(
        DocumentBranding.of(testSettings(logoUrl: 'https://example.org/logo.png')).iconUrl,
        'https://example.org/logo.png',
      );
    });

    test('two churches do not produce the same branding', () {
      // The equality is what stops the DOM being rewritten on every
      // unrelated settings change, so it has to actually distinguish.
      final riverside = DocumentBranding.of(testSettings(churchName: 'Riverside'));
      final augustine = DocumentBranding.of(testSettings(churchName: 'St Augustine'));

      expect(riverside, isNot(augustine));
      expect(riverside, DocumentBranding.of(testSettings(churchName: 'Riverside')));
    });
  });

  test('there is nothing to write to off the web, and it says so', () {
    // The tests run on the VM, so this is the stub - which is the point:
    // a desktop or mobile build takes its name and icon from the bundle,
    // and pretending otherwise would be the same dishonesty as a download
    // button that cannot download.
    expect(
      applyDocumentBranding(DocumentBranding.of(testSettings())),
      isFalse,
    );
  });
}
