import 'file_download_stub.dart' if (dart.library.js_interop) 'file_download_web.dart' as impl;

/// Hand the user a file.
///
/// Split by platform because only the browser can actually save one from
/// inside this app. Everywhere else the caller gets `false` back and
/// falls back to showing the text, rather than a button that does
/// nothing - the same honesty [FileStorage.supportsUpload] applies to
/// uploads.
bool get canDownloadFiles => impl.canDownloadFiles;

/// Returns false if this platform cannot save a file.
bool downloadText({
  required String fileName,
  required String contents,
  String mimeType = 'text/plain',
}) =>
    impl.downloadText(fileName: fileName, contents: contents, mimeType: mimeType);
