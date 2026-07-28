import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/config/settings_providers.dart';
import '../../../core/widgets/app_shell.dart';
import '../../../core/widgets/async_value_widget.dart';
import '../../../core/widgets/section_container.dart';
import '../../auth/application/auth_providers.dart';
import '../application/resource_providers.dart';
import '../domain/resource.dart';

IconData iconForKind(ResourceKind kind) => switch (kind) {
      ResourceKind.pdf => Icons.picture_as_pdf_outlined,
      ResourceKind.document => Icons.description_outlined,
      ResourceKind.sheet => Icons.table_chart_outlined,
      ResourceKind.audio => Icons.headphones_outlined,
      ResourceKind.video => Icons.play_circle_outline,
      ResourceKind.link => Icons.link,
    };

class ResourcesScreen extends ConsumerStatefulWidget {
  const ResourcesScreen({super.key});

  @override
  ConsumerState<ResourcesScreen> createState() => _ResourcesScreenState();
}

class _ResourcesScreenState extends ConsumerState<ResourcesScreen> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(resourceCategoriesProvider);
    final selected = ref.watch(resourceCategoryFilterProvider);
    final signedIn = ref.watch(isSignedInProvider);

    return PageBody(
      children: [
        const PageBanner(
          eyebrow: 'Grow',
          title: 'Resources',
          subtitle: 'Study guides, forms, and things worth passing along.',
        ),
        SectionContainer(
          maxWidth: 900,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _search,
                onChanged: (value) => ref.read(resourceSearchQueryProvider.notifier).state = value,
                decoration: const InputDecoration(
                  hintText: 'Search resources',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
              if (categories.isNotEmpty) ...[
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('All'),
                      selected: selected == null,
                      onSelected: (_) => ref.read(resourceCategoryFilterProvider.notifier).state = null,
                    ),
                    for (final category in categories)
                      ChoiceChip(
                        label: Text(category),
                        selected: selected == category,
                        onSelected: (_) =>
                            ref.read(resourceCategoryFilterProvider.notifier).state = category,
                      ),
                  ],
                ),
              ],
              if (!signedIn) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Icons.lock_outline, size: 16, color: Colors.black45),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Some resources are for members. Sign in to see everything.',
                        style: TextStyle(color: Colors.black54, fontSize: 13),
                      ),
                    ),
                    TextButton(onPressed: () => context.go('/sign-in'), child: const Text('Sign in')),
                  ],
                ),
              ],
              const SizedBox(height: 24),
              AsyncListWidget<Resource>(
                value: ref.watch(filteredResourcesProvider),
                errorContext: 'resources',
                emptyMessage: 'Nothing here yet. Check back soon.',
                data: (items) => Column(
                  children: [for (final item in items) ResourceRow(resource: item)],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class ResourceRow extends ConsumerWidget {
  final Resource resource;

  const ResourceRow({super.key, required this.resource});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brand = ref.watch(settingsProvider).colors;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        leading: CircleAvatar(
          backgroundColor: brand.primary.withValues(alpha: 0.1),
          child: Icon(iconForKind(resource.kind), color: brand.primary, size: 20),
        ),
        title: Text(resource.title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (resource.description.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(resource.description, style: const TextStyle(height: 1.5)),
              ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              children: [
                if (resource.category.isNotEmpty)
                  Chip(
                    label: Text(resource.category),
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                  ),
                if (resource.membersOnly)
                  Chip(
                    avatar: const Icon(Icons.lock_outline, size: 14),
                    label: const Text('Members'),
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                  ),
              ],
            ),
          ],
        ),
        trailing: IconButton(
          tooltip: 'Open',
          icon: const Icon(Icons.open_in_new),
          onPressed: resource.url.isEmpty
              ? null
              : () => launchUrl(Uri.parse(resource.url), webOnlyWindowName: '_blank'),
        ),
      ),
    );
  }
}
