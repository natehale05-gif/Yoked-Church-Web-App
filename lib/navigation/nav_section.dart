import 'package:flutter/material.dart';

import '../models/church_config.dart';

enum SectionId { home, about, sermons, events, ministries, giving, contact }

class NavSection {
  final SectionId id;
  final String label;
  final IconData icon;

  const NavSection(this.id, this.label, this.icon);
}

/// Builds the ordered list of nav sections the church has enabled.
List<NavSection> visibleSections(ChurchConfig config) {
  return [
    const NavSection(SectionId.home, 'Home', Icons.home_outlined),
    if (config.showAbout)
      const NavSection(SectionId.about, 'About', Icons.info_outline),
    if (config.showSermons)
      const NavSection(SectionId.sermons, 'Messages', Icons.play_circle_outline),
    if (config.showEvents)
      const NavSection(SectionId.events, 'Events', Icons.event_outlined),
    if (config.showMinistries)
      const NavSection(
          SectionId.ministries, 'Ministries', Icons.diversity_3_outlined),
    if (config.showGiving)
      const NavSection(SectionId.giving, 'Give', Icons.favorite_outline),
    if (config.showContact)
      const NavSection(SectionId.contact, 'Contact', Icons.place_outlined),
  ];
}
