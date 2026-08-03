import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../account/presentation/my_bookings_screen.dart' show bookingWhen;
import '../../audit_log/application/audit_providers.dart';
import '../../church_info/application/church_info_providers.dart';
import '../../church_info/domain/church_info.dart';
import '../../rooms/application/room_providers.dart';
import '../../rooms/domain/room.dart';
import 'admin_header.dart';

class RoomsAdminScreen extends ConsumerWidget {
  const RoomsAdminScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pending = ref.watch(pendingBookingCountProvider);

    return AdminListScaffold<RoomBooking>(
      title: 'Rooms & Bookings',
      subtitle: pending == 0
          ? 'Nothing waiting. Approving a booking is what actually holds the room.'
          : '$pending request${pending == 1 ? '' : 's'} waiting for review.',
      value: ref.watch(allBookingsProvider),
      errorContext: 'room bookings',
      emptyMessage: 'No booking requests yet.',
      maxWidth: 860,
      aboveList: const _RoomManager(),
      itemBuilder: (booking) => _BookingCard(booking: booking),
    );
  }
}

/// Rooms live above the booking queue rather than on their own page - a
/// church has a handful and always manages them alongside the requests.
/// Same shape as the sermon series manager.
class _RoomManager extends ConsumerWidget {
  const _RoomManager();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rooms = ref.watch(roomsProvider).valueOrNull ?? const <Room>[];

    Future<void> openForm({Room? existing}) async {
      final result = await showDialog<Room>(
        context: context,
        builder: (_) => _RoomForm(existing: existing),
      );
      if (result == null) return;
      final repo = ref.read(roomRepositoryProvider);
      if (existing == null) {
        await repo.create(result);
      } else {
        await repo.update(result);
      }
      ref.invalidate(roomsProvider);
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text('Rooms', style: Theme.of(context).textTheme.titleMedium)),
                TextButton.icon(
                  onPressed: openForm,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('New room'),
                ),
              ],
            ),
            if (rooms.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('No rooms yet. Add one before members can book.',
                    style: TextStyle(color: Colors.black54)),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final room in rooms)
                    InputChip(
                      avatar: room.bookable
                          ? null
                          : const Tooltip(
                              message: 'Not bookable - used for check-in only',
                              child: Icon(Icons.lock_outline, size: 14),
                            ),
                      label: Text(room.name),
                      onPressed: () => openForm(existing: room),
                      onDeleted: () async {
                        if (!await confirmDelete(context, 'the room "${room.name}"')) return;
                        await ref.read(roomRepositoryProvider).delete(room.id);
                        await ref.read(auditLoggerProvider).record(
                              action: 'deleted',
                              entity: 'room',
                              details: room.name,
                            );
                        ref.invalidate(roomsProvider);
                      },
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _BookingCard extends ConsumerWidget {
  final RoomBooking booking;

  const _BookingCard({required this.booking});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(roomControllerProvider);
    final (label, color) = switch (booking.status) {
      BookingStatus.pending => ('Waiting', Colors.orange),
      BookingStatus.approved => ('Confirmed', Colors.green),
      BookingStatus.declined => ('Declined', Colors.red),
      BookingStatus.cancelled => ('Cancelled', Colors.grey),
    };

    Future<void> approve() async {
      final conflict = await controller.approve(booking);
      if (!context.mounted) return;
      if (conflict == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Booking confirmed. The member has been notified.')),
        );
        return;
      }
      // Naming the clash matters: "the room is taken" tells a staff
      // member nothing about what to do next.
      final other = conflict.existing;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('That room is already booked'),
          content: Text(
            '${booking.roomName} is held by "${other.purpose}" '
            '(${other.requestedByName.isEmpty ? 'a member' : other.requestedByName}) '
            'on ${bookingWhen(other)}.\n\n'
            'Cancel that booking first, or decline this request with a note.',
          ),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
        ),
      );
    }

    Future<void> decline() async {
      final note = await showDialog<String>(
        context: context,
        builder: (_) => const _DeclineDialog(),
      );
      if (note == null) return;
      await controller.decline(booking, note: note);
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(booking.purpose, style: Theme.of(context).textTheme.titleMedium),
                ),
                Chip(
                  label: Text(label),
                  labelStyle: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12),
                  backgroundColor: color.withValues(alpha: 0.1),
                  side: BorderSide.none,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('${booking.roomName} · ${bookingWhen(booking)}',
                style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text(
              [
                if (booking.requestedByName.isNotEmpty) booking.requestedByName,
                if (booking.expectedAttendance > 0) '~${booking.expectedAttendance} people',
                if (booking.moderatedBy.isNotEmpty) 'handled by ${booking.moderatedBy}',
              ].join(' · '),
              style: const TextStyle(color: Colors.black54, fontSize: 12),
            ),
            if (booking.staffNote.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(booking.staffNote, style: const TextStyle(height: 1.5, fontStyle: FontStyle.italic)),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                if (booking.status != BookingStatus.approved)
                  ElevatedButton.icon(
                    onPressed: approve,
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('Confirm'),
                  ),
                if (booking.status == BookingStatus.pending)
                  OutlinedButton.icon(
                    onPressed: decline,
                    icon: const Icon(Icons.close, size: 16),
                    label: const Text('Decline'),
                  ),
                if (booking.status == BookingStatus.approved)
                  OutlinedButton.icon(
                    onPressed: () => controller.cancel(booking),
                    icon: const Icon(Icons.event_busy_outlined, size: 16),
                    label: const Text('Release room'),
                  ),
                TextButton.icon(
                  onPressed: () async {
                    if (!await confirmDelete(context, 'this booking request')) return;
                    await controller.deleteBooking(booking.id);
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

class _DeclineDialog extends StatefulWidget {
  const _DeclineDialog();

  @override
  State<_DeclineDialog> createState() => _DeclineDialogState();
}

class _DeclineDialogState extends State<_DeclineDialog> {
  final _note = TextEditingController();

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Decline this request'),
      content: SizedBox(
        width: 420,
        child: TextField(
          controller: _note,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Reason (sent to the member)',
            hintText: 'The hall is set up for the food drive that morning.',
            border: OutlineInputBorder(),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: () => Navigator.pop(context, _note.text.trim()),
          child: const Text('Decline'),
        ),
      ],
    );
  }
}

class _RoomForm extends ConsumerStatefulWidget {
  final Room? existing;

  const _RoomForm({this.existing});

  @override
  ConsumerState<_RoomForm> createState() => _RoomFormState();
}

class _RoomFormState extends ConsumerState<_RoomForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _description;
  late final TextEditingController _capacity;
  String? _locationId;
  late bool _bookable;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _name = TextEditingController(text: e?.name ?? '');
    _description = TextEditingController(text: e?.description ?? '');
    _capacity = TextEditingController(text: (e?.capacity ?? 0) == 0 ? '' : '${e!.capacity}');
    _locationId = (e?.locationId.isNotEmpty ?? false) ? e!.locationId : null;
    _bookable = e?.bookable ?? true;
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _capacity.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locations = ref.watch(locationsProvider).valueOrNull ?? const <ChurchLocation>[];

    return AdminFormDialog(
      title: widget.existing == null ? 'New Room' : 'Edit Room',
      onSave: () {
        if (!_formKey.currentState!.validate()) return;
        final location = locations.where((l) => l.id == _locationId);
        Navigator.pop(
          context,
          Room(
            id: widget.existing?.id ?? '',
            name: _name.text.trim(),
            locationId: _locationId ?? '',
            locationName: location.isEmpty ? '' : location.first.name,
            description: _description.text.trim(),
            capacity: int.tryParse(_capacity.text.trim()) ?? 0,
            bookable: _bookable,
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
              controller: _name,
              decoration: const InputDecoration(labelText: 'Name', hintText: 'Fellowship Hall'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            TextFormField(
              controller: _description,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 2,
            ),
            TextFormField(
              controller: _capacity,
              decoration: const InputDecoration(labelText: 'Capacity (optional)'),
              keyboardType: TextInputType.number,
            ),
            if (locations.isNotEmpty) ...[
              const SizedBox(height: 12),
              DropdownButtonFormField<String?>(
                initialValue: _locationId,
                decoration: const InputDecoration(labelText: 'Campus'),
                items: [
                  const DropdownMenuItem<String?>(value: null, child: Text('No campus')),
                  for (final l in locations) DropdownMenuItem(value: l.id, child: Text(l.name)),
                ],
                onChanged: (value) => setState(() => _locationId = value),
              ),
            ],
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Bookable'),
              subtitle: const Text('Turn off for spaces used only by kids check-in.'),
              value: _bookable,
              onChanged: (v) => setState(() => _bookable = v),
            ),
          ],
        ),
      ),
    );
  }
}

/// Kept out of the card so the queue reads chronologically for staff.
String bookingDay(RoomBooking booking) => DateFormat.yMMMEd().format(booking.start);
