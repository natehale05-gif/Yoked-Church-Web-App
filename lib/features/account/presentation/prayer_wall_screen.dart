import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/config/settings_providers.dart';
import '../../../core/widgets/app_shell.dart';
import '../../../core/widgets/async_value_widget.dart';
import '../../../core/widgets/section_container.dart';
import '../../prayer_wall/application/prayer_providers.dart';
import '../../prayer_wall/domain/prayer_post.dart';
import 'account_header.dart';

/// Members-only by design: a prayer request often names a person or a
/// diagnosis, and that is not something to publish on a public page.
class PrayerWallScreen extends ConsumerWidget {
  const PrayerWallScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mine = ref.watch(myPrayerPostsProvider);

    return PageBody(
      children: [
        const AccountHeader(
          title: 'Prayer Wall',
          subtitle: 'Share what you are carrying, and pray for one another.',
        ),
        SectionContainer(
          maxWidth: 760,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _RequestForm(),
              if (mine.isNotEmpty) ...[
                const SizedBox(height: 28),
                Text('Your requests', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                for (final post in mine) _MyPendingCard(post: post),
              ],
              const SizedBox(height: 28),
              Text('Praying together', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              AsyncListWidget<PrayerPost>(
                value: ref.watch(prayerWallProvider),
                errorContext: 'the prayer wall',
                emptyMessage: 'No requests on the wall yet.',
                data: (posts) => Column(
                  children: [for (final post in posts) _PrayerCard(post: post)],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RequestForm extends ConsumerStatefulWidget {
  const _RequestForm();

  @override
  ConsumerState<_RequestForm> createState() => _RequestFormState();
}

class _RequestFormState extends ConsumerState<_RequestForm> {
  final _controller = TextEditingController();
  bool _anonymous = false;
  bool _sending = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_controller.text.trim().isEmpty) return;
    setState(() => _sending = true);
    await ref.read(prayerControllerProvider).submit(
          body: _controller.text,
          anonymous: _anonymous,
        );
    if (!mounted) return;
    _controller.clear();
    setState(() {
      _sending = false;
      _anonymous = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sent. A staff member will post it to the wall shortly.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Ask for prayer', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'What would you like us to pray for?',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              value: _anonymous,
              onChanged: (v) => setState(() => _anonymous = v ?? false),
              title: const Text('Post anonymously'),
              subtitle: const Text('Your name is never stored on an anonymous request.'),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Requests go to staff first, so nothing reaches the wall unreviewed.',
                    style: TextStyle(color: Colors.black54, fontSize: 12),
                  ),
                ),
                ElevatedButton(
                  onPressed: _sending ? null : _submit,
                  child: _sending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Send request'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Shown to an author so a request awaiting review doesn't just seem to
/// have disappeared.
class _MyPendingCard extends StatelessWidget {
  final PrayerPost post;

  const _MyPendingCard({required this.post});

  @override
  Widget build(BuildContext context) {
    final removed = post.status == PrayerStatus.removed;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.black.withValues(alpha: 0.03),
      child: ListTile(
        leading: Icon(removed ? Icons.block : Icons.schedule, size: 20, color: Colors.black45),
        title: Text(post.body, style: const TextStyle(height: 1.5)),
        subtitle: Text(
          removed ? "Not posted to the wall. Talk to a staff member if you'd like to know why." : 'Waiting for review',
          style: const TextStyle(fontSize: 12, color: Colors.black54),
        ),
      ),
    );
  }
}

class _PrayerCard extends ConsumerWidget {
  final PrayerPost post;

  const _PrayerCard({required this.post});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brand = ref.watch(settingsProvider).colors;
    final counts = ref.watch(prayerCountsProvider).valueOrNull ?? const <String, int>{};
    final mine = ref.watch(myIntercessionsProvider).valueOrNull ?? const <String>{};
    final count = counts[post.id] ?? 0;
    final prayed = mine.contains(post.id);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(post.body, style: const TextStyle(fontSize: 15, height: 1.6)),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${post.displayName} · ${DateFormat.yMMMd().format(post.createdAt)}',
                    style: const TextStyle(color: Colors.black54, fontSize: 13),
                  ),
                ),
                if (count > 0)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Text(
                      count == 1 ? '1 praying' : '$count praying',
                      style: TextStyle(color: brand.primary, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                TextButton.icon(
                  onPressed: () => ref.read(prayerControllerProvider).togglePrayed(post.id),
                  style: TextButton.styleFrom(foregroundColor: prayed ? brand.accent : brand.primary),
                  icon: Icon(prayed ? Icons.volunteer_activism : Icons.volunteer_activism_outlined, size: 18),
                  label: Text(prayed ? 'Praying' : 'I prayed'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
