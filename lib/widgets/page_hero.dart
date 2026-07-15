import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/responsive.dart';
import 'content_width.dart';

/// A compact dark header used at the top of interior pages. Provides the dark
/// backdrop the nav expects, plus a clear page title and intro.
class PageHero extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String subtitle;

  const PageHero({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.navyDeep, AppColors.navy],
        ),
      ),
      padding: EdgeInsets.only(
        top: context.responsive(mobile: 128, desktop: 168),
        bottom: context.responsive(mobile: 56, desktop: 84),
      ),
      child: ContentWidth(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(eyebrow.toUpperCase(), style: AppTheme.eyebrow()),
            const SizedBox(height: 18),
            Text(
              title,
              style: context
                  .responsive(
                    mobile: Theme.of(context).textTheme.displaySmall,
                    desktop: Theme.of(context).textTheme.displayLarge,
                  )!
                  .copyWith(color: AppColors.onDark),
            ),
            const SizedBox(height: 22),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Text(
                subtitle,
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(color: AppColors.onDarkSoft),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
