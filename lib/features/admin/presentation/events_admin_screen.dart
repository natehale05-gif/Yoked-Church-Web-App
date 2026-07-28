import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../audit_log/application/audit_providers.dart';
import '../../events/application/event_providers.dart';
import '../../events/application/rsvp_providers.dart';
import '../../events/domain/church_event.dart';
import 'admin_header.dart';

class EventsAdminScreen extends ConsumerWidget {
  const EventsAdminScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Future<void> openForm({ChurchEvent? existing}) async {
      final result = await showDialog<ChurchEvent>(
        context: context,
        builder: (_) => _EventForm(existing: existing),
      );
      if (result == null) return;
      final repo = ref.read(eventRepositoryProvider);
      if (existing == null) {
        await repo.create(result);
      } else {
        await repo.update(result);
      }
      ref.invalidate(allEventsProvider);
    }

    return AdminListScaffold<ChurchEvent>(
      title: 'Events',
      subtitle: 'Add, edit, or remove events, and see who has RSVP\'d.',
      value: ref.watch(allEventsProvider),
      errorContext: 'events',
      emptyMessage: 'No events yet. Add the first one.',
      newLabel: 'New Event',
      onNew: openForm,
      itemBuilder: (event) => AdminListTile(
        title: event.title,
        subtitle: [
          DateFormat.yMMMd().add_jm().format(event.start),
          if (event.location.isNotEmpty) event.location,
          if (event.isPast) 'past',
        ].join(' · '),
        deleteLabel: '"${event.title}"',
        actions: [
          if (event.rsvpEnabled)
            TextButton(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => _RsvpListDialog(event: event),
              ),
              child: const Text('RSVPs'),
            ),
        ],
        onEdit: () => openForm(existing: event),
        onDelete: () async {
          await ref.read(eventRepositoryProvider).delete(event.id);
          await ref.read(auditLoggerProvider).record(
                action: 'deleted',
                entity: 'event',
                details: event.title,
              );
          ref.invalidate(allEventsProvider);
        },
      ),
    );
  }
}

/// Attendee list for a single event - the "who's coming" view staff need
/// on the day.
class _RsvpListDialog extends ConsumerWidget {
  final ChurchEvent event;

  const _RsvpListDialog({required this.event});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rsvps = ref.watch(eventRsvpsProvider(event.id));

    return AlertDialog(
      title: Text('${event.title} - RSVPs'),
      content: SizedBox(
        width: 420,
        child: rsvps.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => Text('Could not load RSVPs: $e'),
          data: (list) {
            if (list.isEmpty) {
              return const Padding(padding: EdgeInsets.all(24), child: Text('No RSVPs yet.'));
            }
            final total = list.fold<int>(0, (sum, r) => sum + r.partySize);
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${list.length} response(s) · $total attending'
                  '${event.capacity > 0 ? " of ${event.capacity}" : ""}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 320),
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      for (final rsvp in list)
                        ListTile(
                          dense: true,
                          title: Text(rsvp.memberName.isEmpty ? rsvp.uid : rsvp.memberName),
                          subtitle: Text(DateFormat.yMMMd().format(rsvp.respondedAt)),
                          trailing: rsvp.partySize > 1 ? Text('party of ${rsvp.partySize}') : null,
                        ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
    );
  }
}

class _EventForm extends StatefulWidget {
  final ChurchEvent? existing;

  const _EventForm({this.existing});

  @override
  State<_EventForm> createState() => _EventFormState();
}

class _EventFormState extends State<_EventForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _location;
  late final TextEditingController _description;
  late final TextEditingController _category;
  late final TextEditingController _capacity;
  late DateTime _start;
  DateTime? _end;
  late bool _rsvpEnabled;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _title = TextEditingController(text: e?.title ?? '');
    _location = TextEditingController(text: e?.location ?? '');
    _description = TextEditingController(text: e?.description ?? '');
    _category = TextEditingController(text: e?.category ?? '');
    _capacity = TextEditingController(text: (e?.capacity ?? 0) == 0 ? '' : '${e!.capacity}');
    _start = e?.start ?? DateTime.now();
    _end = e?.end;
    _rsvpEnabled = e?.rsvpEnabled ?? true;
  }

  @override
  void dispose() {
    for (final c in [_title, _location, _description, _category, _capacity]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<DateTime?> _pickDateTime(DateTime initial) async {
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2015),
      lastDate: DateTime(2100),
    );
    if (date == null || !mounted) return null;
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(initial));
    if (time == null) return null;
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  @override
  Widget build(BuildContext context) {
    return AdminFormDialog(
      title: widget.existing == null ? 'New Event' : 'Edit Event',
      onSave: () {
        if (!_formKey.currentState!.validate()) return;
        Navigator.pop(
          context,
          ChurchEvent(
            id: widget.existing?.id ?? '',
            title: _title.text.trim(),
            start: _start,
            end: _end,
            location: _location.text.trim(),
            description: _description.text.trim(),
            category: _category.text.trim(),
            rsvpEnabled: _rsvpEnabled,
            capacity: int.tryParse(_capacity.text.trim()) ?? 0,
          ),
        );
      },
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
            TextFormField(controller: _location, decoration: const InputDecoration(labelText: 'Location')),
            TextFormField(
              controller: _category,
              decoration: const InputDecoration(labelText: 'Category', hintText: 'Worship, Youth, Outreach'),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('Starts: ${DateFormat.yMMMd().add_jm().format(_start)}'),
              trailing: TextButton(
                onPressed: () async {
                  final picked = await _pickDateTime(_start);
                  if (picked != null) setState(() => _start = picked);
                },
                child: const Text('Change'),
              ),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(_end == null ? 'Ends: not set' : 'Ends: ${DateFormat.yMMMd().add_jm().format(_end!)}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_end != null)
                    IconButton(
                      tooltip: 'Clear',
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () => setState(() => _end = null),
                    ),
                  TextButton(
                    onPressed: () async {
                      final picked = await _pickDateTime(_end ?? _start.add(const Duration(hours: 1)));
                      if (picked != null) setState(() => _end = picked);
                    },
                    child: const Text('Change'),
                  ),
                ],
              ),
            ),
            TextFormField(
              controller: _description,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 3,
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Allow RSVPs'),
              value: _rsvpEnabled,
              onChanged: (v) => setState(() => _rsvpEnabled = v),
            ),
            if (_rsvpEnabled)
              TextFormField(
                controller: _capacity,
                decoration: const InputDecoration(labelText: 'Capacity (blank = unlimited)'),
                keyboardType: TextInputType.number,
              ),
          ],
        ),
      ),
    );
  }
}
