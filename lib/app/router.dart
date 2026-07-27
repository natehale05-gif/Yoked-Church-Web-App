import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
import '../features/auth/application/auth_providers.dart';
import '../features/auth/presentation/forgot_password_screen.dart';
import '../features/auth/presentation/sign_in_screen.dart';
import '../features/auth/presentation/sign_up_screen.dart';
import '../features/church_info/presentation/about_screen.dart';
import '../features/church_info/presentation/visit_screen.dart';
import '../features/connect/presentation/connect_screen.dart';
import '../features/events/presentation/events_screen.dart';
import '../features/giving/presentation/giving_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/sermons/presentation/sermon_detail_screen.dart';
import '../features/sermons/presentation/sermons_screen.dart';

const _authPaths = {'/sign-in', '/sign-up', '/forgot-password'};

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

      if (path.startsWith('/account') && !signedIn) return '/sign-in';
      if (path.startsWith('/admin')) {
        if (!signedIn) return '/sign-in';
        if (!ref.read(isStaffProvider)) return '/account';
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

          GoRoute(path: '/account', builder: (_, _) => const AccountHomeScreen()),
          GoRoute(path: '/account/profile', builder: (_, _) => const ProfileScreen()),
          GoRoute(path: '/account/groups', builder: (_, _) => const MyGroupsScreen()),
          GoRoute(path: '/account/events', builder: (_, _) => const MyEventsScreen()),
          GoRoute(path: '/account/volunteering', builder: (_, _) => const MyVolunteeringScreen()),
          GoRoute(path: '/account/directory', builder: (_, _) => const DirectoryScreen()),
          GoRoute(path: '/account/giving', builder: (_, _) => const GivingHistoryScreen()),
          GoRoute(path: '/account/notifications', builder: (_, _) => const NotificationsScreen()),
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
