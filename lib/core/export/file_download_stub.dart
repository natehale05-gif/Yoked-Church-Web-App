/// Non-web builds. Saving a file needs a platform path picker this app
/// does not carry, so callers show the text instead.
const bool canDownloadFiles = false;

bool downloadText({
  required String fileName,
  required String contents,
  String mimeType = 'text/plain',
}) =>
    false;
