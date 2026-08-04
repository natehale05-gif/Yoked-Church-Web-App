import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/config/settings_providers.dart';
import '../../../core/widgets/async_value_widget.dart';
import '../../../core/widgets/app_shell.dart';
import '../../../core/widgets/section_container.dart';
import '../application/sermon_providers.dart';
import '../domain/sermon.dart';

class SermonsScreen extends ConsumerWidget {
  const SermonsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final liveUrl = settings.social.liveStreamUrl;
    final podcastUrl = settings.social.podcastUrl;

    final onWhite = OutlinedButton.styleFrom(
      foregroundColor: Colors.white,
      side: const BorderSide(color: Colors.white70),
    );

    return PageBody(
      children: [
        PageBanner(
          title: 'Sermons',
          subtitle: 'Catch up on past messages, or watch online.',
          action: (liveUrl.isEmpty && podcastUrl.isEmpty)
              ? null
              : Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    // "Watch Online", for the same reason the home page
                    // says it: this link is to wherever the church
                    // streams, which is there whether or not anything is
                    // happening. The home page's banner is what says
                    // "live", and only when it is true.
                    if (liveUrl.isNotEmpty)
                      OutlinedButton.icon(
                        onPressed: () => launchUrl(Uri.parse(liveUrl), webOnlyWindowName: '_blank'),
                        icon: const Icon(Icons.live_tv, color: Colors.white),
                        label: const Text('Watch Online'),
                        style: onWhite,
                      ),
                    if (podcastUrl.isNotEmpty)
                      OutlinedButton.icon(
                        onPressed: () => launchUrl(Uri.parse(podcastUrl), webOnlyWindowName: '_blank'),
                        icon: const Icon(Icons.podcasts, color: Colors.white),
                        label: const Text('Listen on your podcast app'),
                        style: onWhite,
                      ),
                  ],
                ),
        ),
        SectionContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SermonFilters(),
              const SizedBox(height: 28),
              AsyncListWidget<Sermon>(
                value: ref.watch(filteredSermonsProvider),
                errorContext: 'sermons',
                emptyMessage: 'No sermons match your search yet.',
                data: (sermons) => Wrap(
                  spacing: 24,
                  runSpacing: 24,
                  children: [for (final sermon in sermons) SermonCard(sermon: sermon)],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SermonFilters extends ConsumerStatefulWidget {
  const _SermonFilters();

  @override
  ConsumerState<_SermonFilters> createState() => _SermonFiltersState();
}

class _SermonFiltersState extends ConsumerState<_SermonFilters> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: ref.read(sermonSearchQueryProvider));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final seriesAsync = ref.watch(sermonSeriesProvider);
    final activeSeries = ref.watch(sermonSeriesFilterProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _controller,
          onChanged: (value) => ref.read(sermonSearchQueryProvider.notifier).state = value,
          decoration: InputDecoration(
            hintText: 'Search by title, speaker, series, or scripture',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _controller.text.isEmpty
                ? null
                : IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _controller.clear();
                      ref.read(sermonSearchQueryProvider.notifier).state = '';
                    },
                  ),
          ),
        ),
        const SizedBox(height: 16),
        seriesAsync.maybeWhen(
          data: (seriesList) => seriesList.isEmpty
              ? const SizedBox.shrink()
              : Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilterChip(
                      label: const Text('All series'),
                      selected: activeSeries == null,
                      onSelected: (_) => ref.read(sermonSeriesFilterProvider.notifier).state = null,
                    ),
                    for (final series in seriesList)
                      FilterChip(
                        label: Text(series.name),
                        selected: activeSeries == series.id,
                        onSelected: (selected) =>
                            ref.read(sermonSeriesFilterProvider.notifier).state = selected ? series.id : null,
                      ),
                  ],
                ),
          orElse: () => const SizedBox.shrink(),
        ),
      ],
    );
  }
}

class SermonCard extends ConsumerWidget {
  final Sermon sermon;

  const SermonCard({super.key, required this.sermon});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brand = ref.watch(settingsProvider).colors;

    return SizedBox(
      width: 320,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.go('/sermons/${sermon.id}'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: 16 / 9,
                child: sermon.thumbnailUrl.isNotEmpty
                    ? Image.network(
                        sermon.thumbnailUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => _Placeholder(color: brand.primary),
                      )
                    : _Placeholder(color: brand.primary),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (sermon.seriesName.isNotEmpty)
                      Text(
                        sermon.seriesName.toUpperCase(),
                        style: TextStyle(
                          color: brand.accent,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                        ),
                      ),
                    const SizedBox(height: 6),
                    Text(sermon.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
                    const SizedBox(height: 6),
                    Text(
                      '${sermon.speaker} · ${DateFormat.yMMMd().format(sermon.date)}',
                      style: const TextStyle(color: Colors.black54, fontSize: 13),
                    ),
                    if (sermon.scripture.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(sermon.scripture, style: const TextStyle(color: Colors.black45, fontSize: 13)),
                    ],
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

class _Placeholder extends StatelessWidget {
  final Color color;

  const _Placeholder({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: color.withValues(alpha: 0.1),
      child: Icon(Icons.play_circle_fill, size: 48, color: color.withValues(alpha: 0.5)),
    );
  }
}
