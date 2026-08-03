import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/tenant.dart';
import '../application/church_providers.dart';
import '../domain/church_summary.dart';

/// The first screen a member ever sees, and the one they see again only
/// if they switch churches.
///
/// Deliberately not wrapped in the app shell: there is no church yet, so
/// there is nothing to theme it as and no navigation that would mean
/// anything. It is its own full screen.
class ChurchPickerScreen extends ConsumerWidget {
  /// True when reached from "switch church" rather than on first launch,
  /// which is the difference between offering a way back and not having
  /// anywhere to go back to.
  final bool canCancel;

  const ChurchPickerScreen({super.key, this.canCancel = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final churches = ref.watch(churchesProvider);
    final matches = ref.watch(matchingChurchesProvider);
    final query = ref.watch(churchSearchProvider);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),
                  if (canCancel)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: () => context.go('/'),
                        icon: const Icon(Icons.arrow_back),
                        label: const Text('Back'),
                      ),
                    ),
                  const SizedBox(height: 8),
                  Text('Find your church', style: theme.textTheme.headlineMedium),
                  const SizedBox(height: 8),
                  Text(
                    'Choose the church you are part of. Everything in the app '
                    'becomes theirs, and you can change it any time.',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    autofocus: false,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: 'Search by name or town',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) =>
                        ref.read(churchSearchProvider.notifier).state = value,
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: churches.when(
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (error, _) => _Message(
                        icon: Icons.cloud_off,
                        title: 'Could not load the list of churches',
                        body: 'Check your connection and try again.',
                      ),
                      data: (_) => matches.isEmpty
                          ? _Message(
                              icon: Icons.search_off,
                              title: 'No church matches "$query"',
                              body: 'Try the town instead, or a shorter part of the name.',
                            )
                          : ListView.separated(
                              itemCount: matches.length,
                              separatorBuilder: (_, _) => const SizedBox(height: 8),
                              itemBuilder: (context, i) => _ChurchTile(church: matches[i]),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ChurchTile extends ConsumerWidget {
  final ChurchSummary church;

  const _ChurchTile({required this.church});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final selected = ref.watch(selectedChurchIdProvider) == church.id;

    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: selected ? theme.colorScheme.primary : theme.dividerColor,
          width: selected ? 2 : 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primaryContainer,
          foregroundImage: church.logoUrl.isEmpty ? null : NetworkImage(church.logoUrl),
          child: const Icon(Icons.church),
        ),
        title: Text(church.name, style: theme.textTheme.titleMedium),
        subtitle: Text(
          [church.city, church.tagline].where((s) => s.isNotEmpty).join(' · '),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: selected ? const Icon(Icons.check_circle) : const Icon(Icons.chevron_right),
        onTap: () {
          chooseChurch(ref, church.id);
          context.go('/');
        },
      ),
    );
  }
}

class _Message extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;

  const _Message({required this.icon, required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 40, color: theme.textTheme.bodySmall?.color),
          const SizedBox(height: 12),
          Text(title, style: theme.textTheme.titleMedium, textAlign: TextAlign.center),
          const SizedBox(height: 6),
          Text(body, style: theme.textTheme.bodyMedium, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
