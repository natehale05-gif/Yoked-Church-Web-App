import 'package:web/web.dart' as web;

import 'document_branding.dart';

/// Writes the church's identity into the four places in `index.html`
/// that Flutter does not own.
///
/// Every write goes through [_setMeta] / [_setLink], which create the
/// element when it is missing. `index.html` ships with some of these and
/// not others - there is no `theme-color` in it at all - and a version
/// that only updated existing tags would silently do nothing for the one
/// that matters most on Android.
bool apply(DocumentBranding branding) {
  _setMeta('description', branding.description);
  _setMeta('theme-color', branding.themeColor);
  _setMeta('apple-mobile-web-app-title', branding.appleTitle);

  // Only when the church has one. Overwriting the bundled icon with an
  // empty href would leave a home screen square blank.
  if (branding.iconUrl.isNotEmpty) {
    _setLink('apple-touch-icon', branding.iconUrl);
  }
  return true;
}

void _setMeta(String name, String content) {
  final existing = web.document.querySelector('meta[name="$name"]');
  if (existing != null) {
    existing.setAttribute('content', content);
    return;
  }

  final meta = web.document.createElement('meta') as web.HTMLMetaElement
    ..name = name
    ..content = content;
  web.document.head?.append(meta);
}

void _setLink(String rel, String href) {
  final existing = web.document.querySelector('link[rel="$rel"]');
  if (existing != null) {
    existing.setAttribute('href', href);
    return;
  }

  final link = web.document.createElement('link') as web.HTMLLinkElement
    ..rel = rel
    ..href = href;
  web.document.head?.append(link);
}
