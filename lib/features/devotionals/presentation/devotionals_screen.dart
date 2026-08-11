import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/config/settings_providers.dart';
import '../../../core/widgets/app_shell.dart';
import '../../../core/widgets/async_value_widget.dart';
import '../../../core/widgets/section_container.dart';
import '../application/devotional_providers.dart';
import '../domain/devotional.dart';

class DevotionalsScreen extends ConsumerStatefulWidget {
  const DevotionalsScreen({super.key});

  @override
  ConsumerState<DevotionalsScreen> createState() => _DevotionalsScreenState();
}

class _DevotionalsScreenState extends ConsumerState<DevotionalsScreen> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PageBody(
      children: [
        const PageBanner(
          eyebrow: 'Daily',
          title: 'Devotionals',
          subtitle: 'A few minutes in the Word, written by our team.',
        ),
        SectionContainer(
          maxWidth: 820,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _search,
                onChanged: (value) => ref.read(devotionalSearchQueryProvider.notifier).state = value,
                decoration: const InputDecoration(
                  hintText: 'Search devotionals',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
              const SizedBox(height: 24),
              AsyncListWidget<Devotional>(
                value: ref.watch(filteredDevotionalsProvider),
                errorContext: 'devotionals',
                emptyMessage: 'No devotionals yet. Check back soon.',
                data: (items) => Column(
                  children: [for (final item in items) DevotionalCard(devotional: item)],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class DevotionalCard extends ConsumerWidget {
  final Devotional devotional;

  const DevotionalCard({super.key, required this.devotional});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brand = ref.watch(settingsProvider).colors;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => context.go('/devotionals/${devotional.id}'),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                DateFormat.yMMMMd().format(devotional.publishDate).toUpperCase(),
                style: TextStyle(color: brand.accentInk, fontWeight: FontWeight.w700, letterSpacing: 1, fontSize: 12),
              ),
              const SizedBox(height: 8),
              Text(devotional.title, style: Theme.of(context).textTheme.titleLarge),
              if (devotional.scripture.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(devotional.scripture, style: TextStyle(color: brand.primary, fontWeight: FontWeight.w600)),
              ],
              const SizedBox(height: 12),
              Text(devotional.excerpt, style: const TextStyle(height: 1.6, color: Colors.black87)),
              if (devotional.author.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text('By ${devotional.author}', style: const TextStyle(color: Colors.black54, fontSize: 13)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
