import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/config/settings_providers.dart';
import '../../../core/widgets/app_shell.dart';
import '../../../core/widgets/async_value_widget.dart';
import '../../../core/widgets/section_container.dart';
import '../application/sermon_providers.dart';
import '../domain/sermon.dart';

class SermonDetailScreen extends ConsumerWidget {
  final String sermonId;

  const SermonDetailScreen({super.key, required this.sermonId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PageBody(
      children: [
        SectionContainer(
          maxWidth: 820,
          child: AsyncValueWidget<Sermon?>(
            value: ref.watch(sermonByIdProvider(sermonId)),
            errorContext: 'this sermon',
            data: (sermon) => sermon == null
                ? const EmptyState(message: 'Sermon not found.')
                : _SermonBody(sermon: sermon),
          ),
        ),
      ],
    );
  }
}

class _SermonBody extends ConsumerWidget {
  final Sermon sermon;

  const _SermonBody({required this.sermon});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brand = ref.watch(settingsProvider).colors;

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
              color: brand.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  if (sermon.videoUrl.isNotEmpty)
                    ElevatedButton.icon(
                      onPressed: () => launchUrl(Uri.parse(sermon.videoUrl), webOnlyWindowName: '_blank'),
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Watch Sermon'),
                    ),
                  if (sermon.audioUrl.isNotEmpty)
                    OutlinedButton.icon(
                      onPressed: () => launchUrl(Uri.parse(sermon.audioUrl), webOnlyWindowName: '_blank'),
                      icon: const Icon(Icons.headphones),
                      label: const Text('Listen'),
                    ),
                  if (sermon.videoUrl.isEmpty && sermon.audioUrl.isEmpty)
                    const Text('Media coming soon.', style: TextStyle(color: Colors.black45)),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        if (sermon.seriesName.isNotEmpty)
          Text(
            sermon.seriesName.toUpperCase(),
            style: TextStyle(color: brand.accent, fontWeight: FontWeight.w700, letterSpacing: 1),
          ),
        const SizedBox(height: 8),
        Text(sermon.title, style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 8),
        Text(
          '${sermon.speaker} · ${DateFormat.yMMMMd().format(sermon.date)}',
          style: const TextStyle(color: Colors.black54),
        ),
        if (sermon.scripture.isNotEmpty) ...[
          const SizedBox(height: 12),
          Chip(
            avatar: const Icon(Icons.menu_book_outlined, size: 18),
            label: Text(sermon.scripture),
          ),
        ],
        if (sermon.description.isNotEmpty) ...[
          const SizedBox(height: 20),
          Text(sermon.description, style: const TextStyle(fontSize: 16, height: 1.6)),
        ],
        if (sermon.notes.isNotEmpty) ...[
          const SizedBox(height: 32),
          Text('Sermon Notes', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(sermon.notes, style: const TextStyle(fontSize: 15, height: 1.7)),
            ),
          ),
        ],
      ],
    );
  }
}
