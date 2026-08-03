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

  /// Empty for a group heading, which navigates nowhere itself.
  final String path;
  final List<NavDestination> children;

  const NavDestination(this.label, this.path, {this.children = const []});

  bool get isGroup => children.isNotEmpty;

  /// True when this entry, or anything under it, is the open page.
  bool covers(String currentPath) =>
      path == currentPath || children.any((child) => child.path == currentPath);
}

/// Primary nav is derived from feature flags, so a church that turns off
/// (say) sermons never sees a dead link.
///
/// The discipleship sections are grouped under one menu rather than laid
/// out flat: a church running all of them would otherwise push the bar
/// to eight top-level links, and they read as one area anyway.
List<NavDestination> primaryNav(ChurchSettings settings) {
  final flags = settings.features;
  final grow = <NavDestination>[
    if (flags.devotionals) const NavDestination('Devotionals', '/devotionals'),
    if (flags.readingPlans) const NavDestination('Reading Plans', '/reading-plans'),
    if (flags.resources) const NavDestination('Resources', '/resources'),
  ];

  return [
    const NavDestination('Home', '/'),
    if (flags.sermons) const NavDestination('Sermons', '/sermons'),
    if (flags.events) const NavDestination('Events', '/events'),
    if (grow.isNotEmpty) NavDestination('Grow', '', children: grow),
    const NavDestination('About', '/about'),
    const NavDestination('Visit', '/visit'),
    if (flags.connect) const NavDestination('Connect', '/connect'),
    if (flags.forms) const NavDestination('Forms', '/forms'),
  ];
}

/// True when the installable-app downloads have somewhere to point.
///
/// Both conditions, matching the route guard: the feature has to be on
/// *and* an admin has to have named the repository whose releases hold
/// the builds. Either missing and the links would 404.
bool hasAppDownloads(ChurchSettings settings) =>
    settings.features.appDownloads && settings.releasesRepo.trim().isNotEmpty;

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
    // A phone gets app navigation, not website navigation. The top bar
    // keeps only the church's name and the notification bell; getting
    // anywhere happens through the bar at the bottom, where a thumb
    // actually reaches. Above mobile width the top bar is unchanged -
    // a mouse has no reach problem and a wide window has room for links.
    final isMobile = Breakpoints.isMobile(context);

    return Scaffold(
      appBar: const AppNavBar(),
      body: child,
      bottomNavigationBar: isMobile ? const AppBottomNav() : null,
    );
  }
}

/// The five destinations a phone shows along the bottom.
///
/// Four from the church's own feature flags plus **More**, which is
/// where everything that did not fit goes - including the account and
/// the church switcher. Five is the ceiling because Material's
/// [NavigationBar] stops being tappable past it, and because a person
/// scanning a bar cannot hold more than that anyway.
List<NavDestination> bottomNav(ChurchSettings settings) {
  final flags = settings.features;
  return [
    const NavDestination('Home', '/'),
    if (flags.sermons) const NavDestination('Watch', '/sermons'),
    if (flags.events) const NavDestination('Events', '/events'),
    if (flags.giving) const NavDestination('Give', '/give'),
    const NavDestination('More', ''),
  ].take(5).toList();
}

IconData _iconFor(String path) => switch (path) {
      '/' => Icons.home_outlined,
      '/sermons' => Icons.play_circle_outline,
      '/events' => Icons.event_outlined,
      '/give' => Icons.favorite_outline,
      _ => Icons.menu,
    };

class AppBottomNav extends ConsumerWidget {
  const AppBottomNav({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Same reason the top bar listens: this is built const, so without a
    // listener the highlight sticks on whichever page opened first.
    return ListenableBuilder(
      listenable: GoRouter.of(context).routerDelegate,
      builder: (context, _) => _build(context, ref),
    );
  }

  Widget _build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final destinations = bottomNav(settings);
    final currentPath = GoRouter.of(context).routerDelegate.currentConfiguration.uri.path;

    // Anything reached from More - a devotional, the account, a form -
    // keeps More lit rather than falsely highlighting Home.
    var selected = destinations.indexWhere((d) => d.path == currentPath);
    if (selected < 0) selected = destinations.length - 1;

    return NavigationBar(
      selectedIndex: selected,
      onDestinationSelected: (index) {
        final destination = destinations[index];
        if (destination.path.isEmpty) {
          openMoreMenu(context, primaryNav(settings), settings);
        } else {
          context.go(destination.path);
        }
      },
      destinations: [
        for (final destination in destinations)
          NavigationDestination(
            icon: Icon(_iconFor(destination.path)),
            label: destination.label,
          ),
      ],
    );
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
    final destinations = primaryNav(settings);

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
                              selected: destination.covers(currentPath),
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
            // Only tablets keep the hamburger: they are collapsed but
            // have no bottom bar, which is reserved for phone widths.
            if (collapsed && !Breakpoints.isMobile(context))
              IconButton(
                icon: const Icon(Icons.menu),
                tooltip: 'Menu',
                onPressed: () => openMoreMenu(context, destinations, settings),
              ),
          ],
        ),
      ),
    );
  }

}

/// The sheet behind **More** on a phone, and behind the hamburger on a
/// tablet. Everything that did not earn a permanent place.
void openMoreMenu(
  BuildContext context,
  List<NavDestination> destinations,
  ChurchSettings settings,
) {
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
                  // The sheet has room to be flat, so groups are shown
                  // expanded rather than as a nested menu.
                  for (final destination in destinations)
                    if (destination.isGroup)
                      for (final child in destination.children)
                        ListTile(title: Text(child.label), onTap: () => go(child.path))
                    else
                      ListTile(title: Text(destination.label), onTap: () => go(destination.path)),
                  if (hasAppDownloads(settings))
                    ListTile(
                      leading: const Icon(Icons.download),
                      title: const Text('Get the App'),
                      onTap: () => go('/download'),
                    ),
                  const Divider(height: 1),
                  // Which church this is, and the way out of it. Shown to
                  // everyone, signed in or not: a visitor who picked the
                  // wrong church needs this more than a member does.
                  ListTile(
                    leading: const Icon(Icons.church_outlined),
                    title: Text(settings.churchName),
                    subtitle: const Text('Switch church'),
                    trailing: const Icon(Icons.swap_horiz),
                    onTap: () => go('/choose-church?switch=1'),
                  ),
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
    final style = TextStyle(fontWeight: selected ? FontWeight.w700 : FontWeight.w500);
    final foreground = selected ? color.accent : color.primary;

    if (destination.isGroup) {
      return PopupMenuButton<String>(
        tooltip: destination.label,
        offset: const Offset(0, 44),
        onSelected: context.go,
        itemBuilder: (context) => [
          for (final child in destination.children)
            PopupMenuItem(value: child.path, child: Text(child.label)),
        ],
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(destination.label, style: style.copyWith(color: foreground)),
              Icon(Icons.arrow_drop_down, size: 20, color: foreground),
            ],
          ),
        ),
      );
    }

    return TextButton(
      onPressed: () => context.go(destination.path),
      style: TextButton.styleFrom(foregroundColor: foreground),
      child: Text(destination.label, style: style),
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
              if (social.podcastUrl.isNotEmpty) _SocialLink(icon: Icons.podcasts, url: social.podcastUrl),
            ],
          ),
          if (hasAppDownloads(settings)) ...[
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () => context.go('/download'),
              icon: const Icon(Icons.download, color: Colors.white, size: 18),
              label: const Text('Get the app for your phone or computer',
                  style: TextStyle(color: Colors.white)),
              style: TextButton.styleFrom(padding: EdgeInsets.zero),
            ),
          ],
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
