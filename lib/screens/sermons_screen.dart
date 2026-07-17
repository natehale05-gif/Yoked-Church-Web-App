import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/church_config.dart';
import '../models/sermon.dart';
import '../services/sermon_service.dart';
import '../theme/app_theme.dart';
import '../widgets/section_container.dart';

class SermonsScreen extends StatefulWidget {
  const SermonsScreen({super.key});

  @override
  State<SermonsScreen> createState() => _SermonsScreenState();
}

class _SermonsScreenState extends State<SermonsScreen> {
  final SermonService _service = const SermonService();
  late final Future<List<Sermon>> _sermonsFuture;

  @override
  void initState() {
    super.initState();
    _sermonsFuture = _service.fetchSermons();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Breakpoints.isMobile(context);

    return Column(
      children: [
        Container(
          width: double.infinity,
          color: ChurchConfig.primaryColor,
          padding: EdgeInsets.symmetric(horizontal: isMobile ? 24 : 60, vertical: isMobile ? 48 : 72),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Sermons', style: Theme.of(context).textTheme.displayMedium?.copyWith(color: Colors.white)),
              const SizedBox(height: 12),
              const Text('Catch up on past messages or watch this week live.',
                  style: TextStyle(color: Colors.white70, fontSize: 16)),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: () => launchUrl(Uri.parse(ChurchConfig.liveStreamUrl), webOnlyWindowName: '_blank'),
                icon: const Icon(Icons.live_tv, color: Colors.white),
                label: const Text('Watch Live'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white70),
                ),
              ),
            ],
          ),
        ),
        SectionContainer(
          child: FutureBuilder<List<Sermon>>(
            future: _sermonsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 60),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (snapshot.hasError) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 60),
                  child: Center(child: Text('Could not load sermons: ${snapshot.error}')),
                );
              }
              final sermons = snapshot.data ?? [];
              if (sermons.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 60),
                  child: Center(child: Text('No sermons yet - check back soon.')),
                );
              }
              return Wrap(
                spacing: 24,
                runSpacing: 24,
                children: sermons.map((sermon) => _SermonCard(sermon: sermon)).toList(),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SermonCard extends StatelessWidget {
  final Sermon sermon;

  const _SermonCard({required this.sermon});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 320,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.go('/sermons/${sermon.id}', extra: sermon),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Container(
                  color: ChurchConfig.primaryColor.withValues(alpha: 0.1),
                  child: Icon(Icons.play_circle_fill, size: 48, color: ChurchConfig.primaryColor.withValues(alpha: 0.5)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(sermon.series.toUpperCase(),
                        style: TextStyle(color: ChurchConfig.accentColor, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1)),
                    const SizedBox(height: 6),
                    Text(sermon.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
                    const SizedBox(height: 6),
                    Text('${sermon.speaker} · ${DateFormat.yMMMd().format(sermon.date)}',
                        style: const TextStyle(color: Colors.black54, fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
