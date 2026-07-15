import 'package:flutter/material.dart';

import '../config/site_config.dart';
import '../widgets/cards.dart';
import '../widgets/content_width.dart';
import '../widgets/page_hero.dart';
import '../widgets/responsive_grid.dart';

class EventsPage extends StatelessWidget {
  const EventsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const PageHero(
          eyebrow: 'Events',
          title: 'Something for everyone',
          subtitle:
              'From weekly gatherings to special events, there are lots of ways '
              'to connect. We would love to see you there.',
        ),
        Section(
          child: ResponsiveGrid(
            desktopColumns: 2,
            tabletColumns: 2,
            runSpacing: 28,
            children: [for (final e in SiteConfig.events) EventCard(e)],
          ),
        ),
      ],
    );
  }
}
