import 'package:flutter/material.dart';

import '../models/church_config.dart';
import '../utils/color_utils.dart';

/// The church "logo": either a supplied image, or a rounded monogram built from
/// the configured initials / church name.
class ChurchLogo extends StatelessWidget {
  final ChurchConfig config;
  final double size;
  final bool showName;

  const ChurchLogo({
    super.key,
    required this.config,
    this.size = 40,
    this.showName = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = ColorUtils.fromHex(config.primaryColorHex);
    final secondary = ColorUtils.fromHex(config.secondaryColorHex);

    final initials = config.logoInitials.trim().isNotEmpty
        ? config.logoInitials.trim()
        : _initialsFromName(config.churchName);

    final Widget mark = config.logoImageUrl.trim().isNotEmpty
        ? ClipOval(
            child: Image.network(
              config.logoImageUrl.trim(),
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _monogram(initials, primary,
                  secondary, size),
            ),
          )
        : _monogram(initials, primary, secondary, size);

    if (!showName) return mark;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        mark,
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            config.churchName,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _monogram(String initials, Color a, Color b, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [a, b],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TextStyle(
          color: ColorUtils.onColor(a),
          fontWeight: FontWeight.w800,
          fontSize: size * 0.4,
          letterSpacing: -0.5,
        ),
      ),
    );
  }

  static String _initialsFromName(String name) {
    final parts =
        name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return (parts.first.substring(0, 1) + parts[1].substring(0, 1))
        .toUpperCase();
  }
}
