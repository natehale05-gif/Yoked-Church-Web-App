import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/site_content_controller.dart';
import '../theme/app_colors.dart';
import '../theme/responsive.dart';
import '../utils/launch.dart';
import '../widgets/buttons.dart';
import '../widgets/cards.dart';
import '../widgets/content_width.dart';
import '../widgets/page_hero.dart';
import '../widgets/responsive_grid.dart';
import '../widgets/section_header.dart';

class GivePage extends StatelessWidget {
  const GivePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        PageHero(
          eyebrow: 'Give',
          title: 'Generosity changes lives',
          subtitle:
              'Your giving fuels everything we do — from Sunday gatherings to '
              'caring for our city. Thank you for your generosity.',
        ),
        _GiveWays(),
        _WhereItGoes(),
      ],
    );
  }
}

class _GiveWays extends StatelessWidget {
  const _GiveWays();

  @override
  Widget build(BuildContext context) {
    final content = context.watch<SiteContentController>().content;
    return Section(
      child: Column(
        children: [
          const SectionHeader(
            eyebrow: 'Ways to Give',
            title: 'Simple, secure, and quick',
            subtitle: 'Choose whatever is easiest for you.',
          ),
          const SizedBox(height: 44),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: SurfaceCard(
                padding: const EdgeInsets.all(36),
                child: Column(
                  children: [
                    const Icon(Icons.favorite,
                        color: AppColors.gold, size: 44),
                    const SizedBox(height: 20),
                    Text(
                      'Give Online',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'The fastest and most secure way to give. Make a '
                      'one-time gift or set up recurring giving in minutes.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 24),
                    PrimaryButton(
                      label: 'Give Now',
                      icon: Icons.arrow_forward,
                      onPressed: () => openUrl(content.giveUrl),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 40),
          ResponsiveGrid(
            desktopColumns: 2,
            tabletColumns: 2,
            children: [
              _GiveMethod(
                icon: Icons.mail_outline,
                title: 'By Mail',
                body:
                    'Send a check to our office at '
                    '${content.addressLine1}, ${content.addressLine2}.',
              ),
              const _GiveMethod(
                icon: Icons.volunteer_activism_outlined,
                title: 'In Person',
                body:
                    'Drop your gift in the box at any Sunday gathering. '
                    'Every gift makes a difference.',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GiveMethod extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  const _GiveMethod({
    required this.icon,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.navy, size: 30),
          const SizedBox(height: 18),
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 10),
          Text(body, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _WhereItGoes extends StatelessWidget {
  const _WhereItGoes();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.cream,
      padding: EdgeInsets.symmetric(
        vertical: context.responsive(mobile: 56, desktop: 96),
      ),
      child: ContentWidth(
        child: Column(
          children: [
            const SectionHeader(
              eyebrow: 'Your Impact',
              title: 'Where your giving goes',
              subtitle:
                  'We are committed to stewarding every gift with integrity and '
                  'transparency.',
            ),
          ],
        ),
      ),
    );
  }
}
