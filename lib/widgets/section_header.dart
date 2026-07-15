import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/responsive.dart';

/// A consistent section heading: a small gold eyebrow, a large serif title,
/// and an optional supporting sentence. Centered or left-aligned.
class SectionHeader extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String? subtitle;
  final bool centered;
  final bool onDark;

  const SectionHeader({
    super.key,
    required this.eyebrow,
    required this.title,
    this.subtitle,
    this.centered = true,
    this.onDark = false,
  });

  @override
  Widget build(BuildContext context) {
    final align = centered ? CrossAxisAlignment.center : CrossAxisAlignment.start;
    final textAlign = centered ? TextAlign.center : TextAlign.start;
    final titleStyle = context
        .responsive(
          mobile: Theme.of(context).textTheme.displaySmall,
          desktop: Theme.of(context).textTheme.displayMedium,
        )!
        .copyWith(color: onDark ? AppColors.onDark : AppColors.navy);

    return Column(
      crossAxisAlignment: align,
      children: [
        Text(eyebrow.toUpperCase(), style: AppTheme.eyebrow()),
        const SizedBox(height: 16),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Text(title, textAlign: textAlign, style: titleStyle),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 20),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Text(
              subtitle!,
              textAlign: textAlign,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: onDark ? AppColors.onDarkSoft : AppColors.inkSoft,
                  ),
            ),
          ),
        ],
      ],
    );
  }
}
