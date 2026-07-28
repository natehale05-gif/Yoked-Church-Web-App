import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/config/settings_providers.dart';
import '../../connect/application/connect_providers.dart';
import '../../connect/domain/connect_submission.dart';
import 'admin_header.dart';

class ConnectAdminScreen extends ConsumerStatefulWidget {
  const ConnectAdminScreen({super.key});

  @override
  ConsumerState<ConnectAdminScreen> createState() => _ConnectAdminScreenState();
}

class _ConnectAdminScreenState extends ConsumerState<ConnectAdminScreen> {
  bool _showFollowedUp = false;

  @override
  Widget build(BuildContext context) {
    final all = ref.watch(submissionsProvider);
    final filtered = all.whenData(
      (list) => _showFollowedUp ? list : list.where((s) => s.status == SubmissionStatus.open).toList(),
    );

    return AdminListScaffold<ConnectSubmission>(
      title: 'Connect Inbox',
      subtitle: 'Prayer requests and connect cards from the website.',
      value: filtered,
      errorContext: 'the inbox',
      emptyMessage: _showFollowedUp ? 'Nothing here yet.' : "You're all caught up.",
      maxWidth: 820,
      aboveList: SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: const Text('Show followed-up messages'),
        value: _showFollowedUp,
        onChanged: (v) => setState(() => _showFollowedUp = v),
      ),
      itemBuilder: (submission) => _SubmissionCard(submission: submission),
    );
  }
}

class _SubmissionCard extends ConsumerStatefulWidget {
  final ConnectSubmission submission;

  const _SubmissionCard({required this.submission});

  @override
  ConsumerState<_SubmissionCard> createState() => _SubmissionCardState();
}

class _SubmissionCardState extends ConsumerState<_SubmissionCard> {
  late final TextEditingController _note;
  bool _editingNote = false;

  @override
  void initState() {
    super.initState();
    _note = TextEditingController(text: widget.submission.staffNote);
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _update(ConnectSubmission updated) async {
    await ref.read(connectRepositoryProvider).update(updated);
    ref.invalidate(submissionsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.submission;
    final brand = ref.watch(settingsProvider).colors;
    final isPrayer = s.type == ConnectType.prayerRequest;
    final followedUp = s.status == SubmissionStatus.followedUp;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Chip(
                  avatar: Icon(isPrayer ? Icons.favorite_outline : Icons.person_outline, size: 16),
                  label: Text(isPrayer ? 'Prayer' : 'Connect'),
                  backgroundColor: brand.primary.withValues(alpha: 0.08),
                ),
                const SizedBox(width: 10),
                Expanded(child: Text(s.name, style: const TextStyle(fontWeight: FontWeight.w700))),
                Text(
                  DateFormat.yMMMd().format(s.submittedAt),
                  style: const TextStyle(color: Colors.black54, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              children: [
                if (s.email.isNotEmpty)
                  TextButton.icon(
                    onPressed: () => launchUrl(Uri.parse('mailto:${s.email}')),
                    icon: const Icon(Icons.mail_outline, size: 15),
                    label: Text(s.email),
                    style: TextButton.styleFrom(padding: EdgeInsets.zero),
                  ),
                if (s.phone.isNotEmpty)
                  TextButton.icon(
                    onPressed: () => launchUrl(Uri.parse('tel:${s.phone}')),
                    icon: const Icon(Icons.phone_outlined, size: 15),
                    label: Text(s.phone),
                    style: TextButton.styleFrom(padding: EdgeInsets.zero),
                  ),
              ],
            ),
            if (s.message.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(s.message, style: const TextStyle(height: 1.5)),
            ],
            const SizedBox(height: 12),
            if (_editingNote)
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _note,
                      decoration: const InputDecoration(labelText: 'Internal note', isDense: true),
                      maxLines: 2,
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () async {
                      await _update(s.copyWith(staffNote: _note.text.trim()));
                      if (mounted) setState(() => _editingNote = false);
                    },
                    child: const Text('Save'),
                  ),
                ],
              )
            else if (s.staffNote.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text('Note: ${s.staffNote}', style: const TextStyle(fontSize: 13)),
              ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => setState(() => _editingNote = !_editingNote),
                  icon: const Icon(Icons.edit_note, size: 16),
                  label: Text(s.staffNote.isEmpty ? 'Add note' : 'Edit note'),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: () => _update(
                    s.copyWith(
                      status: followedUp ? SubmissionStatus.open : SubmissionStatus.followedUp,
                    ),
                  ),
                  icon: Icon(followedUp ? Icons.replay : Icons.check_circle_outline, size: 16),
                  label: Text(followedUp ? 'Reopen' : 'Mark followed up'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
