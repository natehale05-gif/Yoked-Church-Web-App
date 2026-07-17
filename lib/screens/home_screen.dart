import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/church_config.dart';
import '../theme/app_theme.dart';
import '../widgets/section_container.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _Hero(),
        SectionContainer(child: _ServiceTimes(context: context)),
        SectionContainer(
          backgroundColor: Colors.white,
          child: _QuickLinks(),
        ),
        SectionContainer(child: _Welcome()),
      ],
    );
  }
}

class _Hero extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isMobile = Breakpoints.isMobile(context);
    return Container(
      width: double.infinity,
      color: ChurchConfig.primaryColor,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 24 : 60,
        vertical: isMobile ? 64 : 120,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            ChurchConfig.churchName,
            style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  color: Colors.white,
                  fontSize: isMobile ? 36 : 56,
                ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: isMobile ? double.infinity : 520,
            child: Text(
              ChurchConfig.tagline,
              style: TextStyle(color: Colors.white70, fontSize: isMobile ? 16 : 20),
            ),
          ),
          const SizedBox(height: 32),
          Wrap(
            spacing: 16,
            runSpacing: 12,
            children: [
              ElevatedButton(
                onPressed: () => context.go('/events'),
                child: const Text('Plan a Visit'),
              ),
              OutlinedButton(
                onPressed: () => launchUrl(Uri.parse(ChurchConfig.liveStreamUrl), webOnlyWindowName: '_blank'),
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
  final BuildContext context;

  const _ServiceTimes({required this.context});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Join Us', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 24),
        Wrap(
          spacing: 20,
          runSpacing: 20,
          children: ChurchConfig.serviceTimes
              .map(
                (service) => SizedBox(
                  width: 260,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(service.day, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                          const SizedBox(height: 4),
                          Text(service.time,
                              style: TextStyle(color: ChurchConfig.accentColor, fontWeight: FontWeight.w700, fontSize: 22)),
                          const SizedBox(height: 8),
                          Text(service.label, style: const TextStyle(color: Colors.black54)),
                        ],
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

class _QuickLinks extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final links = <_QuickLinkData>[
      if (ChurchConfig.showSermons)
        _QuickLinkData(icon: Icons.play_circle_outline, label: 'Sermons', path: '/sermons'),
      if (ChurchConfig.showEvents)
        _QuickLinkData(icon: Icons.event_outlined, label: 'Events', path: '/events'),
      if (ChurchConfig.showGiving)
        _QuickLinkData(icon: Icons.favorite_outline, label: 'Give', path: '/give'),
      if (ChurchConfig.showConnect)
        _QuickLinkData(icon: Icons.mail_outline, label: 'Connect', path: '/connect'),
    ];

    return Wrap(
      spacing: 24,
      runSpacing: 24,
      alignment: WrapAlignment.center,
      children: links
          .map(
            (link) => InkWell(
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
                    Icon(link.icon, size: 34, color: ChurchConfig.primaryColor),
                    const SizedBox(height: 12),
                    Text(link.label, style: const TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _QuickLinkData {
  final IconData icon;
  final String label;
  final String path;

  _QuickLinkData({required this.icon, required this.label, required this.path});
}

class _Welcome extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isMobile = Breakpoints.isMobile(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Welcome Home', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 16),
              const Text(
                'Whoever you are and wherever you are on your journey, there\'s a place '
                'for you here. We\'re a community learning to walk yoked with Christ - '
                'together, unhurried, and free.',
                style: TextStyle(fontSize: 16, height: 1.6, color: Colors.black87),
              ),
              const SizedBox(height: 24),
              Text(ChurchConfig.address, style: const TextStyle(color: Colors.black54)),
              Text('${ChurchConfig.phone} · ${ChurchConfig.email}', style: const TextStyle(color: Colors.black54)),
            ],
          ),
        ),
        if (!isMobile) const SizedBox(width: 40),
        if (!isMobile)
          Expanded(
            child: AspectRatio(
              aspectRatio: 4 / 3,
              child: Container(
                decoration: BoxDecoration(
                  color: ChurchConfig.primaryColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.church, size: 72, color: ChurchConfig.primaryColor.withValues(alpha: 0.4)),
              ),
            ),
          ),
      ],
    );
  }
}
