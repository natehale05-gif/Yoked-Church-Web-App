import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/church_event.dart';
import '../../services/event_service.dart';
import '../../widgets/admin_header.dart';
import '../../widgets/section_container.dart';

class EventsAdminScreen extends StatefulWidget {
  const EventsAdminScreen({super.key});

  @override
  State<EventsAdminScreen> createState() => _EventsAdminScreenState();
}

class _EventsAdminScreenState extends State<EventsAdminScreen> {
  final EventService _service = const EventService();
  late Future<List<ChurchEvent>> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.fetchUpcomingEvents();
  }

  void _refresh() => setState(() => _future = _service.fetchUpcomingEvents());

  Future<void> _openForm({ChurchEvent? existing}) async {
    final result = await showDialog<ChurchEvent>(
      context: context,
      builder: (context) => _EventFormDialog(existing: existing),
    );
    if (result == null) return;
    if (existing == null) {
      await _service.createEvent(result);
    } else {
      await _service.updateEvent(result);
    }
    _refresh();
  }

  Future<void> _delete(ChurchEvent event) async {
    await _service.deleteEvent(event.id);
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const AdminHeader(title: 'Events', subtitle: 'Add, edit, or remove upcoming events.'),
        SectionContainer(
          maxWidth: 900,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  onPressed: () => _openForm(),
                  icon: const Icon(Icons.add),
                  label: const Text('New Event'),
                ),
              ),
              const SizedBox(height: 16),
              FutureBuilder<List<ChurchEvent>>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 60),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  final events = snapshot.data ?? [];
                  if (events.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 60),
                      child: Center(child: Text('No events yet.')),
                    );
                  }
                  return Column(
                    children: events.map((event) {
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          title: Text(event.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                          subtitle: Text('${DateFormat.yMMMd().add_jm().format(event.start)} · ${event.location}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined),
                                onPressed: () => _openForm(existing: event),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () => _delete(event),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _EventFormDialog extends StatefulWidget {
  final ChurchEvent? existing;

  const _EventFormDialog({this.existing});

  @override
  State<_EventFormDialog> createState() => _EventFormDialogState();
}

class _EventFormDialogState extends State<_EventFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _location;
  late final TextEditingController _description;
  late DateTime _start;
  DateTime? _end;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _title = TextEditingController(text: e?.title ?? '');
    _location = TextEditingController(text: e?.location ?? '');
    _description = TextEditingController(text: e?.description ?? '');
    _start = e?.start ?? DateTime.now();
    _end = e?.end;
  }

  @override
  void dispose() {
    _title.dispose();
    _location.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _pickStart() async {
    final date = await showDatePicker(context: context, initialDate: _start, firstDate: DateTime(2015), lastDate: DateTime(2100));
    if (date == null || !mounted) return;
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_start));
    if (time == null) return;
    setState(() => _start = DateTime(date.year, date.month, date.day, time.hour, time.minute));
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(ChurchEvent(
      id: widget.existing?.id ?? '',
      title: _title.text.trim(),
      start: _start,
      end: _end,
      location: _location.text.trim(),
      description: _description.text.trim(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existing == null ? 'New Event' : 'Edit Event'),
      content: SizedBox(
        width: 480,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
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
                  controller: _location,
                  decoration: const InputDecoration(labelText: 'Location'),
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Starts: ${DateFormat.yMMMd().add_jm().format(_start)}'),
                  trailing: TextButton(onPressed: _pickStart, child: const Text('Change')),
                ),
                TextFormField(
                  controller: _description,
                  decoration: const InputDecoration(labelText: 'Description'),
                  maxLines: 3,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        ElevatedButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}
