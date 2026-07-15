import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/church_config.dart';
import '../models/sermon.dart';
import '../state/site_controller.dart';
import '../utils/launch_helper.dart';
import '../widgets/responsive.dart';
import '../widgets/section_header.dart';
import '../widgets/site_footer.dart';

class SermonsScreen extends StatefulWidget {
  const SermonsScreen({super.key});

  @override
  State<SermonsScreen> createState() => _SermonsScreenState();
}

class _SermonsScreenState extends State<SermonsScreen> {
  String _query = '';
  String _series = 'All';

  @override
  Widget build(BuildContext context) {
    final site = context.watch<SiteController>();
    final config = site.config;
    final theme = Theme.of(context);

    final seriesOptions = <String>{
      'All',
      ...site.sermons.map((s) => s.series).where((s) => s.isNotEmpty),
    }.toList();

    var sermons = site.sermonsByNewest;
    if (_series != 'All') {
      sermons = sermons.where((s) => s.series == _series).toList();
    }
    if (_query.isNotEmpty) {
      final q = _query.toLowerCase();
      sermons = sermons
          .where((s) =>
              s.title.toLowerCase().contains(q) ||
              s.speaker.toLowerCase().contains(q) ||
              s.scripture.toLowerCase().contains(q))
          .toList();
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          ContentContainer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeader(
                  eyebrow: 'Messages',
                  title: 'Sermons & teaching',
                  subtitle:
                      'Catch up on recent messages or explore past series.',
                ),
                if (config.showLiveStream &&
                    config.liveStreamUrl.trim().isNotEmpty) ...[
                  const SizedBox(height: 24),
                  _LiveBanner(config: config),
                ],
                const SizedBox(height: 24),
                TextField(
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'Search messages…',
                  ),
                  onChanged: (v) => setState(() => _query = v),
                ),
                if (seriesOptions.length > 1) ...[
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final s in seriesOptions)
                        ChoiceChip(
                          label: Text(s),
                          selected: _series == s,
                          onSelected: (_) => setState(() => _series = s),
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: 24),
                if (sermons.isEmpty)
                  _EmptyState(theme: theme)
                else
                  GridView.count(
                    crossAxisCount: Responsive.gridColumns(context,
                        mobile: 1, tablet: 2, desktop: 3),
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio:
                        Responsive.isMobile(context) ? 1.5 : 1.05,
                    children: [
                      for (final sermon in sermons)
                        _SermonCard(sermon: sermon),
                    ],
                  ),
              ],
            ),
          ),
          SiteFooter(config: config),
        ],
      ),
    );
  }
}

class _LiveBanner extends StatelessWidget {
  final ChurchConfig config;

  const _LiveBanner({required this.config});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: () => openUrl(context, config.liveStreamUrl),
      borderRadius: BorderRadius.circular(config.cornerRadius),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(config.cornerRadius),
        ),
        child: Row(
          children: [
            Icon(Icons.sensors,
                color: theme.colorScheme.onErrorContainer, size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Watch Live',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onErrorContainer,
                        fontWeight: FontWeight.w700,
                      )),
                  Text('Join our live stream',
                      style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onErrorContainer)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward,
                color: theme.colorScheme.onErrorContainer),
          ],
        ),
      ),
    );
  }
}

class _SermonCard extends StatelessWidget {
  final Sermon sermon;

  const _SermonCard({required this.sermon});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: InkWell(
        onTap: sermon.mediaUrl.trim().isNotEmpty
            ? () => openUrl(context, sermon.mediaUrl)
            : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (sermon.imageUrl.trim().isNotEmpty)
                    Image.network(sermon.imageUrl.trim(), fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            _placeholder(theme))
                  else
                    _placeholder(theme),
                  Center(
                    child: CircleAvatar(
                      backgroundColor: Colors.black.withOpacity(0.5),
                      child: const Icon(Icons.play_arrow,
                          color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (sermon.series.isNotEmpty)
                    Text(sermon.series.toUpperCase(),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.1,
                        )),
                  const SizedBox(height: 4),
                  Text(sermon.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(
                    '${sermon.speaker} · ${DateFormat('MMM d, yyyy').format(sermon.date)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant),
                  ),
                  if (sermon.scripture.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.menu_book,
                            size: 14,
                            color: theme.colorScheme.onSurfaceVariant),
                        const SizedBox(width: 6),
                        Text(sermon.scripture,
                            style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant)),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder(ThemeData theme) {
    return Container(
      color: theme.colorScheme.primaryContainer,
      child: Icon(Icons.church,
          size: 48, color: theme.colorScheme.onPrimaryContainer.withOpacity(0.5)),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final ThemeData theme;

  const _EmptyState({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.search_off,
                size: 48, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 12),
            Text('No messages found',
                style: theme.textTheme.titleMedium),
          ],
        ),
      ),
    );
  }
}
