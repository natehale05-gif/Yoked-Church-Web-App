import 'package:flutter/material.dart';

import '../config/site_config.dart';
import '../widgets/cards.dart';
import '../widgets/content_width.dart';
import '../widgets/page_hero.dart';
import '../widgets/responsive_grid.dart';

class SermonsPage extends StatelessWidget {
  const SermonsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const PageHero(
          eyebrow: 'Messages',
          title: 'Watch and listen anytime',
          subtitle:
              'Catch up on recent messages or explore a series. New messages '
              'are posted every week.',
        ),
        Section(
          child: ResponsiveGrid(
            desktopColumns: 2,
            tabletColumns: 2,
            runSpacing: 48,
            children: [for (final s in SiteConfig.sermons) SermonCard(s)],
          ),
        ),
      ],
    );
  }
}
