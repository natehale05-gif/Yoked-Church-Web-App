import 'package:flutter/foundation.dart';

/// One installable build, and everything the download page needs to say
/// about it.
///
/// The [asset] names are a contract with `.github/workflows/release.yml`:
/// the buttons link to GitHub's `releases/latest/download/<asset>`
/// redirect, which is what lets a button keep working across releases
/// without rebuilding and redeploying the site. Rename an artifact in the
/// workflow and the button here 404s with nothing in between failing, so
/// `test/features/download_test.dart` parses the workflow and asserts
/// these names still match.
@immutable
class AppDownload {
  final TargetPlatform platform;

  /// What a member calls the thing they are running.
  final String label;

  /// The release asset name, fixed by the workflow.
  final String asset;

  /// The shape of the download - format and rough requirements.
  final String fileHint;

  /// How to install it once downloaded.
  final String install;

  /// What the operating system will say about an app that is not
  /// code-signed, and how to get past it.
  ///
  /// On the page rather than in a footnote deliberately. A member who
  /// taps a link from their church and gets "the developer cannot be
  /// verified" with no warning concludes the church sent them malware.
  final String warning;

  /// Anything else true of this build that a member should know before
  /// downloading it. Empty for most.
  final String caveat;

  const AppDownload({
    required this.platform,
    required this.label,
    required this.asset,
    required this.fileHint,
    required this.install,
    required this.warning,
    this.caveat = '',
  });

  /// GitHub's "latest release" redirect for this asset.
  ///
  /// [repo] is an `owner/repo` slug; leading and trailing slashes are
  /// tolerated because an admin pasting from a browser bar will include
  /// them.
  String urlFor(String repo) =>
      'https://github.com/${repo.trim().replaceAll(RegExp(r'^/+|/+$'), '')}'
      '/releases/latest/download/$asset';
}

/// Ordered as they appear on the page when nothing is detected.
const List<AppDownload> appBuilds = [
  AppDownload(
    platform: TargetPlatform.windows,
    label: 'Windows',
    asset: 'yoked-church-windows.zip',
    fileHint: 'ZIP archive · Windows 10 and later, 64-bit',
    install: 'Unzip it anywhere and run the .exe inside. Keep the whole '
        'folder together - the app needs the files next to it.',
    warning: 'Windows will show "Windows protected your PC". Choose '
        '"More info", then "Run anyway".',
  ),
  AppDownload(
    platform: TargetPlatform.macOS,
    label: 'macOS',
    asset: 'yoked-church-macos.zip',
    fileHint: 'ZIP archive · macOS 10.15 and later',
    install: 'Unzip it and drag the app into your Applications folder.',
    warning: 'macOS will say the app "cannot be opened because the '
        'developer cannot be verified". Right-click the app, choose Open, '
        'then Open again in the dialog.',
  ),
  AppDownload(
    platform: TargetPlatform.android,
    label: 'Android',
    asset: 'yoked-church-android.apk',
    fileHint: 'APK · Android 5.0 and later',
    install: 'Open the downloaded file and tap Install.',
    warning: 'Your phone will ask permission to install apps from this '
        'source, because it did not come from the Play Store. Allow it for '
        'your browser, then install.',
  ),
  AppDownload(
    platform: TargetPlatform.linux,
    label: 'Linux',
    asset: 'yoked-church-linux.tar.gz',
    fileHint: 'tar.gz archive · 64-bit, GTK 3',
    install: 'Extract it and run the executable inside: '
        '`tar -xzf yoked-church-linux.tar.gz && ./yoked_church_app`.',
    warning: 'Nothing to get past here - Linux does not gatekeep unsigned '
        'applications.',
    // Firebase publishes no Linux plugin: firebase_core, cloud_firestore,
    // firebase_auth and firebase_storage all support android, iOS, macOS,
    // web and Windows only. `main.dart` falls back to the bundled content
    // rather than crashing, which is the right behaviour but is not what
    // a member expects unless they are told.
    caveat: 'The Linux build shows the bundled demo content and cannot '
        'sign in or sync: no Firebase support exists for Linux desktop. '
        'Use the website for a live account.',
  ),
];

/// The build for the platform the visitor is on, or null if there is not
/// one - most importantly on iPhone and iPad.
AppDownload? buildForCurrentPlatform([TargetPlatform? platform]) {
  final target = platform ?? defaultTargetPlatform;
  for (final build in appBuilds) {
    if (build.platform == target) return build;
  }
  return null;
}

/// Why an iOS visitor gets no button.
///
/// Not an oversight worth hiding: Apple has no sideloading, so an iOS
/// build can only reach a phone through the App Store or TestFlight, both
/// of which need a paid developer account and a review. A download button
/// could not work, so the page says why instead of showing a dead one.
const String iosExplanation =
    'Apple does not allow apps to be installed from a link. Getting this '
    'on an iPhone or iPad would mean publishing it to the App Store. In '
    'the meantime, open this site in Safari and tap Share, then "Add to '
    'Home Screen" - it will behave much like an app.';
