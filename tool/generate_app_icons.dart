// Generates every platform's launcher icon from the app's own brand mark.
//
// Run it with:
//
//     flutter test tool/generate_app_icons.dart
//
// It writes into android/, macos/, windows/ and web/, so the generated
// files are committed and nobody needs to run this to build the app.
// Re-run it after changing the brand colours or the mark below.
//
// This is a `flutter test` rather than a `dart run` because rasterising
// anything needs the Flutter engine, and the test harness is the only
// way to get one headlessly. It asserts nothing; the harness is a
// rendering surface.
//
// Why generate rather than draw by hand: the mark is `Icons.church` in
// the church's own primary and accent colours, which is exactly what the
// site's wordmark shows. Hand-drawn files would drift from the app the
// first time somebody changed a brand colour.

import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yoked_church_app/core/config/church_settings.dart';

/// The mark, at whatever size is asked for.
///
/// The glyph sits at 62% of the canvas, which keeps it inside the safe
/// zone Android's adaptive icons and the web's maskable icons crop to -
/// both can clip up to 20% off each edge, and a mark drawn edge to edge
/// loses its extremities on a round-icon launcher.
Widget _icon(double size, BrandColors colors) {
  return Container(
    width: size,
    height: size,
    color: colors.primary,
    child: Center(
      child: Icon(Icons.church, size: size * 0.62, color: colors.accent),
    ),
  );
}

/// The mark alone, on transparency, for Android's adaptive icons.
///
/// An adaptive icon's foreground layer is 108dp of which only the middle
/// 72dp is guaranteed visible - launchers crop the rest to whatever
/// shape they use. So the glyph is drawn at 42% of the canvas, which
/// lands inside that circle with room to spare.
Widget _foreground(double size, BrandColors colors) {
  return SizedBox(
    width: size,
    height: size,
    child: Center(
      child: Icon(Icons.church, size: size * 0.42, color: colors.accent),
    ),
  );
}

void main() {
  const colors = BrandColors.fallback;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await _loadMaterialIcons();
  });

  testWidgets('write the launcher icons', (tester) async {
    Future<Uint8List> render(int size, {bool foregroundOnly = false}) =>
        _render(tester, size, colors, foregroundOnly: foregroundOnly);

    // Android launcher icons, one per density bucket.
    const androidDensities = {
      'mdpi': 48,
      'hdpi': 72,
      'xhdpi': 96,
      'xxhdpi': 144,
      'xxxhdpi': 192,
    };
    for (final entry in androidDensities.entries) {
      _write(
        'android/app/src/main/res/mipmap-${entry.key}/ic_launcher.png',
        await render(entry.value),
      );
    }

    // Adaptive icons, so Android 8 and later shapes the mark to the
    // launcher instead of letterboxing a square PNG. The foreground
    // canvas is 108dp against the legacy icon's 48dp, hence the larger
    // pixel sizes.
    const adaptiveDensities = {
      'mdpi': 108,
      'hdpi': 162,
      'xhdpi': 216,
      'xxhdpi': 324,
      'xxxhdpi': 432,
    };
    for (final entry in adaptiveDensities.entries) {
      _write(
        'android/app/src/main/res/mipmap-${entry.key}/ic_launcher_foreground.png',
        await render(entry.value, foregroundOnly: true),
      );
    }

    _write(
      'android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml',
      _utf8('''<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@color/ic_launcher_background" />
    <foreground android:drawable="@mipmap/ic_launcher_foreground" />
</adaptive-icon>
'''),
    );

    _write(
      'android/app/src/main/res/values/ic_launcher_background.xml',
      _utf8('''<?xml version="1.0" encoding="utf-8"?>
<resources>
    <color name="ic_launcher_background">${_hex(colors.primary)}</color>
</resources>
'''),
    );

    // macOS asset catalogue. The filenames are fixed by Contents.json.
    for (final size in [16, 32, 64, 128, 256, 512, 1024]) {
      _write(
        'macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_$size.png',
        await render(size),
      );
    }

    // Web: PWA icons, their maskable twins, and the favicon.
    _write('web/icons/Icon-192.png', await render(192));
    _write('web/icons/Icon-512.png', await render(512));
    _write('web/icons/Icon-maskable-192.png', await render(192));
    _write('web/icons/Icon-maskable-512.png', await render(512));
    _write('web/favicon.png', await render(16));

    // Windows wants one .ico holding several sizes.
    _write(
      'windows/runner/resources/app_icon.ico',
      _ico({for (final size in [16, 32, 48, 64, 128, 256]) size: await render(size)}),
    );
  });
}

/// Renders the mark and returns PNG bytes.
Future<Uint8List> _render(
  WidgetTester tester,
  int size,
  BrandColors colors, {
  bool foregroundOnly = false,
}) async {
  final key = GlobalKey();
  tester.view.physicalSize = Size(size.toDouble(), size.toDouble());
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: RepaintBoundary(
        key: key,
        child: foregroundOnly
            ? _foreground(size.toDouble(), colors)
            : _icon(size.toDouble(), colors),
      ),
    ),
  );
  await tester.pump();

  final boundary = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;

  // Encoding is real engine work, so it has to happen outside the fake
  // async zone a widget test runs in - inside it, the future never
  // completes and the run hangs until the timeout.
  late Uint8List bytes;
  await tester.runAsync(() async {
    final image = await boundary.toImage();
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    bytes = data!.buffer.asUint8List();
    image.dispose();
  });
  return bytes;
}

/// Synchronous on purpose: same fake-async trap as the encoding above.
void _write(String path, Uint8List bytes) {
  final file = File(path);
  file.parent.createSync(recursive: true);
  file.writeAsBytesSync(bytes);
  // ignore: avoid_print
  print('wrote $path (${bytes.length} bytes)');
}

Uint8List _utf8(String text) => Uint8List.fromList(text.codeUnits);

String _hex(Color color) =>
    '#${(color.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

/// Packs PNGs into a Windows .ico.
///
/// The format is a 6-byte header, a 16-byte directory entry per image,
/// then the image payloads. Entries may hold a PNG verbatim rather than
/// a bitmap, which every Windows since Vista reads, and which is why
/// this needs no image library.
Uint8List _ico(Map<int, Uint8List> images) {
  final entries = images.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
  final header = ByteData(6)
    ..setUint16(0, 0, Endian.little) // reserved
    ..setUint16(2, 1, Endian.little) // type: icon
    ..setUint16(4, entries.length, Endian.little);

  var offset = 6 + entries.length * 16;
  final directory = BytesBuilder();
  final payloads = BytesBuilder();

  for (final entry in entries) {
    final size = entry.key;
    final png = entry.value;
    final row = ByteData(16)
      // 256 is written as 0; the field is one byte wide.
      ..setUint8(0, size >= 256 ? 0 : size)
      ..setUint8(1, size >= 256 ? 0 : size)
      ..setUint8(2, 0) // palette size: not paletted
      ..setUint8(3, 0) // reserved
      ..setUint16(4, 1, Endian.little) // colour planes
      ..setUint16(6, 32, Endian.little) // bits per pixel
      ..setUint32(8, png.length, Endian.little)
      ..setUint32(12, offset, Endian.little);
    directory.add(row.buffer.asUint8List());
    payloads.add(png);
    offset += png.length;
  }

  return Uint8List.fromList([
    ...header.buffer.asUint8List(),
    ...directory.takeBytes(),
    ...payloads.takeBytes(),
  ]);
}

/// Loads the real MaterialIcons font.
///
/// Widget tests otherwise render every glyph as a blank box from the
/// test font, which would silently produce icons that are a plain
/// coloured square - wrong in a way that looks deliberate.
Future<void> _loadMaterialIcons() async {
  // Walk up from whatever binary is running the test - `flutter test`
  // runs under flutter_tester, which lives at a different depth than the
  // Dart VM does - until the SDK's font cache turns up. Hardcoding a
  // relative depth breaks the moment the harness changes.
  File? font;
  for (var dir = File(Platform.resolvedExecutable).parent;
      dir.parent.path != dir.path;
      dir = dir.parent) {
    final candidate = File('${dir.path}/artifacts/material_fonts/MaterialIcons-Regular.otf');
    if (candidate.existsSync()) {
      font = candidate;
      break;
    }
  }

  if (font == null) {
    throw StateError(
      'MaterialIcons-Regular.otf not found above ${Platform.resolvedExecutable}. '
      'Without it every glyph renders as a blank box and the icons come out '
      'as plain coloured squares - wrong in a way that looks deliberate.',
    );
  }

  final bytes = font.readAsBytesSync();
  final loader = FontLoader('MaterialIcons')
    ..addFont(Future.value(ByteData.view(Uint8List.fromList(bytes).buffer)));
  await loader.load();
}

