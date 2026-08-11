import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yoked_church_app/core/config/church_settings.dart';
import 'package:yoked_church_app/core/config/contrast.dart';
import 'package:yoked_church_app/core/config/themes.dart';

/// The check that was missing, and whose absence is why all six bundled
/// palettes shipped with an unreadable primary button.
///
/// Nothing about this needed a browser or a screenshot to find - it is
/// arithmetic on colours that have been in the repo the whole time. It
/// went unnoticed because nobody ever did the arithmetic.
void main() {
  group('the ratio itself', () {
    test('agrees with the values everybody knows', () {
      // If the helper is wrong, every assertion built on it is
      // decoration. These three are the fixed points of the scale.
      expect(contrastRatio(Colors.black, Colors.white), closeTo(21, 0.01));
      expect(contrastRatio(Colors.white, Colors.white), closeTo(1, 0.001));
      expect(contrastRatio(Colors.black, Colors.black), closeTo(1, 0.001));
    });

    test('does not care which colour is the text', () {
      const gold = Color(0xFFC9A24B);
      expect(
        contrastRatio(gold, Colors.white),
        closeTo(contrastRatio(Colors.white, gold), 0.0001),
      );
    });
  });

  group('picking a foreground', () {
    test('takes black on a mid-tone the app actually ships', () {
      // The default accent. White on it is 2.4:1 - which is what every
      // button in the app used to be.
      const gold = Color(0xFFC9A24B);
      expect(contrastRatio(Colors.white, gold), lessThan(readableContrast));
      expect(readableOn(gold), Colors.black);
    });

    test('and white on something dark', () {
      expect(readableOn(const Color(0xFF1B3A4B)), Colors.white);
    });
  });

  group('darkening a colour until it reads', () {
    const pale = Color(0xFFF7F5F0);

    test('leaves a colour that already reads exactly alone', () {
      const navy = Color(0xFF1B3A4B);
      expect(readableInk(navy, on: pale), navy);
    });

    test('keeps the hue it was given', () {
      // The point of darkening rather than substituting the primary
      // colour: a church picked its accent, and the page should still
      // have it on it.
      const gold = Color(0xFFC9A24B);
      final ink = readableInk(gold, on: pale);

      expect(ink, isNot(gold));
      expect(
        HSLColor.fromColor(ink).hue,
        closeTo(HSLColor.fromColor(gold).hue, 1.0),
        reason: 'darkened, not replaced',
      );
      expect(contrastRatio(ink, pale), greaterThanOrEqualTo(readableContrast));
    });

    test('does not overshoot into near-black', () {
      // Stepping down finds the first shade that works. Solving for it
      // in one jump used to land far darker than needed, which reads as
      // "the accent stopped existing".
      final ink = readableInk(const Color(0xFFC9A24B), on: pale);
      expect(HSLColor.fromColor(ink).lightness, greaterThan(0.15));
    });
  });

  /// The three pairs the app paints, for every palette a church can pick
  /// with one tap - plus the fallback, which is what a church gets
  /// before it picks anything at all.
  group('every palette a church can choose', () {
    final palettes = <String, BrandColors>{
      for (final theme in churchThemes) theme.name: theme.colors,
      'the fallback': BrandColors.fallback,
    };

    for (final entry in palettes.entries) {
      final name = entry.key;
      final colours = entry.value;

      test('$name: a button label can be read', () {
        // Give, Plan a Visit, Sign In, Save Settings, Release at the
        // kids desk - 45 of them, all this one pair.
        final foreground = readableOn(colours.accent);
        expect(
          contrastRatio(foreground, colours.accent),
          greaterThanOrEqualTo(readableContrast),
          reason: '$name buttons are unreadable',
        );
      });

      test('$name: the accent works as small text', () {
        expect(
          contrastRatio(colours.accentInk, colours.background),
          greaterThanOrEqualTo(readableContrast),
          reason: '$name eyebrow labels are unreadable',
        );
      });

      test('$name: headings can be read on the background', () {
        expect(
          contrastRatio(colours.primary, colours.background),
          greaterThanOrEqualTo(readableContrast),
          reason: '$name headings are unreadable',
        );
      });
    }

    test('the raw accent really was the problem, and is still the fill', () {
      // Guards the fix rather than the symptom: if somebody "simplifies"
      // accentInk back to accent, the tests above would still pass only
      // if the palettes had changed - which they have not.
      final failing = churchThemes
          .where((t) => contrastRatio(t.colors.accent, t.colors.background) < readableContrast)
          .map((t) => t.name)
          .toList();

      expect(
        failing,
        isNotEmpty,
        reason: 'the accents were mid-tone by design; if that changed, this note is stale',
      );
    });
  });
}
