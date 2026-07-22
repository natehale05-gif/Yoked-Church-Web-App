import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../config/church_config.dart';
import '../providers/auth_provider.dart';
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
    final auth = ChurchConfig.useFirebase ? context.watch<AuthProvider>() : null;

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
            if (!isMobile && auth != null) ...[
              const SizedBox(width: 8),
              _AccountControl(auth: auth),
            ],
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
                  onPressed: () => _openMobileMenu(context, auth),
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

  void _openMobileMenu(BuildContext context, AuthProvider? auth) {
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
            if (auth != null && auth.isSignedIn) ...[
              ListTile(
                leading: const Icon(Icons.person_outline),
                title: const Text('My Account'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  context.go('/account');
                },
              ),
              if (auth.currentUser?.isStaff == true)
                ListTile(
                  leading: const Icon(Icons.admin_panel_settings_outlined),
                  title: const Text('Staff Dashboard'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    context.go('/admin');
                  },
                ),
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Sign Out'),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  await auth.signOut();
                  if (context.mounted) context.go('/');
                },
              ),
            ] else if (auth != null) ...[
              ListTile(
                leading: const Icon(Icons.login),
                title: const Text('Sign In'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  context.go('/sign-in');
                },
              ),
            ],
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

class _AccountControl extends StatelessWidget {
  final AuthProvider auth;

  const _AccountControl({required this.auth});

  @override
  Widget build(BuildContext context) {
    if (!auth.isSignedIn) {
      return TextButton(
        onPressed: () => context.go('/sign-in'),
        style: TextButton.styleFrom(foregroundColor: ChurchConfig.primaryColor),
        child: const Text('Sign In', style: TextStyle(fontWeight: FontWeight.w500)),
      );
    }

    final name = auth.currentUser?.displayName ?? '';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    final isStaff = auth.currentUser?.isStaff == true;

    return PopupMenuButton<String>(
      tooltip: 'Account',
      offset: const Offset(0, 44),
      itemBuilder: (context) => [
        const PopupMenuItem(value: 'account', child: Text('My Account')),
        if (isStaff) const PopupMenuItem(value: 'admin', child: Text('Staff Dashboard')),
        const PopupMenuItem(value: 'sign-out', child: Text('Sign Out')),
      ],
      onSelected: (value) async {
        if (value == 'account') {
          context.go('/account');
        } else if (value == 'admin') {
          context.go('/admin');
        } else if (value == 'sign-out') {
          await auth.signOut();
          if (context.mounted) context.go('/');
        }
      },
      child: CircleAvatar(
        radius: 18,
        backgroundColor: ChurchConfig.primaryColor.withValues(alpha: 0.12),
        child: Text(initial, style: TextStyle(color: ChurchConfig.primaryColor, fontWeight: FontWeight.w700)),
      ),
    );
  }
}
