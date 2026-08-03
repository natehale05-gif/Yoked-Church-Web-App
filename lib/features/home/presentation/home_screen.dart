import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/theme.dart';
import '../../../core/config/church_settings.dart';
import '../../../core/config/settings_providers.dart';
import '../../../core/widgets/app_shell.dart';
import '../../../core/widgets/section_container.dart';
import '../../devotionals/application/devotional_providers.dart';
import '../../events/application/event_providers.dart';
import '../../sermons/application/sermon_providers.dart';
import '../../sermons/presentation/sermons_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return PageBody(
      children: [
        _Hero(settings: settings),
        if (settings.serviceTimes.isNotEmpty) _ServiceTimes(settings: settings),
        const _QuickLinks(),
        if (settings.features.sermons) const _LatestSermons(),
        if (settings.features.devotionals) const _TodaysDevotional(),
        if (settings.features.events) const _UpcomingEvents(),
        _Welcome(settings: settings),
      ],
    );
  }
}

class _Hero extends StatelessWidget {
  final ChurchSettings settings;

  const _Hero({required this.settings});

  @override
  Widget build(BuildContext context) {
    final isMobile = Breakpoints.isMobile(context);
    final liveUrl = settings.social.liveStreamUrl;

    return Container(
      width: double.infinity,
      color: settings.colors.primary,
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 24 : 60, vertical: isMobile ? 64 : 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            settings.churchName,
            style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  color: Colors.white,
                  fontSize: isMobile ? 36 : 56,
                ),
          ),
          if (settings.tagline.isNotEmpty) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: isMobile ? double.infinity : 520,
              child: Text(
                settings.tagline,
                style: TextStyle(color: Colors.white70, fontSize: isMobile ? 16 : 20),
              ),
            ),
          ],
          const SizedBox(height: 32),
          Wrap(
            spacing: 16,
            runSpacing: 12,
            children: [
              ElevatedButton(onPressed: () => context.go('/visit'), child: const Text('Plan a Visit')),
              if (liveUrl.isNotEmpty)
                OutlinedButton(
                  onPressed: () => launchUrl(Uri.parse(liveUrl), webOnlyWindowName: '_blank'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white70),
                  ),
                  child: const Text('Watch Live'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ServiceTimes extends StatelessWidget {
  final ChurchSettings settings;

  const _ServiceTimes({required this.settings});

  @override
  Widget build(BuildContext context) {
    return SectionContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Join Us', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 24),
          Wrap(
            spacing: 20,
            runSpacing: 20,
            children: [
              for (final service in settings.serviceTimes)
                SizedBox(
                  width: 260,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(service.day, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                          const SizedBox(height: 4),
                          Text(
                            service.time,
                            style: TextStyle(
                              color: settings.colors.accent,
                              fontWeight: FontWeight.w700,
                              fontSize: 22,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(service.label, style: const TextStyle(color: Colors.black54)),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickLinks extends ConsumerWidget {
  const _QuickLinks();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final flags = settings.features;

    final links = <({IconData icon, String label, String path})>[
      if (flags.sermons) (icon: Icons.play_circle_outline, label: 'Sermons', path: '/sermons'),
      if (flags.events) (icon: Icons.event_outlined, label: 'Events', path: '/events'),
      if (flags.devotionals)
        (icon: Icons.auto_stories_outlined, label: 'Devotionals', path: '/devotionals'),
      if (flags.readingPlans)
        (icon: Icons.menu_book_outlined, label: 'Reading Plans', path: '/reading-plans'),
      if (flags.giving) (icon: Icons.favorite_outline, label: 'Give', path: '/give'),
      if (flags.connect) (icon: Icons.mail_outline, label: 'Connect', path: '/connect'),
    ];
    if (links.isEmpty) return const SizedBox.shrink();

    return SectionContainer(
      backgroundColor: Colors.white,
      child: Wrap(
        spacing: 24,
        runSpacing: 24,
        alignment: WrapAlignment.center,
        children: [
          for (final link in links)
            InkWell(
              onTap: () => context.go(link.path),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: 200,
                padding: const EdgeInsets.symmetric(vertical: 28),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    Icon(link.icon, size: 34, color: settings.colors.primary),
                    const SizedBox(height: 12),
                    Text(link.label, style: const TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _LatestSermons extends ConsumerWidget {
  const _LatestSermons();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sermons = ref.watch(publishedSermonsProvider).valueOrNull ?? const [];
    if (sermons.isEmpty) return const SizedBox.shrink();
    final latest = sermons.take(3).toList();

    return SectionContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text('Latest Messages', style: Theme.of(context).textTheme.headlineMedium)),
              TextButton(onPressed: () => context.go('/sermons'), child: const Text('View all')),
            ],
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 24,
            runSpacing: 24,
            children: [for (final sermon in latest) SermonCard(sermon: sermon)],
          ),
        ],
      ),
    );
  }
}

class _TodaysDevotional extends ConsumerWidget {
  const _TodaysDevotional();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final devotional = ref.watch(todaysDevotionalProvider).valueOrNull;
    if (devotional == null) return const SizedBox.shrink();
    final brand = ref.watch(settingsProvider).colors;
    final isMobile = Breakpoints.isMobile(context);

    return SectionContainer(
      backgroundColor: brand.primary.withValues(alpha: 0.05),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "TODAY'S DEVOTIONAL",
            style: TextStyle(color: brand.accent, fontWeight: FontWeight.w700, letterSpacing: 1.5, fontSize: 12),
          ),
          const SizedBox(height: 12),
          Text(
            devotional.title,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: isMobile ? 26 : 32),
          ),
          if (devotional.scripture.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              devotional.scripture,
              style: TextStyle(color: brand.primary, fontWeight: FontWeight.w600, fontSize: 16),
            ),
          ],
          const SizedBox(height: 16),
          Text(devotional.excerpt, style: const TextStyle(fontSize: 16, height: 1.7, color: Colors.black87)),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              ElevatedButton(
                onPressed: () => context.go('/devotionals/${devotional.id}'),
                child: const Text('Read today'),
              ),
              TextButton(onPressed: () => context.go('/devotionals'), child: const Text('All devotionals')),
            ],
          ),
        ],
      ),
    );
  }
}

class _UpcomingEvents extends ConsumerWidget {
  const _UpcomingEvents();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final events = ref.watch(upcomingEventsProvider).valueOrNull ?? const [];
    if (events.isEmpty) return const SizedBox.shrink();
    final next = events.take(3).toList();
    final brand = ref.watch(settingsProvider).colors;

    return SectionContainer(
      backgroundColor: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text("What's Coming Up", style: Theme.of(context).textTheme.headlineMedium)),
              TextButton(onPressed: () => context.go('/events'), child: const Text('View all')),
            ],
          ),
          const SizedBox(height: 20),
          for (final event in next)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: brand.primary.withValues(alpha: 0.08),
                child: Icon(Icons.event_outlined, color: brand.primary, size: 20),
              ),
              title: Text(event.title, style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(
                [
                  DateFormat.yMMMd().add_jm().format(event.start),
                  if (event.location.isNotEmpty) event.location,
                ].join(' · '),
              ),
              onTap: () => context.go('/events'),
            ),
        ],
      ),
    );
  }
}

class _Welcome extends StatelessWidget {
  final ChurchSettings settings;

  const _Welcome({required this.settings});

  @override
  Widget build(BuildContext context) {
    final isMobile = Breakpoints.isMobile(context);
    if (settings.aboutBody.isEmpty) return const SizedBox.shrink();

    return SectionContainer(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  settings.aboutHeadline.isEmpty ? 'Welcome' : settings.aboutHeadline,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 16),
                Text(settings.aboutBody, style: const TextStyle(fontSize: 16, height: 1.6, color: Colors.black87)),
                const SizedBox(height: 20),
                OutlinedButton(onPressed: () => context.go('/about'), child: const Text('More about us')),
              ],
            ),
          ),
          if (!isMobile) ...[
            const SizedBox(width: 40),
            Expanded(
              child: AspectRatio(
                aspectRatio: 4 / 3,
                child: Container(
                  decoration: BoxDecoration(
                    color: settings.colors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.church,
                    size: 72,
                    color: settings.colors.primary.withValues(alpha: 0.4),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
