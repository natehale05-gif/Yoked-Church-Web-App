import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/theme.dart';
import '../../features/auth/application/auth_providers.dart';
import '../../features/notifications/application/notification_providers.dart';
import '../config/church_settings.dart';
import '../config/settings_providers.dart';

class NavDestination {
  final String label;
  final String path;

  const NavDestination(this.label, this.path);
}

/// Primary nav is derived from feature flags, so a church that turns off
/// (say) sermons never sees a dead link.
List<NavDestination> primaryNav(FeatureFlags flags) => [
      const NavDestination('Home', '/'),
      if (flags.sermons) const NavDestination('Sermons', '/sermons'),
      if (flags.events) const NavDestination('Events', '/events'),
      if (flags.devotionals) const NavDestination('Devotionals', '/devotionals'),
      const NavDestination('About', '/about'),
      const NavDestination('Visit', '/visit'),
      if (flags.connect) const NavDestination('Connect', '/connect'),
    ];

/// Wraps every public page with the shared nav bar.
///
/// Scrolling deliberately lives in [PageBody] on each page rather than
/// here: the shell's child is a `Navigator` (from go_router's
/// `ShellRoute`), and a Navigator inside a scroll view has no bounded
/// height to lay out against.
class AppShell extends ConsumerWidget {
  final Widget child;

  const AppShell({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(appBar: const AppNavBar(), body: child);
  }
}

/// The scrolling body of a single page, with the shared footer appended.
class PageBody extends StatelessWidget {
  final List<Widget> children;

  const PageBody({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(children: [...children, const AppFooter()]),
    );
  }
}

class AppNavBar extends ConsumerWidget implements PreferredSizeWidget {
  const AppNavBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(76);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Rebuild whenever the router navigates. This bar is built as
    // `const AppNavBar()`, so Dart canonicalises it to a single instance
    // and Flutter skips the subtree on rebuild - without listening here,
    // the highlight sticks on whichever page was open first.
    return ListenableBuilder(
      listenable: GoRouter.of(context).routerDelegate,
      builder: (context, _) => _buildBar(context, ref),
    );
  }

  Widget _buildBar(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    // Read the location straight off the router delegate's configuration.
    // Both `GoRouterState.of(context)` and `GoRouter.of(context).state`
    // throw on the error/404 page - there is no matched route to describe -
    // which would turn any bad URL into a crashed page instead of a
    // friendly "not found".
    final currentPath = GoRouter.of(context).routerDelegate.currentConfiguration.uri.path;
    // Collapse to a menu below desktop width so the link row never has to
    // squeeze into a narrow (e.g. tablet) viewport.
    final collapsed = !Breakpoints.isDesktop(context);
    final destinations = primaryNav(settings.features);

    return AppBar(
      toolbarHeight: preferredSize.height,
      titleSpacing: 0,
      title: Padding(
        padding: EdgeInsets.symmetric(horizontal: collapsed ? 16 : 40),
        child: Row(
          children: [
            _Wordmark(settings: settings),
            // The link row scrolls rather than overflows. A church can
            // switch on every feature at once, and the wordmark is its
            // own name - neither has a length this bar can assume.
            Expanded(
              child: !collapsed
                  ? SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      reverse: true,
                      child: Row(
                        children: [
                          for (final destination in destinations)
                            _NavLink(
                              destination: destination,
                              selected: currentPath == destination.path,
                              color: settings.colors,
                            ),
                        ],
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
            const NotificationBell(),
            if (!collapsed) ...[
              const SizedBox(width: 4),
              const AccountControl(),
            ],
            if (!collapsed && settings.features.giving) ...[
              const SizedBox(width: 12),
              ElevatedButton(onPressed: () => context.go('/give'), child: const Text('Give')),
            ],
            if (collapsed)
              IconButton(
                icon: const Icon(Icons.menu),
                tooltip: 'Menu',
                onPressed: () => _openMenu(context, destinations, settings),
              ),
          ],
        ),
      ),
    );
  }

  void _openMenu(BuildContext context, List<NavDestination> destinations, ChurchSettings settings) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: SingleChildScrollView(
          child: Consumer(
            builder: (sheetContext, ref, _) {
              final user = ref.watch(currentUserProvider);

              void go(String path) {
                Navigator.pop(sheetContext);
                context.go(path);
              }

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final destination in destinations)
                    ListTile(title: Text(destination.label), onTap: () => go(destination.path)),
                  const Divider(height: 1),
                  if (user == null)
                    ListTile(
                      leading: const Icon(Icons.login),
                      title: const Text('Sign In'),
                      onTap: () => go('/sign-in'),
                    )
                  else ...[
                    ListTile(
                      leading: const Icon(Icons.person_outline),
                      title: const Text('My Account'),
                      onTap: () => go('/account'),
                    ),
                    if (user.isStaff)
                      ListTile(
                        leading: const Icon(Icons.admin_panel_settings_outlined),
                        title: const Text('Staff Dashboard'),
                        onTap: () => go('/admin'),
                      ),
                    ListTile(
                      leading: const Icon(Icons.logout),
                      title: const Text('Sign Out'),
                      onTap: () async {
                        Navigator.pop(sheetContext);
                        await ref.read(authControllerProvider.notifier).signOut();
                        if (context.mounted) context.go('/');
                      },
                    ),
                  ],
                  if (settings.features.giving)
                    ListTile(
                      leading: Icon(Icons.favorite, color: settings.colors.accent),
                      title: const Text('Give', style: TextStyle(fontWeight: FontWeight.w700)),
                      onTap: () => go('/give'),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Sign-in link when signed out; avatar menu when signed in.
class AccountControl extends ConsumerWidget {
  const AccountControl({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final user = ref.watch(currentUserProvider);

    if (user == null) {
      return TextButton(
        onPressed: () => context.go('/sign-in'),
        style: TextButton.styleFrom(foregroundColor: settings.colors.primary),
        child: const Text('Sign In', style: TextStyle(fontWeight: FontWeight.w500)),
      );
    }

    return PopupMenuButton<String>(
      tooltip: 'Account',
      offset: const Offset(0, 48),
      itemBuilder: (context) => [
        const PopupMenuItem(value: '/account', child: Text('My Account')),
        if (user.isStaff) const PopupMenuItem(value: '/admin', child: Text('Staff Dashboard')),
        const PopupMenuItem(value: 'sign-out', child: Text('Sign Out')),
      ],
      onSelected: (value) async {
        if (value == 'sign-out') {
          await ref.read(authControllerProvider.notifier).signOut();
          if (context.mounted) context.go('/');
        } else {
          context.go(value);
        }
      },
      child: CircleAvatar(
        radius: 18,
        backgroundColor: settings.colors.primary.withValues(alpha: 0.12),
        child: Text(
          user.initial,
          style: TextStyle(color: settings.colors.primary, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

/// Bell with an unread badge. Hidden entirely when signed out.
class NotificationBell extends ConsumerWidget {
  const NotificationBell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(currentUserProvider) == null) return const SizedBox.shrink();
    final unread = ref.watch(unreadNotificationCountProvider);

    return IconButton(
      tooltip: 'Notifications',
      onPressed: () => context.go('/account/notifications'),
      icon: Badge(
        isLabelVisible: unread > 0,
        label: Text('$unread'),
        child: const Icon(Icons.notifications_outlined),
      ),
    );
  }
}

class _Wordmark extends StatelessWidget {
  final ChurchSettings settings;

  const _Wordmark({required this.settings});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.go('/'),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (settings.logoUrl.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Image.network(
                settings.logoUrl,
                height: 32,
                errorBuilder: (_, _, _) => Icon(Icons.church, color: settings.colors.primary, size: 28),
              ),
            )
          else ...[
            Icon(Icons.church, color: settings.colors.primary, size: 28),
            const SizedBox(width: 10),
          ],
          Text(
            settings.churchName,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(color: settings.colors.primary),
          ),
        ],
      ),
    );
  }
}

class _NavLink extends StatelessWidget {
  final NavDestination destination;
  final bool selected;
  final BrandColors color;

  const _NavLink({required this.destination, required this.selected, required this.color});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () => context.go(destination.path),
      style: TextButton.styleFrom(foregroundColor: selected ? color.accent : color.primary),
      child: Text(
        destination.label,
        style: TextStyle(fontWeight: selected ? FontWeight.w700 : FontWeight.w500),
      ),
    );
  }
}

class AppFooter extends ConsumerWidget {
  const AppFooter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final isMobile = Breakpoints.isMobile(context);
    final social = settings.social;

    return Container(
      width: double.infinity,
      color: settings.colors.primary,
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 20 : 60, vertical: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(settings.churchName, style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white)),
          const SizedBox(height: 8),
          if (settings.contact.address.isNotEmpty)
            Text(settings.contact.address, style: const TextStyle(color: Colors.white70)),
          Text(
            [settings.contact.phone, settings.contact.email].where((s) => s.isNotEmpty).join(' · '),
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            children: [
              if (social.facebook.isNotEmpty) _SocialLink(icon: Icons.facebook, url: social.facebook),
              if (social.instagram.isNotEmpty) _SocialLink(icon: Icons.camera_alt_outlined, url: social.instagram),
              if (social.youtube.isNotEmpty) _SocialLink(icon: Icons.play_circle_outline, url: social.youtube),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(color: Colors.white24),
          const SizedBox(height: 12),
          Text(
            '© ${DateTime.now().year} ${settings.churchName}. All rights reserved.',
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _SocialLink extends StatelessWidget {
  final IconData icon;
  final String url;

  const _SocialLink({required this.icon, required this.url});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, color: Colors.white),
      onPressed: () => launchUrl(Uri.parse(url), webOnlyWindowName: '_blank'),
    );
  }
}
