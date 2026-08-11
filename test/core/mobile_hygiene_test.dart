import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Rules about the source that a widget test cannot practically reach.
///
/// `responsive_test.dart` walks every route at every size and catches
/// what actually overflows *with the data it seeds*. That is the real
/// check, and it is why this file is short - but it can only see a
/// dropdown break if some seeded room happens to have a long enough
/// name. A rule that holds for every dropdown, seeded or not, belongs
/// here instead.
void main() {
  final dartFiles = Directory('lib')
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .toList();

  test('every dropdown fills the width it is given', () {
    // `DropdownButtonFormField` sizes itself to its widest *item* unless
    // told otherwise, and ignores the space it actually has. Inside a
    // form on a 320px phone that means one long option - a room called
    // "Upper Fellowship Hall", a group called "Tuesday Morning Women" -
    // pushes the whole field off the side of the screen.
    //
    // Thirteen of the fifteen in this app were built without it. Two of
    // those were caught by the route sweep, because those two happened
    // to be seeded with long enough test data; the other eleven were
    // exactly as broken and entirely invisible.
    final offenders = <String>[];

    for (final file in dartFiles) {
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        if (!RegExp(r'DropdownButtonFormField<').hasMatch(lines[i])) continue;

        // The argument list, to the first line that closes it at the
        // same indent as the constructor.
        final indent = RegExp(r'^\s*').firstMatch(lines[i])!.group(0)!;
        final body = <String>[];
        for (var j = i + 1; j < lines.length; j++) {
          if (lines[j].startsWith('$indent)')) break;
          body.add(lines[j]);
        }

        if (!body.any((l) => l.contains('isExpanded'))) {
          offenders.add('${file.path}:${i + 1}');
        }
      }
    }

    expect(
      offenders,
      isEmpty,
      reason: 'these dropdowns will overflow a narrow phone; add `isExpanded: true`:\n'
          '  ${offenders.join('\n  ')}',
    );
  });

  test('the custom bootstrap still does the two jobs it exists for', () {
    // A hand-written `web/flutter_bootstrap.js` opts out of whatever the
    // generated one does, silently, so what it must keep is worth
    // pinning. Both tokens are substituted at build time and the file is
    // dead without them.
    //
    // Not pinned: the service worker. Passing `serviceWorkerSettings`
    // looks like it would restore caching and does nothing on this
    // Flutter - the loader only refreshes an existing registration and
    // creates none, generated bootstrap or not. Tested both ways; see
    // the note at the top of the file.
    final bootstrap = File('web/flutter_bootstrap.js').readAsStringSync();

    expect(bootstrap, contains(r'{{flutter_js}}'));
    expect(bootstrap, contains(r'{{flutter_build_config}}'));
    expect(
      bootstrap,
      contains("getElementById('loading')"),
      reason: 'nothing else takes the loading screen down, and it covers the whole app',
    );
  });
}
