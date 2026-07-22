import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../config/church_config.dart';
import '../theme/app_theme.dart';

class _AdminNavItem {
  final String label;
  final String path;

  const _AdminNavItem(this.label, this.path);
}

const List<_AdminNavItem> _items = [
  _AdminNavItem('Overview', '/admin'),
  _AdminNavItem('Sermons', '/admin/sermons'),
  _AdminNavItem('Events', '/admin/events'),
  _AdminNavItem('Connect Inbox', '/admin/connect'),
  _AdminNavItem('Groups', '/admin/groups'),
];

/// Page header + secondary nav shared by every `/admin/*` screen -
/// mirrors [AccountHeader], with a darker accent so staff always know
/// they're in the management area, not the public/member site.
class AdminHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const AdminHeader({super.key, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final isMobile = Breakpoints.isMobile(context);
    final currentPath = GoRouterState.of(context).uri.toString();

    return Container(
      width: double.infinity,
      color: Colors.black87,
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 24 : 60, vertical: isMobile ? 40 : 56),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.admin_panel_settings_outlined, color: Colors.white70, size: 20),
              const SizedBox(width: 8),
              Text('STAFF DASHBOARD', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1)),
            ],
          ),
          const SizedBox(height: 8),
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
                      backgroundColor: selected ? ChurchConfig.accentColor.withValues(alpha: 0.25) : null,
                      foregroundColor: selected ? ChurchConfig.accentColor : Colors.white70,
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
