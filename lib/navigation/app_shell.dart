import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/church_config.dart';
import '../screens/about_screen.dart';
import '../screens/admin/admin_gate.dart';
import '../screens/contact_screen.dart';
import '../screens/events_screen.dart';
import '../screens/giving_screen.dart';
import '../screens/home_screen.dart';
import '../screens/ministries_screen.dart';
import '../screens/sermons_screen.dart';
import '../state/site_controller.dart';
import '../widgets/church_logo.dart';
import '../widgets/responsive.dart';
import 'nav_section.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  SectionId _selected = SectionId.home;
  final _scrollKey = GlobalKey();

  void _go(SectionId id) {
    setState(() => _selected = id);
  }

  void _openAdmin() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AdminGate()),
    );
  }

  Widget _screenFor(SectionId id) {
    switch (id) {
      case SectionId.home:
        return HomeScreen(onNavigate: _go);
      case SectionId.about:
        return const AboutScreen();
      case SectionId.sermons:
        return const SermonsScreen();
      case SectionId.events:
        return const EventsScreen();
      case SectionId.ministries:
        return const MinistriesScreen();
      case SectionId.giving:
        return const GivingScreen();
      case SectionId.contact:
        return const ContactScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = context.watch<SiteController>().config;
    final sections = visibleSections(config);

    // If a previously-selected section got disabled, fall back to Home.
    if (!sections.any((s) => s.id == _selected)) {
      _selected = SectionId.home;
    }

    final isDesktop = Responsive.isDesktop(context);

    return Scaffold(
      appBar: isDesktop
          ? _desktopAppBar(context, config, sections)
          : _mobileAppBar(context, config),
      drawer: isDesktop ? null : _drawer(context, config, sections),
      bottomNavigationBar:
          isDesktop ? null : _bottomNav(context, config, sections),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: KeyedSubtree(
          key: ValueKey(_selected),
          child: _screenFor(_selected),
        ),
      ),
    );
  }

  PreferredSizeWidget _desktopAppBar(
      BuildContext context, ChurchConfig config, List<NavSection> sections) {
    final theme = Theme.of(context);
    return AppBar(
      key: _scrollKey,
      titleSpacing: 24,
      title: Row(
        children: [
          InkWell(
            onTap: () => _go(SectionId.home),
            child: ChurchLogo(config: config, size: 40),
          ),
          const Spacer(),
          for (final s in sections)
            if (s.id != SectionId.giving)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: TextButton(
                  onPressed: () => _go(s.id),
                  style: TextButton.styleFrom(
                    foregroundColor: _selected == s.id
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface,
                    textStyle: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: _selected == s.id
                          ? FontWeight.w700
                          : FontWeight.w500,
                    ),
                  ),
                  child: Text(s.label),
                ),
              ),
          const SizedBox(width: 12),
          if (config.showGiving)
            FilledButton(
              onPressed: () => _go(SectionId.giving),
              child: const Text('Give'),
            ),
          IconButton(
            tooltip: 'Admin',
            onPressed: _openAdmin,
            icon: const Icon(Icons.admin_panel_settings_outlined),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _mobileAppBar(
      BuildContext context, ChurchConfig config) {
    return AppBar(
      title: InkWell(
        onTap: () => _go(SectionId.home),
        child: ChurchLogo(config: config, size: 34),
      ),
      actions: [
        IconButton(
          tooltip: 'Admin',
          onPressed: _openAdmin,
          icon: const Icon(Icons.admin_panel_settings_outlined),
        ),
      ],
    );
  }

  Widget _drawer(
      BuildContext context, ChurchConfig config, List<NavSection> sections) {
    final theme = Theme.of(context);
    return NavigationDrawer(
      selectedIndex: sections.indexWhere((s) => s.id == _selected),
      onDestinationSelected: (i) {
        Navigator.of(context).pop();
        _go(sections[i].id);
      },
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 32, 28, 16),
          child: ChurchLogo(config: config, size: 44),
        ),
        for (final s in sections)
          NavigationDrawerDestination(
            icon: Icon(s.icon),
            label: Text(s.label),
          ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 28),
          child: Divider(),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 8, 28, 8),
          child: OutlinedButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              _openAdmin();
            },
            icon: const Icon(Icons.admin_panel_settings_outlined),
            label: const Text('Admin / Customize'),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 8, 28, 24),
          child: Text('Powered by Yoked',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ),
      ],
    );
  }

  Widget _bottomNav(
      BuildContext context, ChurchConfig config, List<NavSection> sections) {
    // Bottom bar shows up to 5 primary sections.
    final bottom = sections.take(5).toList();
    final currentIndex = bottom.indexWhere((s) => s.id == _selected);
    return NavigationBar(
      selectedIndex: currentIndex < 0 ? 0 : currentIndex,
      onDestinationSelected: (i) => _go(bottom[i].id),
      destinations: [
        for (final s in bottom)
          NavigationDestination(icon: Icon(s.icon), label: s.label),
      ],
    );
  }
}
