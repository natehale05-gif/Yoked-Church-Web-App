import 'package:flutter/material.dart';

/// Helpers to (de)serialize [Color] values as hex strings so the whole
/// church configuration can be stored/shipped as JSON.
class ColorUtils {
  const ColorUtils._();

  static String toHex(Color color) {
    final argb = color.value;
    return '#${argb.toRadixString(16).padLeft(8, '0').toUpperCase()}';
  }

  static Color fromHex(String? hex, {Color fallback = const Color(0xFF3D5AFE)}) {
    if (hex == null || hex.trim().isEmpty) return fallback;
    var value = hex.trim().replaceAll('#', '').toUpperCase();
    if (value.length == 6) value = 'FF$value';
    final parsed = int.tryParse(value, radix: 16);
    if (parsed == null) return fallback;
    return Color(parsed);
  }

  /// Returns black or white depending on which contrasts best with [color].
  static Color onColor(Color color) {
    return color.computeLuminance() > 0.5 ? Colors.black : Colors.white;
  }
}
