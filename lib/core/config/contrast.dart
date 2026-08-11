import 'dart:math' as math;

import 'package:flutter/material.dart';

/// The ratio WCAG AA asks of normal-sized text against its background.
///
/// Large text is allowed 3:1, but almost nothing here qualifies - the
/// accent is used at 12px bold for the eyebrow labels, and a button
/// label is 14px. Holding everything to the stricter number is simpler
/// than auditing font sizes, and nothing in this palette needs the
/// slack.
const double readableContrast = 4.5;

/// Relative luminance, per the WCAG definition.
double _luminance(Color colour) {
  double channel(double v) => v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * channel(colour.r) + 0.7152 * channel(colour.g) + 0.0722 * channel(colour.b);
}

/// How well two colours separate, from 1 (identical) to 21 (black on
/// white).
///
/// Symmetric, like the specification: it does not matter which is the
/// text and which is behind it.
double contrastRatio(Color a, Color b) {
  final la = _luminance(a);
  final lb = _luminance(b);
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

/// Black or white - whichever can actually be read on [background].
///
/// The app used to assume white, which is why every button in every one
/// of the six bundled themes failed: the accents are mid-tone golds,
/// terracottas and teals, and white on those scores 2.4 to 3.9 against
/// the 4.5 needed. Black on the same colours scores 5.3 to 8.8, so the
/// palettes were never the problem - the assumption was.
Color readableOn(Color background) {
  return contrastRatio(Colors.black, background) >= contrastRatio(Colors.white, background)
      ? Colors.black
      : Colors.white;
}

/// [colour], darkened only as far as it must be to be legible on [on].
///
/// For the places where the accent *is* the text - the small bold
/// "SERMON" and "THIS SUNDAY" labels - so picking a foreground is not an
/// option. Substituting the primary colour instead would work and would
/// also delete the accent from the page, which is most of what a church
/// changed when it picked its colours.
///
/// Returns [colour] untouched when it already reads, so a church whose
/// accent is genuinely dark keeps exactly what it chose.
Color readableInk(Color colour, {required Color on}) {
  if (contrastRatio(colour, on) >= readableContrast) return colour;

  final hsl = HSLColor.fromColor(colour);
  // Down in small steps rather than solving for it: lightness and
  // luminance are not the same curve, and stepping lands on the first
  // shade that works instead of overshooting into near-black.
  for (var lightness = hsl.lightness - 0.02; lightness >= 0; lightness -= 0.02) {
    final candidate = hsl.withLightness(lightness).toColor();
    if (contrastRatio(candidate, on) >= readableContrast) return candidate;
  }
  // Nothing in this hue reads on that background; black always will.
  return Colors.black;
}
