import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../models/church_event.dart';
import '../../../state/site_controller.dart';
import '../admin_widgets.dart';

class EventsAdminScreen extends StatelessWidget {
  const EventsAdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final site = context.watch<SiteController>();
    final events = List<ChurchEvent>.from(site.events)
      ..sort((a, b) => a.start.compareTo(b.start));

    return Scaffold(
      appBar: AppBar(title: const Text('Events')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _edit(context, null),
        icon: const Icon(Icons.add),
        label: const Text('Add event'),
      ),
      body: events.isEmpty
          ? Center(
              child: Text('No events yet.',
                  style: Theme.of(context).textTheme.bodyLarge))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: events.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final e = events[i];
                return Card(
                  child: ListTile(
                    title: Text(e.title),
                    subtitle: Text(
                        '${e.category} · ${DateFormat('MMM d, h:mm a').format(e.start)}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined),
                          onPressed: () => _edit(context, e),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => site.deleteEvent(e.id),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Future<void> _edit(BuildContext context, ChurchEvent? existing) async {
    final result = await Navigator.of(context).push<ChurchEvent>(
      MaterialPageRoute(
        builder: (_) => _EventForm(existing: existing),
        fullscreenDialog: true,
      ),
    );
    if (result != null && context.mounted) {
      context.read<SiteController>().upsertEvent(result);
    }
  }
}

class _EventForm extends StatefulWidget {
  final ChurchEvent? existing;

  const _EventForm({this.existing});

  @override
  State<_EventForm> createState() => _EventFormState();
}

class _EventFormState extends State<_EventForm> {
  late ChurchEvent _draft;

  @override
  void initState() {
    super.initState();
    _draft = widget.existing ??
        ChurchEvent(
          id: 'ev-${DateTime.now().microsecondsSinceEpoch}',
          title: '',
          start: DateTime.now().add(const Duration(days: 1)),
        );
  }

  Future<void> _pickStart() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _draft.start,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_draft.start),
    );
    final start = DateTime(date.year, date.month, date.day,
        time?.hour ?? _draft.start.hour, time?.minute ?? _draft.start.minute);
    setState(() => _draft = _draft.copyWith(start: start));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existing == null ? 'Add event' : 'Edit event'),
        actions: [
          TextButton(
            onPressed: _draft.title.trim().isEmpty
                ? null
                : () => Navigator.of(context).pop(_draft),
            child: const Text('Save'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AdminField(
            label: 'Title',
            value: _draft.title,
            onChanged: (v) => setState(() => _draft = _draft.copyWith(title: v)),
          ),
          AdminField(
            label: 'Category',
            value: _draft.category,
            onChanged: (v) =>
                setState(() => _draft = _draft.copyWith(category: v)),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.event_outlined),
            title: const Text('Starts'),
            subtitle: Text(
                DateFormat('EEE, MMM d, yyyy · h:mm a').format(_draft.start)),
            trailing: const Icon(Icons.chevron_right),
            onTap: _pickStart,
          ),
          const SizedBox(height: 8),
          AdminField(
            label: 'Location',
            value: _draft.location,
            onChanged: (v) =>
                setState(() => _draft = _draft.copyWith(location: v)),
          ),
          AdminField(
            label: 'Description',
            value: _draft.description,
            maxLines: 4,
            onChanged: (v) =>
                setState(() => _draft = _draft.copyWith(description: v)),
          ),
          AdminField(
            label: 'Registration / RSVP URL',
            value: _draft.registrationUrl,
            hint: 'https://…',
            onChanged: (v) =>
                setState(() => _draft = _draft.copyWith(registrationUrl: v)),
          ),
        ],
      ),
    );
  }
}
