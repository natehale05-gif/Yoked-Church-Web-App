import 'package:flutter/material.dart';

import '../../utils/color_utils.dart';

/// A titled card used to group related settings in the admin panel.
class AdminSection extends StatelessWidget {
  final String title;
  final String? description;
  final List<Widget> children;

  const AdminSection({
    super.key,
    required this.title,
    this.description,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700)),
            if (description != null) ...[
              const SizedBox(height: 4),
              Text(description!,
                  style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant)),
            ],
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
}

class AdminField extends StatelessWidget {
  final String label;
  final String value;
  final ValueChanged<String> onChanged;
  final int maxLines;
  final String? hint;
  final TextInputType? keyboardType;

  const AdminField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.maxLines = 1,
    this.hint,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        initialValue: value,
        onChanged: onChanged,
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          alignLabelWithHint: maxLines > 1,
        ),
      ),
    );
  }
}

/// Hex color field with a live swatch and a quick preset palette.
class AdminColorField extends StatelessWidget {
  final String label;
  final String hex;
  final ValueChanged<String> onChanged;

  const AdminColorField({
    super.key,
    required this.label,
    required this.hex,
    required this.onChanged,
  });

  static const _presets = [
    '#FF6C5CE7',
    '#FF3D5AFE',
    '#FF00BFA5',
    '#FF00CEC9',
    '#FFE84393',
    '#FFEB5757',
    '#FFF2994A',
    '#FFFDCB6E',
    '#FF27AE60',
    '#FF2D3436',
    '#FF0984E3',
    '#FF6D4C41',
  ];

  @override
  Widget build(BuildContext context) {
    final color = ColorUtils.fromHex(hex);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: Theme.of(context).colorScheme.outlineVariant),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  initialValue: hex,
                  onChanged: onChanged,
                  decoration: InputDecoration(
                    labelText: label,
                    hintText: '#AARRGGBB',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final p in _presets)
                InkWell(
                  onTap: () => onChanged(p),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: ColorUtils.fromHex(p),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: hex.toUpperCase() == p
                            ? Theme.of(context).colorScheme.onSurface
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class AdminSwitch extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const AdminSwitch({
    super.key,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle!) : null,
      value: value,
      onChanged: onChanged,
    );
  }
}
