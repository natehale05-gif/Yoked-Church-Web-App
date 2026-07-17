import 'package:go_router/go_router.dart';

import '../models/sermon.dart';
import '../screens/connect_screen.dart';
import '../screens/events_screen.dart';
import '../screens/giving_screen.dart';
import '../screens/home_screen.dart';
import '../screens/sermon_detail_screen.dart';
import '../screens/sermons_screen.dart';
import '../widgets/app_shell.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
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
      ],
    ),
  ],
);
