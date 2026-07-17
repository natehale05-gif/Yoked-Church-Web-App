import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../config/church_config.dart';
import '../theme/app_theme.dart';

class NavItem {
  final String label;
  final String path;

  const NavItem(this.label, this.path);
}

const List<NavItem> _navItems = [
  NavItem('Home', '/'),
  NavItem('Sermons', '/sermons'),
  NavItem('Events', '/events'),
  NavItem('Connect', '/connect'),
];

class AppNavBar extends StatelessWidget implements PreferredSizeWidget {
  const AppNavBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(76);

  @override
  Widget build(BuildContext context) {
    final currentPath = GoRouterState.of(context).uri.toString();
    // Use the hamburger menu below desktop width so the full link row
    // never has to squeeze into a narrow (e.g. tablet) viewport.
    final isMobile = !Breakpoints.isDesktop(context);

    return AppBar(
      toolbarHeight: preferredSize.height,
      titleSpacing: 0,
      title: Padding(
        padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 40),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => context.go('/'),
              child: Row(
                children: [
                  Icon(Icons.church, color: ChurchConfig.primaryColor, size: 28),
                  const SizedBox(width: 10),
                  Text(
                    ChurchConfig.churchName,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: ChurchConfig.primaryColor,
                        ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            if (!isMobile) ..._buildDesktopLinks(context, currentPath),
            if (!isMobile && ChurchConfig.showGiving) ...[
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: () => context.go('/give'),
                child: const Text('Give'),
              ),
            ],
            if (isMobile)
              Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: () => _openMobileMenu(context),
                ),
              ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildDesktopLinks(BuildContext context, String currentPath) {
    return _navItems.map((item) {
      final selected = currentPath == item.path;
      return TextButton(
        onPressed: () => context.go(item.path),
        style: TextButton.styleFrom(
          foregroundColor: selected ? ChurchConfig.accentColor : ChurchConfig.primaryColor,
        ),
        child: Text(
          item.label,
          style: TextStyle(fontWeight: selected ? FontWeight.w700 : FontWeight.w500),
        ),
      );
    }).toList();
  }

  void _openMobileMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ..._navItems.map(
              (item) => ListTile(
                title: Text(item.label),
                onTap: () {
                  Navigator.pop(sheetContext);
                  context.go(item.path);
                },
              ),
            ),
            if (ChurchConfig.showGiving)
              ListTile(
                title: const Text('Give', style: TextStyle(fontWeight: FontWeight.w700)),
                leading: Icon(Icons.favorite, color: ChurchConfig.accentColor),
                onTap: () {
                  Navigator.pop(sheetContext);
                  context.go('/give');
                },
              ),
          ],
        ),
      ),
    );
  }
}
