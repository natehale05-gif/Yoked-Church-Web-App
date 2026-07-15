import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../models/app_user.dart';
import '../state/auth_controller.dart';
import '../state/site_content_controller.dart';
import '../theme/app_colors.dart';
import '../theme/responsive.dart';

class _NavEntry {
  final String label;
  final IconData icon;
  final String path;
  const _NavEntry(this.label, this.icon, this.path);
}

const _staffNav = [
  _NavEntry('Dashboard', Icons.dashboard_outlined, '/app/dashboard'),
  _NavEntry('Site Editor', Icons.edit_note_outlined, '/app/editor'),
  _NavEntry('Members', Icons.people_alt_outlined, '/app/members'),
  _NavEntry('Attendance', Icons.fact_check_outlined, '/app/attendance'),
  _NavEntry('Serving', Icons.volunteer_activism_outlined, '/app/serving'),
];

const _memberNav = [
  _NavEntry('My Home', Icons.home_outlined, '/app/me'),
  _NavEntry('Serve', Icons.volunteer_activism_outlined, '/app/serve'),
];

/// Layout for the authenticated admin / member area: a sidebar on desktop and
/// a drawer on smaller screens, wrapping the routed page content.
class AppShell extends StatelessWidget {
  final Widget child;
  final String location;
  const AppShell({super.key, required this.child, required this.location});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final entries = auth.isStaff ? _staffNav : _memberNav;
    final wide = context.screenWidth >= 900;

    if (wide) {
      return Scaffold(
        backgroundColor: AppColors.ivory,
        body: Row(
          children: [
            _Sidebar(entries: entries, location: location),
            Expanded(
              child: _ContentArea(child: child),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.ivory,
      appBar: AppBar(
        backgroundColor: AppColors.navyDeep,
        foregroundColor: AppColors.onDark,
        title: Text(
          context.watch<SiteContentController>().content.churchName,
          style: GoogleFonts.cormorantGaramond(
            fontWeight: FontWeight.w700,
            fontSize: 22,
            color: AppColors.onDark,
          ),
        ),
      ),
      drawer: Drawer(
        child: _Sidebar(entries: entries, location: location, inDrawer: true),
      ),
      body: _ContentArea(child: child),
    );
  }
}

class _ContentArea extends StatelessWidget {
  final Widget child;
  const _ContentArea({required this.child});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: context.responsive(mobile: 18, tablet: 28, desktop: 44),
          vertical: context.responsive(mobile: 24, desktop: 40),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1080),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _Sidebar extends StatelessWidget {
  final List<_NavEntry> entries;
  final String location;
  final bool inDrawer;
  const _Sidebar({
    required this.entries,
    required this.location,
    this.inDrawer = false,
  });

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final content = context.watch<SiteContentController>().content;
    final user = auth.currentUser;

    return Container(
      width: 272,
      color: AppColors.navyDeep,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 26, 24, 8),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: content.accent,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      content.shortName.isNotEmpty
                          ? content.shortName.substring(0, 1)
                          : 'C',
                      style: const TextStyle(
                        color: AppColors.navyDeep,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      content.churchName,
                      style: GoogleFonts.cormorantGaramond(
                        color: AppColors.onDark,
                        fontSize: 21,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 4, 24, 18),
              child: Text(
                auth.isStaff ? 'STAFF WORKSPACE' : 'MEMBER PORTAL',
                style: const TextStyle(
                  color: AppColors.goldSoft,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.6,
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                children: [
                  for (final e in entries)
                    _NavTile(
                      entry: e,
                      active: location.startsWith(e.path),
                      onTap: () {
                        if (inDrawer) Navigator.of(context).pop();
                        context.go(e.path);
                      },
                    ),
                ],
              ),
            ),
            const Divider(color: Colors.white24, height: 1),
            _FooterTile(
              icon: Icons.public,
              label: 'View live site',
              onTap: () {
                if (inDrawer) Navigator.of(context).pop();
                context.go('/');
              },
            ),
            if (user != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 12, 8),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: content.accent,
                      child: Text(
                        user.name.isNotEmpty ? user.name[0] : '?',
                        style: const TextStyle(
                          color: AppColors.navyDeep,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.name,
                            style: const TextStyle(
                              color: AppColors.onDark,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            user.role.label,
                            style: const TextStyle(
                              color: AppColors.onDarkSoft,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Sign out',
                      icon: const Icon(Icons.logout, color: AppColors.onDarkSoft),
                      onPressed: () async {
                        await context.read<AuthController>().signOut();
                        if (context.mounted) context.go('/');
                      },
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  final _NavEntry entry;
  final bool active;
  final VoidCallback onTap;
  const _NavTile({
    required this.entry,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: active ? Colors.white.withValues(alpha: 0.10) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            child: Row(
              children: [
                Icon(
                  entry.icon,
                  size: 21,
                  color: active ? AppColors.goldSoft : AppColors.onDarkSoft,
                ),
                const SizedBox(width: 14),
                Text(
                  entry.label,
                  style: TextStyle(
                    color: active ? AppColors.onDark : AppColors.onDarkSoft,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FooterTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _FooterTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 19, color: AppColors.onDarkSoft),
            const SizedBox(width: 14),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.onDarkSoft,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
