import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Fonts are the one asset a Flutter web build fetches *before it can
/// draw anything*: every face declared in `pubspec.yaml` is downloaded up
/// front, used or not, on the slowest connection any member has.
///
/// Three of the eight declared here were never drawn - `Lora-Italic`,
/// `Lora-BoldItalic` and `WorkSans-BoldItalic`, 452KB of them - because
/// the four-face set is what you get from copying a font family off the
/// internet, not from asking what the app renders. This is the check
/// that keeps that from creeping back, in both directions.
void main() {
  final pubspec = File('pubspec.yaml').readAsStringSync();

  /// The `fonts:` block, which is the only part of pubspec this is about.
  String fontsBlock() {
    final start = pubspec.indexOf(RegExp(r'^  fonts:$', multiLine: true));
    expect(start, greaterThan(-1), reason: 'pubspec declares no fonts at all');
    return pubspec.substring(start);
  }

  /// Every declared face as (family, weight, style).
  List<({String family, String weight, String style})> declaredFaces() {
    final faces = <({String family, String weight, String style})>[];
    var family = '';
    String? asset;
    var weight = '400';
    var style = 'normal';

    void flush() {
      if (asset != null) faces.add((family: family, weight: weight, style: style));
      asset = null;
      weight = '400';
      style = 'normal';
    }

    for (final line in fontsBlock().split('\n')) {
      final familyMatch = RegExp(r'^\s*-\s*family:\s*(\S+)').firstMatch(line);
      if (familyMatch != null) {
        flush();
        family = familyMatch.group(1)!;
        continue;
      }
      final assetMatch = RegExp(r'^\s*-\s*asset:\s*(\S+)').firstMatch(line);
      if (assetMatch != null) {
        flush();
        asset = assetMatch.group(1);
        continue;
      }
      final weightMatch = RegExp(r'^\s*weight:\s*(\d+)').firstMatch(line);
      if (weightMatch != null) weight = weightMatch.group(1)!;
      final styleMatch = RegExp(r'^\s*style:\s*(\S+)').firstMatch(line);
      if (styleMatch != null) style = styleMatch.group(1)!;
    }
    flush();
    return faces;
  }

  /// Font asset paths pubspec names.
  List<String> declaredAssets() => RegExp(r'^\s*-\s*asset:\s*(assets/fonts/\S+)', multiLine: true)
      .allMatches(fontsBlock())
      .map((m) => m.group(1)!)
      .toList();

  /// Every .dart file under lib/, read once.
  final source = Directory('lib')
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .map((f) => f.readAsStringSync())
      .join('\n');

  test('every declared font file is actually there', () {
    // A missing asset is a build failure at best and a silently
    // substituted font at worst.
    for (final asset in declaredAssets()) {
      expect(File(asset).existsSync(), isTrue, reason: '$asset is declared but missing');
    }
    expect(declaredAssets(), isNotEmpty);
  });

  test('nothing on disk is left declared by nobody', () {
    // The other direction: a font file that survived a trim is dead
    // weight in the repo even though it no longer reaches a browser.
    final onDisk = Directory('assets/fonts')
        .listSync()
        .whereType<File>()
        .map((f) => f.path)
        .where((p) => p.endsWith('.ttf'))
        .toSet();

    expect(onDisk, declaredAssets().toSet());
  });

  test('the app never asks for a slant nothing declares', () {
    // `FontStyle.italic` with no italic face makes the engine synthesise
    // one by shearing the upright, which looks wrong in a way nobody
    // reports as a bug - they just think the site looks cheap.
    final wantsItalic = source.contains('FontStyle.italic');
    final hasItalic = declaredFaces().any((f) => f.style == 'italic');

    expect(
      hasItalic,
      wantsItalic,
      reason: wantsItalic
          ? 'something uses FontStyle.italic but no italic face is declared'
          : 'an italic face is declared that nothing uses - it is downloaded anyway',
    );
  });

  test('the heading face is upright only, because headings never slant', () {
    // Lora is headings (see theme.dart). If that ever changes, this
    // fails and the missing face gets declared deliberately rather than
    // being synthesised.
    final lora = declaredFaces().where((f) => f.family == 'Lora');

    expect(lora, isNotEmpty);
    expect(
      lora.every((f) => f.style == 'normal'),
      isTrue,
      reason: 'a Lora italic is declared; nothing in the app slants a heading',
    );
  });

  test('nothing asks for bold italic on either family', () {
    // Both bold-italic faces were declared and never used. There is no
    // way to grep for "bold italic" directly, so this pins the thing
    // that would need one: a TextStyle setting both at once.
    final boldItalic = RegExp(
      r'fontStyle:\s*FontStyle\.italic[^)]*fontWeight:\s*FontWeight\.(w[6-9]00|bold)'
      r'|fontWeight:\s*FontWeight\.(w[6-9]00|bold)[^)]*fontStyle:\s*FontStyle\.italic',
    );

    expect(
      boldItalic.hasMatch(source),
      isFalse,
      reason: 'something wants bold italic; declare the face or it will be synthesised',
    );
  });
}
