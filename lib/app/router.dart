import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/widgets/app_shell.dart';
import '../core/widgets/section_container.dart';
import '../features/church_info/presentation/about_screen.dart';
import '../features/church_info/presentation/visit_screen.dart';
import '../features/connect/presentation/connect_screen.dart';
import '../features/events/presentation/events_screen.dart';
import '../features/giving/presentation/giving_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/sermons/presentation/sermon_detail_screen.dart';
import '../features/sermons/presentation/sermons_screen.dart';

/// All routes are registered unconditionally.
///
/// The previous architecture registered different route sets depending on
/// a compile-time flag, which meant one build could not serve both modes
/// and deep links silently 404'd. Access is now decided by redirects at
/// request time instead.
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    errorBuilder: (context, state) => AppShell(child: _NotFound(location: state.uri.toString())),
    routes: [
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
        ],
      ),
    ],
  );
});

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
              Text(
                "We couldn't find $location.",
                style: const TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 24),
              ElevatedButton(onPressed: () => context.go('/'), child: const Text('Back home')),
            ],
          ),
        ),
      ],
    );
  }
}
