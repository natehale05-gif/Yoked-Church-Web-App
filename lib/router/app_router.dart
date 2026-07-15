import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../pages/about_page.dart';
import '../pages/contact_page.dart';
import '../pages/events_page.dart';
import '../pages/give_page.dart';
import '../pages/home_page.dart';
import '../pages/ministries_page.dart';
import '../pages/sermons_page.dart';
import '../pages/visit_page.dart';
import '../widgets/site_scaffold.dart';

/// All routes wrap their page in [SiteScaffold] so the nav + footer are shared.
/// A subtle fade keeps navigation feeling smooth and premium.
final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    _page('/', const HomePage()),
    _page('/visit', const VisitPage()),
    _page('/sermons', const SermonsPage()),
    _page('/events', const EventsPage()),
    _page('/ministries', const MinistriesPage()),
    _page('/about', const AboutPage()),
    _page('/give', const GivePage()),
    _page('/contact', const ContactPage()),
  ],
  errorBuilder: (context, state) => const SiteScaffold(child: HomePage()),
);

GoRoute _page(String path, Widget child) {
  return GoRoute(
    path: path,
    pageBuilder: (context, state) => CustomTransitionPage(
      key: state.pageKey,
      child: SiteScaffold(child: child),
      transitionDuration: const Duration(milliseconds: 260),
      transitionsBuilder: (context, animation, secondary, child) {
        return FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: child,
        );
      },
    ),
  );
}
