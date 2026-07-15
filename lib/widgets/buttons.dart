import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Solid gold call-to-action button. High contrast and easy to tap.
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final IconData? icon;
  final bool onDark;

  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.onDark = false,
  });

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.gold,
        foregroundColor: AppColors.navyDeep,
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
        textStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
        ),
      ),
      child: _Content(label: label, icon: icon),
    );
  }
}

/// Outlined secondary button. Adapts to light or dark backgrounds.
class SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final IconData? icon;
  final bool onDark;

  const SecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.onDark = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = onDark ? AppColors.onDark : AppColors.navy;
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(
          color: onDark
              ? AppColors.onDark.withValues(alpha: 0.5)
              : AppColors.navy.withValues(alpha: 0.35),
          width: 1.4,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
        textStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
        ),
      ),
      child: _Content(label: label, icon: icon),
    );
  }
}

class _Content extends StatelessWidget {
  final String label;
  final IconData? icon;
  const _Content({required this.label, this.icon});

  @override
  Widget build(BuildContext context) {
    if (icon == null) return Text(label);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label),
        const SizedBox(width: 10),
        Icon(icon, size: 18),
      ],
    );
  }
}
