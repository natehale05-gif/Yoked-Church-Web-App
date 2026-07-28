import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/config/church_settings.dart';
import '../core/config/settings_providers.dart';
import '../core/widgets/app_shell.dart';
import '../core/widgets/section_container.dart';
import '../features/account/presentation/account_home_screen.dart';
import '../features/account/presentation/directory_screen.dart';
import '../features/account/presentation/giving_history_screen.dart';
import '../features/account/presentation/my_events_screen.dart';
import '../features/account/presentation/my_groups_screen.dart';
import '../features/account/presentation/my_volunteering_screen.dart';
import '../features/account/presentation/notifications_screen.dart';
import '../features/account/presentation/profile_screen.dart';
import '../features/admin/presentation/admin_home_screen.dart';
import '../features/admin/presentation/announcements_admin_screen.dart';
import '../features/admin/presentation/audit_admin_screen.dart';
import '../features/admin/presentation/connect_admin_screen.dart';
import '../features/admin/presentation/devotionals_admin_screen.dart';
import '../features/admin/presentation/events_admin_screen.dart';
import '../features/admin/presentation/groups_admin_screen.dart';
import '../features/admin/presentation/members_admin_screen.dart';
import '../features/admin/presentation/sermons_admin_screen.dart';
import '../features/admin/presentation/settings_admin_screen.dart';
import '../features/admin/presentation/volunteering_admin_screen.dart';
import '../features/auth/application/auth_providers.dart';
import '../features/auth/presentation/forgot_password_screen.dart';
import '../features/auth/presentation/sign_in_screen.dart';
import '../features/auth/presentation/sign_up_screen.dart';
import '../features/church_info/presentation/about_screen.dart';
import '../features/church_info/presentation/visit_screen.dart';
import '../features/connect/presentation/connect_screen.dart';
import '../features/devotionals/presentation/devotional_detail_screen.dart';
import '../features/devotionals/presentation/devotionals_screen.dart';
import '../features/events/presentation/events_screen.dart';
import '../features/giving/presentation/giving_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/sermons/presentation/sermon_detail_screen.dart';
import '../features/sermons/presentation/sermons_screen.dart';

const _authPaths = {'/sign-in', '/sign-up', '/forgot-password'};
const _adminOnlyPaths = {'/admin/members', '/admin/settings', '/admin/audit'};

/// Route prefixes owned by a feature flag. Turning a feature off has to
/// close the route as well as hide the nav link, or the page stays live
/// for anyone with the URL - and for search engines that already indexed
/// it.
bool _flagAllows(FeatureFlags flags, String path) {
  bool owns(String prefix) => path == prefix || path.startsWith('$prefix/');

  if (owns('/sermons') || owns('/admin/sermons')) return flags.sermons;
  if (owns('/events') || owns('/admin/events')) return flags.events;
  if (owns('/give')) return flags.giving;
  if (owns('/connect') || owns('/admin/connect')) return flags.connect;
  if (owns('/devotionals') || owns('/admin/devotionals')) return flags.devotionals;
  return true;
}

/// Every route is registered unconditionally; access is decided by the
/// redirect below at request time.
///
/// The previous architecture registered different route *sets* based on a
/// compile-time flag, so one build could not serve both modes and deep
/// links into unregistered routes silently 404'd.
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    refreshListenable: _AuthRefresh(ref),
    redirect: (context, state) {
      final path = state.uri.path;
      final signedIn = ref.read(isSignedInProvider);
      final loading = ref.read(authLoadingProvider);

      // Don't bounce anyone while the first auth check is still in flight,
      // or a signed-in member refreshing /account lands on the login page.
      if (loading) return null;

      if (!_flagAllows(ref.read(featureFlagsProvider), path)) return '/';

      if (path.startsWith('/account') && !signedIn) return '/sign-in';
      if (path.startsWith('/admin')) {
        if (!signedIn) return '/sign-in';
        if (!ref.read(isStaffProvider)) return '/account';
        // Members/roles, settings, and the audit trail can reshape the
        // church, so they are admin-only even among staff.
        if (_adminOnlyPaths.contains(path) && !ref.read(isAdminProvider)) return '/admin';
      }
      if (_authPaths.contains(path) && signedIn) return '/account';
      return null;
    },
    errorBuilder: (context, state) => AppShell(child: _NotFound(location: state.uri.toString())),
    routes: [
      // Auth screens sit outside the site shell - a focused, chrome-free flow.
      GoRoute(path: '/sign-in', builder: (_, _) => const SignInScreen()),
      GoRoute(path: '/sign-up', builder: (_, _) => const SignUpScreen()),
      GoRoute(path: '/forgot-password', builder: (_, _) => const ForgotPasswordScreen()),
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(path: '/', builder: (_, _) => const HomeScreen()),
          GoRoute(path: '/sermons', builder: (_, _) => const SermonsScreen()),
          GoRoute(
            path: '/sermons/:id',
            builder: (_, state) => SermonDetailScreen(sermonId: state.pathParameters['id']!),
          ),
          GoRoute(path: '/events', builder: (_, _) => const EventsScreen()),
          GoRoute(path: '/give', builder: (_, _) => const GivingScreen()),
          GoRoute(path: '/connect', builder: (_, _) => const ConnectScreen()),
          GoRoute(path: '/about', builder: (_, _) => const AboutScreen()),
          GoRoute(path: '/visit', builder: (_, _) => const VisitScreen()),
          GoRoute(path: '/devotionals', builder: (_, _) => const DevotionalsScreen()),
          GoRoute(
            path: '/devotionals/:id',
            builder: (_, state) => DevotionalDetailScreen(devotionalId: state.pathParameters['id']!),
          ),

          GoRoute(path: '/account', builder: (_, _) => const AccountHomeScreen()),
          GoRoute(path: '/account/profile', builder: (_, _) => const ProfileScreen()),
          GoRoute(path: '/account/groups', builder: (_, _) => const MyGroupsScreen()),
          GoRoute(path: '/account/events', builder: (_, _) => const MyEventsScreen()),
          GoRoute(path: '/account/volunteering', builder: (_, _) => const MyVolunteeringScreen()),
          GoRoute(path: '/account/directory', builder: (_, _) => const DirectoryScreen()),
          GoRoute(path: '/account/giving', builder: (_, _) => const GivingHistoryScreen()),
          GoRoute(path: '/account/notifications', builder: (_, _) => const NotificationsScreen()),

          GoRoute(path: '/admin', builder: (_, _) => const AdminHomeScreen()),
          GoRoute(path: '/admin/sermons', builder: (_, _) => const SermonsAdminScreen()),
          GoRoute(path: '/admin/events', builder: (_, _) => const EventsAdminScreen()),
          GoRoute(path: '/admin/groups', builder: (_, _) => const GroupsAdminScreen()),
          GoRoute(path: '/admin/volunteering', builder: (_, _) => const VolunteeringAdminScreen()),
          GoRoute(path: '/admin/connect', builder: (_, _) => const ConnectAdminScreen()),
          GoRoute(path: '/admin/announcements', builder: (_, _) => const AnnouncementsAdminScreen()),
          GoRoute(path: '/admin/devotionals', builder: (_, _) => const DevotionalsAdminScreen()),
          GoRoute(path: '/admin/members', builder: (_, _) => const MembersAdminScreen()),
          GoRoute(path: '/admin/settings', builder: (_, _) => const SettingsAdminScreen()),
          GoRoute(path: '/admin/audit', builder: (_, _) => const AuditAdminScreen()),
        ],
      ),
    ],
  );
});

/// Re-runs the router's redirect whenever the signed-in user changes.
class _AuthRefresh extends ChangeNotifier {
  _AuthRefresh(Ref ref) {
    ref.listen(authStateProvider, (_, _) => notifyListeners());
  }
}

class _NotFound extends StatelessWidget {
  final String location;

  const _NotFound({required this.location});

  @override
  Widget build(BuildContext context) {
    return PageBody(
      children: [
        SectionContainer(
          maxWidth: 620,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Page not found', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 12),
              Text("We couldn't find $location.", style: const TextStyle(color: Colors.black54)),
              const SizedBox(height: 24),
              ElevatedButton(onPressed: () => context.go('/'), child: const Text('Back home')),
            ],
          ),
        ),
      ],
    );
  }
}
