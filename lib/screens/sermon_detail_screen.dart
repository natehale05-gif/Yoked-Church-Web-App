import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/church_config.dart';
import '../models/sermon.dart';
import '../services/sermon_service.dart';
import '../widgets/section_container.dart';

class SermonDetailScreen extends StatefulWidget {
  final String sermonId;
  final Sermon? initialSermon;

  const SermonDetailScreen({super.key, required this.sermonId, this.initialSermon});

  @override
  State<SermonDetailScreen> createState() => _SermonDetailScreenState();
}

class _SermonDetailScreenState extends State<SermonDetailScreen> {
  late Future<Sermon?> _sermonFuture;

  @override
  void initState() {
    super.initState();
    _sermonFuture = widget.initialSermon != null
        ? Future.value(widget.initialSermon)
        : const SermonService().fetchSermons().then((sermons) {
            for (final sermon in sermons) {
              if (sermon.id == widget.sermonId) return sermon;
            }
            return null;
          });
  }

  @override
  Widget build(BuildContext context) {
    return SectionContainer(
      maxWidth: 800,
      child: FutureBuilder<Sermon?>(
        future: _sermonFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 80),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final sermon = snapshot.data;
          if (sermon == null) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 80),
              child: Center(child: Text('Sermon not found.')),
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextButton.icon(
                onPressed: () => context.go('/sermons'),
                icon: const Icon(Icons.arrow_back),
                label: const Text('All sermons'),
              ),
              const SizedBox(height: 12),
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Container(
                  decoration: BoxDecoration(
                    color: ChurchConfig.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: ElevatedButton.icon(
                      onPressed: () => launchUrl(Uri.parse(sermon.videoUrl), webOnlyWindowName: '_blank'),
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Watch Sermon'),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(sermon.series.toUpperCase(),
                  style: TextStyle(color: ChurchConfig.accentColor, fontWeight: FontWeight.w700, letterSpacing: 1)),
              const SizedBox(height: 8),
              Text(sermon.title, style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 8),
              Text('${sermon.speaker} · ${DateFormat.yMMMMd().format(sermon.date)}',
                  style: const TextStyle(color: Colors.black54)),
              const SizedBox(height: 20),
              Text(sermon.description, style: const TextStyle(fontSize: 16, height: 1.6)),
            ],
          );
        },
      ),
    );
  }
}
