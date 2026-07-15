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
import '../widgets/photo_frame.dart';
import '../widgets/responsive_grid.dart';
import '../widgets/section_header.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        PageHero(
          eyebrow: 'About Us',
          title: 'Our story and our people',
          subtitle:
              'We exist to help people find and follow Jesus, and to love our '
              'city with the same grace we have received.',
        ),
        _StorySection(),
        _ValuesSection(),
        _LeadershipSection(),
        _JoinCta(),
      ],
    );
  }
}

class _StorySection extends StatelessWidget {
  const _StorySection();

  @override
  Widget build(BuildContext context) {
    final isDesktop = context.isDesktop;
    return Section(
      child: Flex(
        direction: isDesktop ? Axis.horizontal : Axis.vertical,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: isDesktop ? 6 : 0,
            child: const PhotoFrame(
              aspectRatio: 4 / 3,
              placeholderIcon: Icons.groups_2_outlined,
              placeholderLabel: 'Photo of your\ncongregation gathered',
            ),
          ),
          SizedBox(width: isDesktop ? 64 : 0, height: isDesktop ? 0 : 40),
          Expanded(
            flex: isDesktop ? 6 : 0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeader(
                  eyebrow: 'Our Story',
                  title: 'Rooted in the city, growing in grace',
                  centered: false,
                ),
                const SizedBox(height: 22),
                Text(
                  'What began as a handful of families praying in a living room '
                  'has grown into a vibrant community from every background and '
                  'season of life. Through the years one thing has stayed the '
                  'same: a desire to know God and make Him known.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 16),
                Text(
                  'Today we gather each week to worship, learn, and serve — and '
                  'we would love for you to be a part of the next chapter.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ValuesSection extends StatelessWidget {
  const _ValuesSection();

  @override
  Widget build(BuildContext context) {
    final content = context.watch<SiteContentController>().content;
    return Section(
      background: AppColors.cream,
      child: Column(
        children: [
          const SectionHeader(
            eyebrow: 'What We Value',
            title: 'The convictions that guide us',
          ),
          const SizedBox(height: 56),
          ResponsiveGrid(
            desktopColumns: 4,
            tabletColumns: 2,
            children: [for (final v in content.values) ValueCard(v)],
          ),
        ],
      ),
    );
  }
}

class _LeadershipSection extends StatelessWidget {
  const _LeadershipSection();

  @override
  Widget build(BuildContext context) {
    final content = context.watch<SiteContentController>().content;
    return Section(
      child: Column(
        children: [
          const SectionHeader(
            eyebrow: 'Our Team',
            title: 'Meet the people who serve you',
            subtitle:
                'A team of pastors and leaders dedicated to caring for our '
                'church family and community.',
          ),
          const SizedBox(height: 56),
          ResponsiveGrid(
            desktopColumns: 4,
            tabletColumns: 2,
            children: [for (final p in content.leaders) PersonCard(p)],
          ),
        ],
      ),
    );
  }
}

class _JoinCta extends StatelessWidget {
  const _JoinCta();

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
              'Come be part of the family',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .displaySmall
                  ?.copyWith(color: AppColors.onDark),
            ),
            const SizedBox(height: 32),
            PrimaryButton(
              label: 'Plan Your Visit',
              icon: Icons.arrow_forward,
              onPressed: () => context.go('/visit'),
            ),
          ],
        ),
      ),
    );
  }
}
