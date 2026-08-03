import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../audit_log/application/audit_providers.dart';
import '../../prayer_wall/application/prayer_providers.dart';
import '../../prayer_wall/domain/prayer_post.dart';
import 'admin_header.dart';

class PrayerAdminScreen extends ConsumerWidget {
  const PrayerAdminScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pending = ref.watch(pendingPrayerCountProvider);

    return AdminListScaffold<PrayerPost>(
      title: 'Prayer Wall',
      subtitle: pending == 0
          ? 'Nothing waiting. Approved requests are visible to signed-in members.'
          : '$pending request${pending == 1 ? '' : 's'} waiting for review.',
      value: ref.watch(allPrayerPostsProvider),
      errorContext: 'prayer requests',
      emptyMessage: 'No prayer requests yet.',
      maxWidth: 820,
      itemBuilder: (post) => _ModerationCard(post: post),
    );
  }
}

class _ModerationCard extends ConsumerWidget {
  final PrayerPost post;

  const _ModerationCard({required this.post});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(prayerControllerProvider);
    final (label, color) = switch (post.status) {
      PrayerStatus.pending => ('Waiting', Colors.orange),
      PrayerStatus.approved => ('On the wall', Colors.green),
      PrayerStatus.removed => ('Not posted', Colors.red),
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Chip(
                  label: Text(label),
                  labelStyle: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12),
                  backgroundColor: color.withValues(alpha: 0.1),
                  side: BorderSide.none,
                  visualDensity: VisualDensity.compact,
                ),
                const Spacer(),
                // Staff can always see who submitted a request, even an
                // anonymous one, so they can follow up pastorally - but
                // the wall itself never shows it.
                if (post.anonymous)
                  const Tooltip(
                    message: 'Posted anonymously - the wall will not show a name',
                    child: Icon(Icons.visibility_off_outlined, size: 18, color: Colors.black45),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(post.body, style: const TextStyle(fontSize: 15, height: 1.6)),
            const SizedBox(height: 12),
            Text(
              [
                post.anonymous ? 'Anonymous' : post.displayName,
                DateFormat.yMMMd().add_jm().format(post.createdAt),
                if (post.moderatedBy.isNotEmpty) 'handled by ${post.moderatedBy}',
              ].join(' · '),
              style: const TextStyle(color: Colors.black54, fontSize: 12),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                if (post.status != PrayerStatus.approved)
                  ElevatedButton.icon(
                    onPressed: () => controller.approve(post),
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('Post to wall'),
                  ),
                if (post.status != PrayerStatus.removed)
                  OutlinedButton.icon(
                    onPressed: () => controller.remove(post),
                    icon: const Icon(Icons.visibility_off_outlined, size: 16),
                    label: Text(post.status == PrayerStatus.approved ? 'Take down' : 'Decline'),
                  ),
                TextButton.icon(
                  onPressed: () async {
                    if (!await confirmDelete(context, 'this prayer request')) return;
                    await controller.deleteForever(post.id);
                    await ref.read(auditLoggerProvider).record(
                          action: 'deleted',
                          entity: 'prayer request',
                          details: post.anonymous ? 'anonymous request' : post.displayName,
                        );
                  },
                  icon: const Icon(Icons.delete_outline, size: 16),
                  label: const Text('Delete'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
