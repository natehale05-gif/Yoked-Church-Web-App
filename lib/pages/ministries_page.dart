import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../state/site_content_controller.dart';
import '../theme/app_colors.dart';
import '../theme/responsive.dart';
import '../widgets/buttons.dart';
import '../widgets/cards.dart';
import '../widgets/content_width.dart';
import '../widgets/page_hero.dart';
import '../widgets/responsive_grid.dart';

class MinistriesPage extends StatelessWidget {
  const MinistriesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final content = context.watch<SiteContentController>().content;
    return Column(
      children: [
        const PageHero(
          eyebrow: 'Ministries',
          title: 'Find your people',
          subtitle:
              'Whatever your age or stage, there is a community here ready to '
              'welcome you and help you grow.',
        ),
        Section(
          child: ResponsiveGrid(
            children: [for (final m in content.ministries) MinistryCard(m)],
          ),
        ),
        const _GetConnectedCta(),
      ],
    );
  }
}

class _GetConnectedCta extends StatelessWidget {
  const _GetConnectedCta();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.navy,
      padding: EdgeInsets.symmetric(
        vertical: context.responsive(mobile: 56, desktop: 96),
      ),
      child: ContentWidth(
        child: Column(
          children: [
            Text(
              'Not sure where to start?',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .displaySmall
                  ?.copyWith(color: AppColors.onDark),
            ),
            const SizedBox(height: 18),
            Text(
              'Reach out and we will help you find the right next step.',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(color: AppColors.onDarkSoft),
            ),
            const SizedBox(height: 32),
            PrimaryButton(
              label: 'Get Connected',
              icon: Icons.arrow_forward,
              onPressed: () => context.go('/contact'),
            ),
          ],
        ),
      ),
    );
  }
}
