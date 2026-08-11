import 'package:flutter/foundation.dart';

import '../config/church_settings.dart';
import 'document_branding_stub.dart'
    if (dart.library.js_interop) 'document_branding_web.dart' as impl;

/// The parts of a church's identity that live in the page rather than in
/// anything Flutter paints.
///
/// The app renders inside a canvas, so everything outside it - the tab,
/// the browser's own chrome, the label under a home-screen icon - comes
/// from `web/index.html`, which is one static file serving every church.
/// Left alone it tells a member of Riverside Fellowship they are looking
/// at Yoked Church.
///
/// Deliberately not the title. `MaterialApp.title` is already the church
/// name and Flutter's `Title` widget writes it to `document.title` on
/// web, so one fact keeps one owner.
@immutable
class DocumentBranding {
  /// `meta[name=description]`.
  final String description;

  /// `meta[name=theme-color]`, as `#RRGGBB`. Colours the browser's own
  /// chrome on Android and the status bar of an installed app.
  final String themeColor;

  /// `meta[name=apple-mobile-web-app-title]` - the label under the icon
  /// after Share -> Add to Home Screen on an iPhone.
  ///
  /// The one entry here that changes something a person keeps, and the
  /// one Flutter never touches. It also matters more than it looks:
  /// Apple has no sideloading, so [iosExplanation] on the download page
  /// tells iPhone users Add to Home Screen is their only option. That
  /// single path used to end in an icon labelled with another church.
  final String appleTitle;

  /// `link[rel=apple-touch-icon]`, or empty to leave whatever is there.
  ///
  /// Empty rather than a placeholder when the church has set no logo:
  /// the bundled icon is at least a real image, and pointing this at a
  /// URL that 404s would leave the home screen with a blank square.
  final String iconUrl;

  const DocumentBranding({
    required this.description,
    required this.themeColor,
    required this.appleTitle,
    required this.iconUrl,
  });

  /// What a given church's settings should put in the page.
  ///
  /// Pure, and separated from the four DOM writes so the decisions can be
  /// tested off the web - which is where the tests run.
  factory DocumentBranding.of(ChurchSettings settings) {
    final name = settings.churchName.trim();
    final tagline = settings.tagline.trim();

    return DocumentBranding(
      // The tagline is the church's own sentence about itself and is the
      // better description whenever there is one. The fallback still
      // names the church, because a description that could belong to any
      // church is barely worth having.
      description: tagline.isEmpty
          ? '$name - service times, sermons, events, and online giving.'
          : '$name - $tagline',
      themeColor: settings.colors.toMap()['primary'] as String,
      appleTitle: name,
      iconUrl: settings.logoUrl.trim(),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is DocumentBranding &&
      other.description == description &&
      other.themeColor == themeColor &&
      other.appleTitle == appleTitle &&
      other.iconUrl == iconUrl;

  @override
  int get hashCode => Object.hash(description, themeColor, appleTitle, iconUrl);
}

/// Writes [branding] into the page. A no-op anywhere that is not a browser.
///
/// Returns false where there is no document to write to, matching the
/// honesty of [canDownloadFiles] rather than pretending it worked.
bool applyDocumentBranding(DocumentBranding branding) => impl.apply(branding);
