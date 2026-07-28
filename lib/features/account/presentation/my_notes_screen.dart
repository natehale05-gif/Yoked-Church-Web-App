import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/widgets/app_shell.dart';
import '../../../core/widgets/async_value_widget.dart';
import '../../../core/widgets/section_container.dart';
import '../../sermon_notes/application/sermon_note_providers.dart';
import '../../sermon_notes/domain/sermon_note.dart';
import 'account_header.dart';

class MyNotesScreen extends ConsumerWidget {
  const MyNotesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PageBody(
      children: [
        const AccountHeader(
          title: 'My Notes',
          subtitle: 'Everything you wrote down, in one place. Private to you.',
        ),
        SectionContainer(
          maxWidth: 760,
          child: AsyncListWidget<SermonNote>(
            value: ref.watch(myNotesProvider),
            errorContext: 'your notes',
            emptyMessage: "You haven't written any notes yet. Open a sermon to start.",
            data: (notes) => Column(
              children: [for (final note in notes) _NoteRow(note: note)],
            ),
          ),
        ),
      ],
    );
  }
}

class _NoteRow extends ConsumerWidget {
  final SermonNote note;

  const _NoteRow({required this.note});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => context.go('/sermons/${note.sermonId}'),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      note.sermonTitle.isEmpty ? 'Sermon notes' : note.sermonTitle,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Delete these notes',
                    icon: const Icon(Icons.delete_outline, size: 20),
                    onPressed: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Delete these notes?'),
                          content: const Text('This cannot be undone.'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancel'),
                            ),
                            FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: Theme.of(context).colorScheme.error,
                              ),
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Delete'),
                            ),
                          ],
                        ),
                      );
                      if (confirmed ?? false) {
                        await ref.read(sermonNoteControllerProvider).delete(note.sermonId);
                      }
                    },
                  ),
                ],
              ),
              Text(
                DateFormat.yMMMMd().format(note.sermonDate),
                style: const TextStyle(color: Colors.black54, fontSize: 13),
              ),
              const SizedBox(height: 12),
              Text(note.excerpt, style: const TextStyle(height: 1.6)),
              const SizedBox(height: 10),
              Text(
                'Updated ${DateFormat.yMMMd().format(note.updatedAt)}',
                style: const TextStyle(color: Colors.black45, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
