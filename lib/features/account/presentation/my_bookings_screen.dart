import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/config/settings_providers.dart';
import '../../../core/widgets/app_shell.dart';
import '../../../core/widgets/async_value_widget.dart';
import '../../../core/widgets/responsive.dart';
import '../../../core/widgets/section_container.dart';
import '../../rooms/application/room_providers.dart';
import '../../rooms/domain/room.dart';
import 'account_header.dart';

String bookingWhen(RoomBooking booking) {
  final day = DateFormat.yMMMEd().format(booking.start);
  final from = DateFormat.jm().format(booking.start);
  final to = DateFormat.jm().format(booking.end);
  return '$day · $from – $to';
}

class MyBookingsScreen extends ConsumerWidget {
  const MyBookingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PageBody(
      children: [
        const AccountHeader(
          title: 'Room Bookings',
          subtitle: 'Request a space, and see what is already on the calendar.',
        ),
        SectionContainer(
          maxWidth: 820,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _RequestForm(),
              const SizedBox(height: 28),
              Text('Your requests', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              AsyncListWidget<RoomBooking>(
                value: ref.watch(myBookingsProvider),
                errorContext: 'your bookings',
                emptyMessage: "You haven't requested a room yet.",
                data: (bookings) => Column(
                  children: [for (final booking in bookings) _MyBookingCard(booking: booking)],
                ),
              ),
              const SizedBox(height: 28),
              Text("What's booked", style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              const Text(
                'Approved bookings across the building, so you can pick a slot that is free.',
                style: TextStyle(color: Colors.black54, fontSize: 13),
              ),
              const SizedBox(height: 12),
              const _UpcomingSchedule(),
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
  final _formKey = GlobalKey<FormState>();
  final _purpose = TextEditingController();
  final _attendance = TextEditingController();
  Room? _room;
  DateTime _day = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _from = const TimeOfDay(hour: 19, minute: 0);
  TimeOfDay _to = const TimeOfDay(hour: 20, minute: 30);
  bool _sending = false;

  @override
  void dispose() {
    _purpose.dispose();
    _attendance.dispose();
    super.dispose();
  }

  DateTime _at(TimeOfDay time) => DateTime(_day.year, _day.month, _day.day, time.hour, time.minute);

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _room == null) return;
    if (!_at(_to).isAfter(_at(_from))) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('The end time needs to be after the start time.')),
      );
      return;
    }

    setState(() => _sending = true);
    await ref.read(roomControllerProvider).request(
          room: _room!,
          purpose: _purpose.text,
          start: _at(_from),
          end: _at(_to),
          expectedAttendance: int.tryParse(_attendance.text.trim()) ?? 0,
        );
    if (!mounted) return;
    _purpose.clear();
    _attendance.clear();
    setState(() {
      _sending = false;
      _room = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Requested. Staff will confirm the room shortly.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rooms = ref.watch(bookableRoomsProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Request a room', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              DropdownButtonFormField<Room>(
                initialValue: _room,
                decoration: const InputDecoration(labelText: 'Room'),
                items: [for (final room in rooms) DropdownMenuItem(value: room, child: Text(room.name))],
                onChanged: (value) => setState(() => _room = value),
                validator: (value) => value == null ? 'Choose a room' : null,
              ),
              TextFormField(
                controller: _purpose,
                decoration: const InputDecoration(labelText: 'What is it for?'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              TextFormField(
                controller: _attendance,
                decoration: const InputDecoration(labelText: 'Roughly how many people? (optional)'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('Date: ${DateFormat.yMMMEd().format(_day)}'),
                trailing: TextButton(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _day,
                      firstDate: DateTime.now().subtract(const Duration(days: 1)),
                      lastDate: DateTime.now().add(const Duration(days: 730)),
                    );
                    if (picked != null) setState(() => _day = picked);
                  },
                  child: const Text('Change'),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: _TimeField(
                      label: 'From',
                      value: _from,
                      onChanged: (t) => setState(() => _from = t),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _TimeField(
                      label: 'To',
                      value: _to,
                      onChanged: (t) => setState(() => _to = t),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              DetailWithAction(
                crossAxisAlignment: CrossAxisAlignment.center,
                action: ElevatedButton(
                  onPressed: _sending ? null : _submit,
                  child: _sending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Request room'),
                ),
                child: const Text(
                  'Requests are confirmed by staff, so a room is not held until you hear back.',
                  style: TextStyle(color: Colors.black54, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TimeField extends StatelessWidget {
  final String label;
  final TimeOfDay value;
  final ValueChanged<TimeOfDay> onChanged;

  const _TimeField({required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final picked = await showTimePicker(context: context, initialTime: value);
        if (picked != null) onChanged(picked);
      },
      child: InputDecorator(
        decoration: InputDecoration(labelText: label),
        child: Text(value.format(context)),
      ),
    );
  }
}

class _MyBookingCard extends ConsumerWidget {
  final RoomBooking booking;

  const _MyBookingCard({required this.booking});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (label, color) = switch (booking.status) {
      BookingStatus.pending => ('Waiting for staff', Colors.orange),
      BookingStatus.approved => ('Confirmed', Colors.green),
      BookingStatus.declined => ('Declined', Colors.red),
      BookingStatus.cancelled => ('Cancelled', Colors.grey),
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DetailWithAction(
              spacing: 8,
              crossAxisAlignment: CrossAxisAlignment.center,
              action: Chip(
                label: Text(label),
                labelStyle: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12),
                backgroundColor: color.withValues(alpha: 0.1),
                side: BorderSide.none,
                visualDensity: VisualDensity.compact,
              ),
              child: Text(booking.purpose, style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
            const SizedBox(height: 6),
            Text('${booking.roomName} · ${bookingWhen(booking)}',
                style: const TextStyle(color: Colors.black54, fontSize: 13)),
            if (booking.staffNote.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(booking.staffNote, style: const TextStyle(height: 1.5)),
            ],
            if (booking.status == BookingStatus.pending || booking.status == BookingStatus.approved) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => ref.read(roomControllerProvider).cancel(booking),
                  icon: const Icon(Icons.close, size: 16),
                  label: const Text('Cancel this request'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _UpcomingSchedule extends ConsumerWidget {
  const _UpcomingSchedule();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookings = ref.watch(upcomingBookingsProvider);
    final brand = ref.watch(settingsProvider).colors;
    if (bookings.isEmpty) {
      return const EmptyState(message: 'Nothing booked yet.', icon: Icons.event_available_outlined);
    }

    return Column(
      children: [
        for (final booking in bookings.take(20))
          ListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            leading: Icon(Icons.meeting_room_outlined, size: 20, color: brand.primary),
            title: Text('${booking.roomName} · ${booking.purpose}'),
            subtitle: Text(bookingWhen(booking)),
          ),
      ],
    );
  }
}
