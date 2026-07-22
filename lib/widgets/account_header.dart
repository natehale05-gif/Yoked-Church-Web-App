import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../config/church_config.dart';
import '../theme/app_theme.dart';

class _AccountNavItem {
  final String label;
  final String path;

  const _AccountNavItem(this.label, this.path);
}

const List<_AccountNavItem> _items = [
  _AccountNavItem('Overview', '/account'),
  _AccountNavItem('Profile', '/account/profile'),
  _AccountNavItem('Groups', '/account/groups'),
  _AccountNavItem('My Events', '/account/events'),
  _AccountNavItem('Directory', '/account/directory'),
  _AccountNavItem('Giving', '/account/giving'),
];

/// Page header + secondary nav shared by every `/account/*` screen -
/// mirrors the colored header pattern already used on the public
/// Sermons/Events/Give/Connect screens.
class AccountHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const AccountHeader({super.key, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final isMobile = Breakpoints.isMobile(context);
    final currentPath = GoRouterState.of(context).uri.toString();

    return Container(
      width: double.infinity,
      color: ChurchConfig.primaryColor,
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 24 : 60, vertical: isMobile ? 40 : 56),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.displayMedium?.copyWith(color: Colors.white)),
          const SizedBox(height: 8),
          Text(subtitle, style: const TextStyle(color: Colors.white70, fontSize: 16)),
          const SizedBox(height: 24),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _items.map((item) {
                final selected = currentPath == item.path;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: TextButton(
                    onPressed: () => context.go(item.path),
                    style: TextButton.styleFrom(
                      backgroundColor: selected ? Colors.white.withValues(alpha: 0.15) : null,
                      foregroundColor: selected ? Colors.white : Colors.white70,
                    ),
                    child: Text(item.label, style: TextStyle(fontWeight: selected ? FontWeight.w700 : FontWeight.w500)),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
