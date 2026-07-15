import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../pages/about_page.dart';
import '../pages/admin/admin_attendance_page.dart';
import '../pages/admin/admin_dashboard_page.dart';
import '../pages/admin/admin_editor_page.dart';
import '../pages/admin/admin_members_page.dart';
import '../pages/admin/admin_serving_page.dart';
import '../pages/auth/login_page.dart';
import '../pages/contact_page.dart';
import '../pages/events_page.dart';
import '../pages/give_page.dart';
import '../pages/home_page.dart';
import '../pages/member/member_home_page.dart';
import '../pages/member/member_serve_page.dart';
import '../pages/ministries_page.dart';
import '../pages/sermons_page.dart';
import '../pages/visit_page.dart';
import '../state/auth_controller.dart';
import '../widgets/app_shell.dart';
import '../widgets/site_scaffold.dart';

const _staffOnly = [
  '/app/dashboard',
  '/app/editor',
  '/app/members',
  '/app/attendance',
  '/app/serving',
];
const _memberOnly = ['/app/me', '/app/serve'];

/// Boundary-aware prefix match so that, e.g., `/app/members` does not match
/// `/app/me` (which would wrongly redirect staff away from the Members page).
bool _matchesAny(String loc, List<String> paths) =>
    paths.any((p) => loc == p || loc.startsWith('$p/'));

GoRouter buildRouter(AuthController auth) {
  return GoRouter(
    initialLocation: '/',
    refreshListenable: auth,
    redirect: (context, state) {
      final loc = state.matchedLocation;
      final signedIn = auth.isSignedIn;
      final staff = auth.isStaff;
      final inApp = loc.startsWith('/app');

      if (inApp && !signedIn) return '/login';
      if (loc == '/login' && signedIn) {
        return staff ? '/app/dashboard' : '/app/me';
      }
      if (inApp && signedIn) {
        if (loc == '/app') return staff ? '/app/dashboard' : '/app/me';
        if (!staff && _matchesAny(loc, _staffOnly)) return '/app/me';
        if (staff && _matchesAny(loc, _memberOnly)) return '/app/dashboard';
      }
      return null;
    },
    routes: [
      _public('/', const HomePage()),
      _public('/visit', const VisitPage()),
      _public('/sermons', const SermonsPage()),
      _public('/events', const EventsPage()),
      _public('/ministries', const MinistriesPage()),
      _public('/about', const AboutPage()),
      _public('/give', const GivePage()),
      _public('/contact', const ContactPage()),
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: LoginPage()),
      ),
      ShellRoute(
        builder: (context, state, child) => AppShell(
          location: state.matchedLocation,
          child: child,
        ),
        routes: [
          GoRoute(path: '/app', redirect: (context, state) => '/app/dashboard'),
          _app('/app/dashboard', const AdminDashboardPage()),
          _app('/app/editor', const AdminEditorPage()),
          _app('/app/members', const AdminMembersPage()),
          _app('/app/attendance', const AdminAttendancePage()),
          _app('/app/serving', const AdminServingPage()),
          _app('/app/me', const MemberHomePage()),
          _app('/app/serve', const MemberServePage()),
        ],
      ),
    ],
    errorBuilder: (context, state) => const SiteScaffold(child: HomePage()),
  );
}

GoRoute _public(String path, Widget child) {
  return GoRoute(
    path: path,
    pageBuilder: (context, state) => CustomTransitionPage(
      key: state.pageKey,
      child: SiteScaffold(child: child),
      transitionDuration: const Duration(milliseconds: 260),
      transitionsBuilder: (context, animation, secondary, child) =>
          FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: child,
      ),
    ),
  );
}

GoRoute _app(String path, Widget child) {
  return GoRoute(
    path: path,
    pageBuilder: (context, state) =>
        NoTransitionPage(key: state.pageKey, child: child),
  );
}
