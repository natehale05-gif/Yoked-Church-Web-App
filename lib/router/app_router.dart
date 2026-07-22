import 'package:go_router/go_router.dart';

import '../config/church_config.dart';
import '../models/church_group.dart';
import '../models/sermon.dart';
import '../providers/auth_provider.dart';
import '../screens/account/account_home_screen.dart';
import '../screens/account/directory_screen.dart';
import '../screens/account/giving_history_screen.dart';
import '../screens/account/group_detail_screen.dart';
import '../screens/account/groups_screen.dart';
import '../screens/account/my_events_screen.dart';
import '../screens/account/profile_screen.dart';
import '../screens/admin/admin_home_screen.dart';
import '../screens/admin/connect_admin_screen.dart';
import '../screens/admin/events_admin_screen.dart';
import '../screens/admin/groups_admin_screen.dart';
import '../screens/admin/sermons_admin_screen.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/auth/sign_in_screen.dart';
import '../screens/auth/sign_up_screen.dart';
import '../screens/connect_screen.dart';
import '../screens/events_screen.dart';
import '../screens/giving_screen.dart';
import '../screens/home_screen.dart';
import '../screens/sermon_detail_screen.dart';
import '../screens/sermons_screen.dart';
import '../widgets/app_shell.dart';

const _authPaths = {'/sign-in', '/sign-up', '/forgot-password'};

GoRouter buildAppRouter(AuthProvider authProvider) {
  return GoRouter(
    initialLocation: '/',
    refreshListenable: authProvider,
    redirect: (context, state) {
      final path = state.uri.path;
      final isAccountPath = path.startsWith('/account');
      final isAdminPath = path.startsWith('/admin');

      // Accounts require Firebase - without it, send visitors home rather
      // than 404 on routes that were never registered.
      if (!ChurchConfig.useFirebase) {
        if (isAccountPath || isAdminPath || _authPaths.contains(path)) return '/';
        return null;
      }

      final signedIn = authProvider.isSignedIn;
      if ((isAccountPath || isAdminPath) && !signedIn && !authProvider.isLoading) return '/sign-in';
      if (isAdminPath && signedIn && authProvider.currentUser?.isStaff != true) return '/account';
      if (_authPaths.contains(path) && signedIn) return '/account';
      return null;
    },
    routes: [
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
          GoRoute(path: '/sermons', builder: (context, state) => const SermonsScreen()),
          GoRoute(
            path: '/sermons/:id',
            builder: (context, state) => SermonDetailScreen(
              sermonId: state.pathParameters['id']!,
              initialSermon: state.extra as Sermon?,
            ),
          ),
          GoRoute(path: '/events', builder: (context, state) => const EventsScreen()),
          GoRoute(path: '/give', builder: (context, state) => const GivingScreen()),
          GoRoute(path: '/connect', builder: (context, state) => const ConnectScreen()),
          if (ChurchConfig.useFirebase) ...[
            GoRoute(path: '/account', builder: (context, state) => const AccountHomeScreen()),
            GoRoute(path: '/account/profile', builder: (context, state) => const ProfileScreen()),
            GoRoute(path: '/account/groups', builder: (context, state) => const GroupsScreen()),
            GoRoute(
              path: '/account/groups/:id',
              builder: (context, state) => GroupDetailScreen(
                groupId: state.pathParameters['id']!,
                initialGroup: state.extra as ChurchGroup?,
              ),
            ),
            GoRoute(path: '/account/events', builder: (context, state) => const MyEventsScreen()),
            GoRoute(path: '/account/directory', builder: (context, state) => const DirectoryScreen()),
            GoRoute(path: '/account/giving', builder: (context, state) => const GivingHistoryScreen()),
            GoRoute(path: '/admin', builder: (context, state) => const AdminHomeScreen()),
            GoRoute(path: '/admin/sermons', builder: (context, state) => const SermonsAdminScreen()),
            GoRoute(path: '/admin/events', builder: (context, state) => const EventsAdminScreen()),
            GoRoute(path: '/admin/connect', builder: (context, state) => const ConnectAdminScreen()),
            GoRoute(path: '/admin/groups', builder: (context, state) => const GroupsAdminScreen()),
          ],
        ],
      ),
      if (ChurchConfig.useFirebase) ...[
        GoRoute(path: '/sign-in', builder: (context, state) => const SignInScreen()),
        GoRoute(path: '/sign-up', builder: (context, state) => const SignUpScreen()),
        GoRoute(path: '/forgot-password', builder: (context, state) => const ForgotPasswordScreen()),
      ],
    ],
  );
}
