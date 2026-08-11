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

class DevotionalDetailScreen extends ConsumerWidget {
  final String devotionalId;

  const DevotionalDetailScreen({super.key, required this.devotionalId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PageBody(
      children: [
        SectionContainer(
          maxWidth: 720,
          child: AsyncValueWidget<Devotional?>(
            value: ref.watch(devotionalByIdProvider(devotionalId)),
            errorContext: 'this devotional',
            // A draft or a future-dated entry must not be reachable just
            // because someone has the link.
            data: (devotional) => devotional == null || !devotional.isLiveAt(DateTime.now())
                ? const EmptyState(message: 'Devotional not found.')
                : _DevotionalBody(devotional: devotional),
          ),
        ),
      ],
    );
  }
}

class _DevotionalBody extends ConsumerWidget {
  final Devotional devotional;

  const _DevotionalBody({required this.devotional});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brand = ref.watch(settingsProvider).colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextButton.icon(
          onPressed: () => context.go('/devotionals'),
          icon: const Icon(Icons.arrow_back),
          label: const Text('All devotionals'),
        ),
        const SizedBox(height: 16),
        Text(
          DateFormat.yMMMMd().format(devotional.publishDate).toUpperCase(),
          style: TextStyle(color: brand.accentInk, fontWeight: FontWeight.w700, letterSpacing: 1, fontSize: 12),
        ),
        const SizedBox(height: 10),
        Text(devotional.title, style: Theme.of(context).textTheme.headlineMedium),
        if (devotional.author.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text('By ${devotional.author}', style: const TextStyle(color: Colors.black54)),
        ],
        if (devotional.scripture.isNotEmpty) ...[
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: brand.primary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border(left: BorderSide(color: brand.accent, width: 4)),
            ),
            child: Row(
              children: [
                Icon(Icons.menu_book_outlined, size: 20, color: brand.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    devotional.scripture,
                    style: TextStyle(color: brand.primary, fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 28),
        Text(devotional.body, style: const TextStyle(fontSize: 16, height: 1.8)),
      ],
    );
  }
}
