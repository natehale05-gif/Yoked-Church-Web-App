import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/config/settings_providers.dart';
import '../../auth/application/auth_providers.dart';
import '../../sermons/domain/sermon.dart';
import '../application/sermon_note_providers.dart';

/// The "My Notes" panel on a sermon page. Explicitly saved rather than
/// autosaved: a member typing during a service should decide when their
/// notes are written, and an autosave that fires mid-sentence on a flaky
/// connection is worse than a button.
class MyNoteCard extends ConsumerStatefulWidget {
  final Sermon sermon;

  const MyNoteCard({super.key, required this.sermon});

  @override
  ConsumerState<MyNoteCard> createState() => _MyNoteCardState();
}

class _MyNoteCardState extends ConsumerState<MyNoteCard> {
  final _controller = TextEditingController();
  bool _hydrated = false;
  bool _dirty = false;
  bool _saving = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await ref.read(sermonNoteControllerProvider).save(
          sermon: widget.sermon,
          body: _controller.text,
        );
    if (!mounted) return;
    setState(() {
      _saving = false;
      _dirty = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_controller.text.trim().isEmpty ? 'Notes cleared.' : 'Notes saved.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final brand = ref.watch(settingsProvider).colors;

    if (!ref.watch(isSignedInProvider)) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('My Notes', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              const Text(
                'Sign in to keep your own notes on this message. They stay private to you.',
                style: TextStyle(height: 1.5, color: Colors.black54),
              ),
              const SizedBox(height: 14),
              OutlinedButton(onPressed: () => context.go('/sign-in'), child: const Text('Sign in')),
            ],
          ),
        ),
      );
    }

    final existing = ref.watch(noteForSermonProvider(widget.sermon.id));
    // Fill the field once from the stored note. After that the member owns
    // it - a later refetch must not overwrite what they are typing.
    if (!_hydrated && existing != null) {
      _hydrated = true;
      _controller.text = existing.body;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text('My Notes', style: Theme.of(context).textTheme.titleLarge)),
                Tooltip(
                  message: 'Only you can see these',
                  child: Icon(Icons.lock_outline, size: 18, color: brand.primary),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              onChanged: (_) {
                if (!_dirty) setState(() => _dirty = true);
              },
              maxLines: 8,
              minLines: 4,
              decoration: const InputDecoration(
                hintText: 'What stood out to you?',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                if (existing != null)
                  Expanded(
                    child: Text(
                      'Saved ${DateFormat.yMMMd().add_jm().format(existing.updatedAt)}',
                      style: const TextStyle(color: Colors.black54, fontSize: 12),
                    ),
                  )
                else
                  const Spacer(),
                ElevatedButton(
                  onPressed: (_dirty && !_saving) ? _save : null,
                  child: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Save notes'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
