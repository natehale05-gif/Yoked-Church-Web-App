import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../state/site_content_controller.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/responsive.dart';
import '../utils/launch.dart';
import 'buttons.dart';
import 'content_width.dart';
import 'nav_items.dart';

/// A sticky, premium top navigation bar. Turns into a clean menu on mobile.
/// [scrolled] toggles a solid background + subtle shadow once the user scrolls.
class TopNav extends StatelessWidget {
  final bool scrolled;
  final VoidCallback onMenuTap;

  const TopNav({super.key, required this.scrolled, required this.onMenuTap});

  @override
  Widget build(BuildContext context) {
    final currentPath = GoRouterState.of(context).uri.path;
    final solid = scrolled;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      decoration: BoxDecoration(
        color: solid ? AppColors.ivory.withValues(alpha: 0.96) : Colors.transparent,
        border: Border(
          bottom: BorderSide(
            color: solid ? AppColors.line : Colors.transparent,
          ),
        ),
      ),
      child: ContentWidth(
        child: SizedBox(
          height: 78,
          child: Row(
            children: [
              _Wordmark(onDark: !solid),
              const Spacer(),
              if (context.isDesktop) ...[
                for (final item in kNavItems)
                  _NavLink(
                    item: item,
                    active: _isActive(currentPath, item.path),
                    onDark: !solid,
                  ),
                _NavLink(
                  item: const NavItem('Sign in', '/login'),
                  active: currentPath == '/login',
                  onDark: !solid,
                ),
                const SizedBox(width: 12),
                PrimaryButton(
                  label: 'Give',
                  onPressed: () =>
                      openUrl(context.read<SiteContentController>().content.giveUrl),
                ),
              ] else
                IconButton(
                  onPressed: onMenuTap,
                  iconSize: 30,
                  icon: Icon(
                    Icons.menu,
                    color: solid ? AppColors.navy : AppColors.onDark,
                  ),
                  tooltip: 'Menu',
                ),
            ],
          ),
        ),
      ),
    );
  }

  static bool _isActive(String current, String path) {
    if (path == '/') return current == '/';
    return current.startsWith(path);
  }
}

class _Wordmark extends StatelessWidget {
  final bool onDark;
  const _Wordmark({required this.onDark});

  @override
  Widget build(BuildContext context) {
    final color = onDark ? AppColors.onDark : AppColors.navy;
    final content = context.watch<SiteContentController>().content;
    final initial = content.shortName.isNotEmpty
        ? content.shortName.substring(0, 1)
        : (content.churchName.isNotEmpty ? content.churchName.substring(0, 1) : '?');
    return InkWell(
      onTap: () => context.go('/'),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
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
                initial,
                style: const TextStyle(
                  color: AppColors.navyDeep,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              content.churchName,
              style: GoogleFonts.cormorantGaramond(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: color,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavLink extends StatefulWidget {
  final NavItem item;
  final bool active;
  final bool onDark;

  const _NavLink({
    required this.item,
    required this.active,
    required this.onDark,
  });

  @override
  State<_NavLink> createState() => _NavLinkState();
}

class _NavLinkState extends State<_NavLink> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final baseColor = widget.onDark ? AppColors.onDark : AppColors.ink;
    final activeColor = widget.onDark ? AppColors.goldSoft : AppColors.navy;
    final color = (widget.active || _hover) ? activeColor : baseColor;

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: () => context.go(widget.item.path),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.item.label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                height: 2,
                width: widget.active ? 20 : 0,
                color: AppColors.gold,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Slide-in drawer used on tablet / mobile.
class NavDrawer extends StatelessWidget {
  const NavDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final currentPath = GoRouterState.of(context).uri.path;
    final content = context.watch<SiteContentController>().content;
    return Drawer(
      backgroundColor: AppColors.navyDeep,
      width: 300,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: AppColors.onDark),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                content.churchName,
                style: GoogleFonts.cormorantGaramond(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onDark,
                ),
              ),
              const SizedBox(height: 28),
              for (final item in kNavItems)
                _DrawerLink(
                  item: item,
                  active: TopNav._isActive(currentPath, item.path),
                ),
              _DrawerLink(
                item: const NavItem('Sign in', '/login'),
                active: currentPath == '/login',
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                label: 'Give',
                icon: Icons.favorite,
                onPressed: () {
                  Navigator.of(context).pop();
                  openUrl(content.giveUrl);
                },
              ),
              const Spacer(),
              Text(
                content.addressLine1,
                style: AppTheme.eyebrow(color: AppColors.onDarkSoft),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DrawerLink extends StatelessWidget {
  final NavItem item;
  final bool active;
  const _DrawerLink({required this.item, required this.active});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.of(context).pop();
        context.go(item.path);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: 3,
              height: 22,
              color: active ? AppColors.gold : Colors.transparent,
            ),
            const SizedBox(width: 16),
            Text(
              item.label,
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w600,
                color: active ? AppColors.goldSoft : AppColors.onDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
