import 'dart:js_interop';

import 'package:web/web.dart' as web;

const bool canDownloadFiles = true;

/// Blob + object URL + a synthetic anchor click - the only way a page can
/// save a file without a server round trip. A `data:` URL would be
/// simpler but browsers block top-level navigation to one, which is
/// exactly what a download is.
bool downloadText({
  required String fileName,
  required String contents,
  String mimeType = 'text/plain',
}) {
  // The BOM is not decoration: without it Excel opens a UTF-8 CSV as
  // Latin-1 and mangles every accented name in the congregation.
  final blob = web.Blob(
    ['﻿$contents'.toJS].toJS,
    web.BlobPropertyBag(type: '$mimeType;charset=utf-8'),
  );
  final url = web.URL.createObjectURL(blob);
  final anchor = web.document.createElement('a') as web.HTMLAnchorElement
    ..href = url
    ..download = fileName;
  anchor.click();
  web.URL.revokeObjectURL(url);
  return true;
}
