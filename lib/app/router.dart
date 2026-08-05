import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/config/church_settings.dart';
import '../core/config/settings_providers.dart';
import '../core/config/tenant.dart';
import '../core/widgets/app_shell.dart';
import '../core/widgets/section_container.dart';
import '../features/account/presentation/account_home_screen.dart';
import '../features/account/presentation/directory_screen.dart';
import '../features/account/presentation/giving_history_screen.dart';
import '../features/account/presentation/my_bookings_screen.dart';
import '../features/account/presentation/my_events_screen.dart';
import '../features/account/presentation/my_groups_screen.dart';
import '../features/account/presentation/my_kids_screen.dart';
import '../features/account/presentation/my_notes_screen.dart';
import '../features/account/presentation/my_reading_screen.dart';
import '../features/account/presentation/my_volunteering_screen.dart';
import '../features/account/presentation/notifications_screen.dart';
import '../features/account/presentation/prayer_wall_screen.dart';
import '../features/account/presentation/profile_screen.dart';
import '../features/admin/presentation/admin_home_screen.dart';
import '../features/admin/presentation/announcements_admin_screen.dart';
import '../features/admin/presentation/attendance_admin_screen.dart';
import '../features/admin/presentation/audit_admin_screen.dart';
import '../features/admin/presentation/connect_admin_screen.dart';
import '../features/admin/presentation/devotionals_admin_screen.dart';
import '../features/admin/presentation/events_admin_screen.dart';
import '../features/admin/presentation/form_responses_screen.dart';
import '../features/admin/presentation/forms_admin_screen.dart';
import '../features/admin/presentation/groups_admin_screen.dart';
import '../features/admin/presentation/kids_admin_screen.dart';
import '../features/admin/presentation/members_admin_screen.dart';
import '../features/admin/presentation/reading_plans_admin_screen.dart';
import '../features/admin/presentation/prayer_admin_screen.dart';
import '../features/admin/presentation/reports_admin_screen.dart';
import '../features/admin/presentation/resources_admin_screen.dart';
import '../features/admin/presentation/rooms_admin_screen.dart';
import '../features/admin/presentation/sermons_admin_screen.dart';
import '../features/admin/presentation/settings_admin_screen.dart';
import '../features/admin/presentation/volunteering_admin_screen.dart';
import '../features/auth/application/auth_providers.dart';
import '../features/auth/presentation/forgot_password_screen.dart';
import '../features/auth/presentation/sign_in_screen.dart';
import '../features/auth/presentation/sign_up_screen.dart';
import '../features/church_info/presentation/about_screen.dart';
import '../features/church_info/presentation/visit_screen.dart';
import '../features/churches/presentation/church_picker_screen.dart';
import '../features/churches/presentation/church_scope.dart';
import '../features/churches/presentation/create_church_screen.dart';
import '../features/connect/presentation/connect_screen.dart';
import '../features/devotionals/presentation/devotional_detail_screen.dart';
import '../features/devotionals/presentation/devotionals_screen.dart';
import '../features/downloads/presentation/download_screen.dart';
import '../features/events/presentation/events_screen.dart';
import '../features/forms/presentation/form_detail_screen.dart';
import '../features/forms/presentation/forms_screen.dart';
import '../features/giving/presentation/giving_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/marketing/presentation/landing_screen.dart';
import '../features/reading_plans/presentation/reading_plan_detail_screen.dart';
import '../features/reading_plans/presentation/reading_plans_screen.dart';
import '../features/resources/presentation/resources_screen.dart';
import '../features/sermons/presentation/sermon_detail_screen.dart';
import '../features/sermons/presentation/sermons_screen.dart';

const _authPaths = {'/sign-in', '/sign-up', '/forgot-password'};
const _adminOnlyPaths = {'/admin/members', '/admin/settings', '/admin/audit', '/admin/reports'};

/// Route prefixes owned by a feature flag. Turning a feature off has to
/// close the route as well as hide the nav link, or the page stays live
/// for anyone with the URL - and for search engines that already indexed
/// it.
bool _flagAllows(FeatureFlags flags, String path) {
  bool owns(String prefix) => path == prefix || path.startsWith('$prefix/');

  if (owns('/sermons') || owns('/admin/sermons') || owns('/account/notes')) return flags.sermons;
  if (owns('/events') || owns('/admin/events')) return flags.events;
  if (owns('/give')) return flags.giving;
  if (owns('/connect') || owns('/admin/connect')) return flags.connect;
  if (owns('/devotionals') || owns('/admin/devotionals')) return flags.devotionals;
  if (owns('/reading-plans') || owns('/admin/reading-plans') || owns('/account/reading')) {
    return flags.readingPlans;
  }
  if (owns('/resources') || owns('/admin/resources')) return flags.resources;
  if (owns('/account/prayer') || owns('/admin/prayer')) return flags.prayerWall;
  if (owns('/account/bookings') || owns('/admin/rooms')) return flags.roomBooking;
  if (owns('/account/kids') || owns('/admin/kids')) return flags.kidsCheckIn;
  if (owns('/admin/attendance')) return flags.attendance;
  if (owns('/forms') || owns('/admin/forms')) return flags.forms;
  if (owns('/download')) return flags.appDownloads;
  return true;
}

/// Routes that belong to the product rather than to any church.
///
/// Everything else in the app is somebody's church, which is why these
/// are listed once here instead of being recognised by prefix.
const _globalPaths = {'/', '/start', '/choose-church'};

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
      final location = state.uri.path;
      final urlChurchId = churchIdFromLocation(location);
      final path = subPathOf(location);

      // Read the auth state itself, not the providers derived from it.
      //
      // This runs from the refresh below, and Riverpod invokes a listener
      // before recomputing anything downstream of what changed - so at
      // this moment `isSignedInProvider` still reports the *previous*
      // user. That is not a detail: the notification fired when someone
      // signs in is the one that matters, and reading it stale is how
      // signing in used to leave you sitting on the sign-in page.
      final auth = ref.read(authStateProvider);
      final user = auth.valueOrNull;
      final signedIn = user != null;
      final loading = auth.isLoading;

      final selected = ref.read(selectedChurchIdProvider);

      // A church-less location: the product's own pages.
      if (urlChurchId == null) {
        // Home is whichever home you have. A visitor who has never
        // chosen gets the product; a member who has gets their church,
        // which is also what the nine `context.go('/')` call sites
        // scattered through the app mean by it.
        if (location == '/') return selected == null ? null : churchPath(selected);
        if (_globalPaths.contains(location)) return null;

        // Any other bare path is an in-app link written before churches
        // had addresses - `context.go('/sermons')` and its sixty-five
        // siblings. Re-point it at the current church rather than
        // rewriting every call site.
        return selected == null ? '/choose-church' : churchPath(selected, location);
      }

      // Which church you are in has nothing to do with whether you are
      // signed in - a visitor reads a sermon without an account - so the
      // church is resolved before the auth gate below. Behind that gate
      // it would not run on a cold start.
      //
      // The URL is the authority from here down. [ChurchScope] is what
      // makes the data layer agree with it.
      if (loading) return null;

      if (!_flagAllows(ref.read(featureFlagsProvider), path)) return churchPath(urlChurchId);

      // The download buttons point at a specific repo's GitHub releases.
      // With no repo configured there is nothing to link to, so the page
      // closes rather than rendering four buttons that 404.
      if (path == '/download' && ref.read(settingsProvider).releasesRepo.trim().isEmpty) {
        return churchPath(urlChurchId);
      }

      String at(String subPath) => churchPath(urlChurchId, subPath);

      if (path.startsWith('/account') && !signedIn) return at('/sign-in');
      if (path.startsWith('/admin')) {
        if (!signedIn) return at('/sign-in');
        if (!user.isStaff) return at('/account');
        // Members/roles, settings, and the audit trail can reshape the
        // church, so they are admin-only even among staff.
        if (_adminOnlyPaths.contains(path) && !user.isAdmin) return at('/admin');
      }

      // Where signing in takes you is decided here and nowhere else.
      //
      // The screens used to navigate themselves the moment the call
      // returned, which is a beat before the auth state reaches this
      // guard - so the guard saw a signed-out visitor asking for /admin
      // and sent them back to /sign-in, undoing the sign-in they had
      // just completed.
      if (_authPaths.contains(path) && signedIn) {
        return at(user.isStaff ? '/admin' : '/account');
      }
      return null;
    },
    errorBuilder: (context, state) => AppShell(child: _NotFound(location: state.uri.toString())),
    routes: [
      // The product's own pages. Everything else in the app belongs to
      // a church; these three are what you see before you have one.
      GoRoute(path: '/', builder: (_, _) => const LandingScreen()),
      GoRoute(path: '/start', builder: (_, _) => const CreateChurchScreen()),
      GoRoute(
        path: '/choose-church',
        builder: (_, state) =>
            ChurchPickerScreen(canCancel: state.uri.queryParameters['switch'] == '1'),
      ),

      // Auth screens sit outside the site shell - a focused, chrome-free
      // flow - but inside a church: the account is global, the
      // membership and the role are not.
      GoRoute(
        path: '/c/:churchId/sign-in',
        builder: (_, state) => ChurchScope(
          churchId: state.pathParameters['churchId'],
          child: const SignInScreen(),
        ),
      ),
      GoRoute(
        path: '/c/:churchId/sign-up',
        builder: (_, state) => ChurchScope(
          churchId: state.pathParameters['churchId'],
          child: const SignUpScreen(),
        ),
      ),
      GoRoute(
        path: '/c/:churchId/forgot-password',
        builder: (_, state) => ChurchScope(
          churchId: state.pathParameters['churchId'],
          child: const ForgotPasswordScreen(),
        ),
      ),
      ShellRoute(
        // Reading the church off the location rather than the path
        // parameters: a ShellRoute's state describes the shell, and the
        // parameter belongs to the child match below it.
        builder: (context, state, child) => ChurchScope(
          churchId: churchIdFromLocation(state.uri.path),
          child: AppShell(child: child),
        ),
        routes: [
          GoRoute(
            path: '/c/:churchId',
            builder: (_, _) => const HomeScreen(),
            routes: [
              GoRoute(path: 'sermons', builder: (_, _) => const SermonsScreen()),
              GoRoute(
                path: 'sermons/:id',
                builder: (_, state) => SermonDetailScreen(sermonId: state.pathParameters['id']!),
              ),
              GoRoute(path: 'events', builder: (_, _) => const EventsScreen()),
              GoRoute(path: 'give', builder: (_, _) => const GivingScreen()),
              GoRoute(path: 'connect', builder: (_, _) => const ConnectScreen()),
              GoRoute(path: 'about', builder: (_, _) => const AboutScreen()),
              GoRoute(path: 'visit', builder: (_, _) => const VisitScreen()),
              GoRoute(path: 'download', builder: (_, _) => const DownloadScreen()),
              GoRoute(path: 'devotionals', builder: (_, _) => const DevotionalsScreen()),
              GoRoute(
                path: 'devotionals/:id',
                builder: (_, state) => DevotionalDetailScreen(devotionalId: state.pathParameters['id']!),
              ),
              GoRoute(path: 'resources', builder: (_, _) => const ResourcesScreen()),
              GoRoute(path: 'forms', builder: (_, _) => const FormsScreen()),
              GoRoute(
                path: 'forms/:slug',
                builder: (_, state) => FormDetailScreen(slug: state.pathParameters['slug']!),
              ),
              GoRoute(path: 'reading-plans', builder: (_, _) => const ReadingPlansScreen()),
              GoRoute(
                path: 'reading-plans/:id',
                builder: (_, state) => ReadingPlanDetailScreen(planId: state.pathParameters['id']!),
              ),

              GoRoute(path: 'account', builder: (_, _) => const AccountHomeScreen()),
              GoRoute(path: 'account/profile', builder: (_, _) => const ProfileScreen()),
              GoRoute(path: 'account/groups', builder: (_, _) => const MyGroupsScreen()),
              GoRoute(path: 'account/events', builder: (_, _) => const MyEventsScreen()),
              GoRoute(path: 'account/volunteering', builder: (_, _) => const MyVolunteeringScreen()),
              GoRoute(path: 'account/directory', builder: (_, _) => const DirectoryScreen()),
              GoRoute(path: 'account/giving', builder: (_, _) => const GivingHistoryScreen()),
              GoRoute(path: 'account/reading', builder: (_, _) => const MyReadingScreen()),
              GoRoute(path: 'account/notes', builder: (_, _) => const MyNotesScreen()),
              GoRoute(path: 'account/prayer', builder: (_, _) => const PrayerWallScreen()),
              GoRoute(path: 'account/bookings', builder: (_, _) => const MyBookingsScreen()),
              GoRoute(path: 'account/kids', builder: (_, _) => const MyKidsScreen()),
              GoRoute(path: 'account/notifications', builder: (_, _) => const NotificationsScreen()),

              GoRoute(path: 'admin', builder: (_, _) => const AdminHomeScreen()),
              GoRoute(path: 'admin/sermons', builder: (_, _) => const SermonsAdminScreen()),
              GoRoute(path: 'admin/events', builder: (_, _) => const EventsAdminScreen()),
              GoRoute(path: 'admin/groups', builder: (_, _) => const GroupsAdminScreen()),
              GoRoute(path: 'admin/volunteering', builder: (_, _) => const VolunteeringAdminScreen()),
              GoRoute(path: 'admin/connect', builder: (_, _) => const ConnectAdminScreen()),
              GoRoute(path: 'admin/announcements', builder: (_, _) => const AnnouncementsAdminScreen()),
              GoRoute(path: 'admin/devotionals', builder: (_, _) => const DevotionalsAdminScreen()),
              GoRoute(path: 'admin/reading-plans', builder: (_, _) => const ReadingPlansAdminScreen()),
              GoRoute(path: 'admin/resources', builder: (_, _) => const ResourcesAdminScreen()),
              GoRoute(path: 'admin/prayer', builder: (_, _) => const PrayerAdminScreen()),
              GoRoute(path: 'admin/rooms', builder: (_, _) => const RoomsAdminScreen()),
              GoRoute(path: 'admin/kids', builder: (_, _) => const KidsAdminScreen()),
              GoRoute(path: 'admin/attendance', builder: (_, _) => const AttendanceAdminScreen()),
              GoRoute(path: 'admin/forms', builder: (_, _) => const FormsAdminScreen()),
              GoRoute(
                path: 'admin/forms/:id',
                builder: (_, state) => FormBuilderScreen(formId: state.pathParameters['id']!),
              ),
              GoRoute(
                path: 'admin/forms/:id/responses',
                builder: (_, state) => FormResponsesScreen(formId: state.pathParameters['id']!),
              ),
              GoRoute(path: 'admin/reports', builder: (_, _) => const ReportsAdminScreen()),
              GoRoute(path: 'admin/members', builder: (_, _) => const MembersAdminScreen()),
              GoRoute(path: 'admin/settings', builder: (_, _) => const SettingsAdminScreen()),
              GoRoute(path: 'admin/audit', builder: (_, _) => const AuditAdminScreen()),
            ],
          ),
        ],
      ),
    ],
  );
});

/// Re-runs the router's redirect whenever the signed-in user changes.
///
/// This is the only notification the guard gets, so the guard has to be
/// able to answer correctly from inside it - which is why it reads
/// [authStateProvider] rather than anything derived from it. See the
/// redirect above.
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
