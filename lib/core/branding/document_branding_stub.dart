import 'document_branding.dart';

/// Non-web builds. There is no document, and the desktop and mobile
/// shells take their name and icon from the bundle rather than from
/// anything the app can set at runtime.
bool apply(DocumentBranding branding) => false;
