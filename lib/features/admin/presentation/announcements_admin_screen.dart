import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../announcements/application/announcement_providers.dart';
import '../../announcements/domain/announcement.dart';
import '../../groups/domain/group.dart';
import 'admin_header.dart';

class AnnouncementsAdminScreen extends ConsumerWidget {
  const AnnouncementsAdminScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AdminListScaffold<Announcement>(
      title: 'Announcements',
      subtitle: "Send news to the congregation. It lands in each member's notification inbox.",
      value: ref.watch(announcementsProvider),
      errorContext: 'announcements',
      emptyMessage: 'Nothing sent yet.',
      newLabel: 'New Announcement',
      maxWidth: 820,
      onNew: () => showDialog<void>(context: context, builder: (_) => const _ComposeDialog()),
      itemBuilder: (announcement) => Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(announcement.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                  ),
                  Chip(label: Text(announcement.audienceLabel)),
                ],
              ),
              const SizedBox(height: 8),
              Text(announcement.body, style: const TextStyle(height: 1.5)),
              const SizedBox(height: 10),
              Text(
                [
                  if (announcement.sentByName.isNotEmpty) announcement.sentByName,
                  DateFormat.yMMMd().add_jm().format(announcement.sentAt),
                  'sent to ${announcement.recipientCount}',
                ].join(' · '),
                style: const TextStyle(color: Colors.black54, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ComposeDialog extends ConsumerStatefulWidget {
  const _ComposeDialog();

  @override
  ConsumerState<_ComposeDialog> createState() => _ComposeDialogState();
}

class _ComposeDialogState extends ConsumerState<_ComposeDialog> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _body = TextEditingController();
  AnnouncementAudience _audience = AnnouncementAudience.everyone;
  ChurchGroup? _group;

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (!_formKey.currentState!.validate()) return;
    if (_audience == AnnouncementAudience.group && _group == null) return;

    final ok = await ref.read(announcementControllerProvider.notifier).send(
          title: _title.text.trim(),
          body: _body.text.trim(),
          audience: _audience,
          group: _group,
        );
    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? 'Announcement sent.' : 'Could not send that announcement.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final groups = ref.watch(announcementGroupsProvider);
    final busy = ref.watch(announcementControllerProvider).isLoading;
    final memberCount = ref.watch(memberCountProvider);

    return AlertDialog(
      title: const Text('New Announcement'),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _title,
                  decoration: const InputDecoration(labelText: 'Title'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                TextFormField(
                  controller: _body,
                  decoration: const InputDecoration(labelText: 'Message'),
                  maxLines: 5,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<AnnouncementAudience>(
                  initialValue: _audience,
                  decoration: const InputDecoration(labelText: 'Send to'),
                  items: [
                    DropdownMenuItem(
                      value: AnnouncementAudience.everyone,
                      child: Text('Everyone ($memberCount)'),
                    ),
                    const DropdownMenuItem(value: AnnouncementAudience.staff, child: Text('Staff only')),
                    const DropdownMenuItem(value: AnnouncementAudience.group, child: Text('A specific group')),
                  ],
                  onChanged: (v) => setState(() {
                    _audience = v ?? AnnouncementAudience.everyone;
                    if (_audience != AnnouncementAudience.group) _group = null;
                  }),
                ),
                if (_audience == AnnouncementAudience.group) ...[
                  const SizedBox(height: 12),
                  DropdownButtonFormField<ChurchGroup>(
                    initialValue: _group,
                    decoration: const InputDecoration(labelText: 'Group'),
                    items: [
                      for (final g in groups) DropdownMenuItem(value: g, child: Text(g.name)),
                    ],
                    onChanged: (v) => setState(() => _group = v),
                    validator: (v) => v == null ? 'Choose a group' : null,
                  ),
                ],
                const SizedBox(height: 12),
                const Text(
                  'Members who muted announcements in their preferences will not '
                  'see this in their inbox.',
                  style: TextStyle(color: Colors.black54, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: busy ? null : _send,
          child: busy
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Send'),
        ),
      ],
    );
  }
}
