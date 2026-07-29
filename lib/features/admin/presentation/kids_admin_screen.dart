import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/config/settings_providers.dart';
import '../../../core/widgets/app_shell.dart';
import '../../../core/widgets/async_value_widget.dart';
import '../../../core/widgets/responsive.dart';
import '../../../core/widgets/section_container.dart';
import '../../auth/application/auth_providers.dart';
import '../../auth/domain/app_user.dart';
import '../../kids/application/check_in_providers.dart';
import '../../kids/domain/check_in.dart';
import '../../rooms/domain/room.dart';
import 'admin_header.dart';

/// The desk in the foyer. Two jobs, side by side: get children in, and
/// get the right child back to the right adult.
class KidsAdminScreen extends ConsumerWidget {
  const KidsAdminScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = ref.watch(activeCheckInCountProvider);

    return PageBody(
      children: [
        AdminHeader(
          title: 'Kids Check-In',
          subtitle: active == 0
              ? 'Nobody checked in right now.'
              : '$active ${active == 1 ? 'child' : 'children'} currently in the building.',
        ),
        SectionContainer(
          maxWidth: 900,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _ReleasePanel(),
              const SizedBox(height: 24),
              const _CheckInPanel(),
              const SizedBox(height: 32),
              Text('In the building', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              const _Roster(),
              const SizedBox(height: 32),
              const Divider(),
              const SizedBox(height: 12),
              const Text(
                'Pickup codes are shown on the parent\'s phone under My Account. '
                'This app does not print labels - that needs a thermal printer a '
                'browser cannot reach.',
                style: TextStyle(color: Colors.black54, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ReleasePanel extends ConsumerStatefulWidget {
  const _ReleasePanel();

  @override
  ConsumerState<_ReleasePanel> createState() => _ReleasePanelState();
}

class _ReleasePanelState extends ConsumerState<_ReleasePanel> {
  final _code = TextEditingController();
  final _releasedTo = TextEditingController();
  String? _error;
  CheckInSession? _justReleased;

  @override
  void dispose() {
    _code.dispose();
    _releasedTo.dispose();
    super.dispose();
  }

  Future<void> _release() async {
    setState(() {
      _error = null;
      _justReleased = null;
    });

    final result = await ref.read(checkInControllerProvider).release(
          code: _code.text,
          releasedTo: _releasedTo.text,
        );
    if (!mounted) return;

    if (result.ok) {
      setState(() => _justReleased = result.released);
      _code.clear();
      _releasedTo.clear();
      return;
    }

    setState(() {
      _error = switch (result.failure!) {
        ReleaseFailure.noSuchCode => "That code doesn't match anyone checked in right now.",
        // Naming the time and the adult is what resolves a confused
        // pickup - "invalid code" would leave the volunteer stuck.
        ReleaseFailure.alreadyUsed => () {
            final spent = result.spent!;
            final when = spent.codeUsedAt == null
                ? 'earlier'
                : DateFormat.jm().format(spent.codeUsedAt!);
            final who = spent.releasedTo.isEmpty ? '' : ' to ${spent.releasedTo}';
            return '${spent.childName} was already collected at $when$who. '
                'That code has been used.';
          }(),
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    final brand = ref.watch(settingsProvider).colors;

    return Card(
      color: brand.primary.withValues(alpha: 0.04),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.how_to_reg_outlined, color: brand.primary),
                const SizedBox(width: 10),
                // Expanded, not bare: "Pick up a child" plus the icon is
                // wider than a phone once the card padding is taken off.
                Expanded(
                  child: Text('Pick up a child', style: Theme.of(context).textTheme.titleLarge),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // The desk might be a tablet or a phone, so this stacks.
            ResponsiveRow(
              flex: const [2, 3],
              children: [
                TextField(
                  controller: _code,
                  textCapitalization: TextCapitalization.characters,
                  style: const TextStyle(fontSize: 22, letterSpacing: 4, fontWeight: FontWeight.w700),
                  decoration: const InputDecoration(
                    labelText: 'Pickup code',
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => _release(),
                ),
                TextField(
                  controller: _releasedTo,
                  decoration: const InputDecoration(
                    labelText: 'Released to (optional)',
                    hintText: 'Name of the adult collecting',
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => _release(),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: ElevatedButton(onPressed: _release, child: const Text('Release')),
                ),
              ],
            ),
            if (_error != null) ...[
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.error.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, size: 20, color: Theme.of(context).colorScheme.error),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                    ),
                  ],
                ),
              ),
            ],
            if (_justReleased != null) ...[
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_outline, size: 20, color: Colors.green),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '${_justReleased!.childName} released from ${_justReleased!.roomName}.',
                        style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CheckInPanel extends ConsumerStatefulWidget {
  const _CheckInPanel();

  @override
  ConsumerState<_CheckInPanel> createState() => _CheckInPanelState();
}

class _CheckInPanelState extends ConsumerState<_CheckInPanel> {
  final _childName = TextEditingController();
  final _guardianName = TextEditingController();
  final _guardianPhone = TextEditingController();
  final _allergy = TextEditingController();
  Room? _room;
  AppUser? _guardian;
  DateTime? _birthDate;
  CheckInSession? _lastCode;

  @override
  void dispose() {
    for (final c in [_childName, _guardianName, _guardianPhone, _allergy]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (_childName.text.trim().isEmpty || _room == null) return;

    final session = await ref.read(checkInControllerProvider).checkIn(
          childName: _childName.text,
          childBirthDate: _birthDate,
          room: _room!,
          guardianUid: _guardian?.uid ?? '',
          guardianName: _guardian?.displayName ?? _guardianName.text.trim(),
          guardianPhone: _guardianPhone.text,
          allergyNote: _allergy.text,
        );
    if (!mounted || session == null) return;

    _childName.clear();
    _allergy.clear();
    setState(() {
      _birthDate = null;
      _lastCode = session;
    });
  }

  @override
  Widget build(BuildContext context) {
    final rooms = ref.watch(checkInRoomsProvider);
    final members = ref.watch(allMembersProvider).valueOrNull ?? const <AppUser>[];
    final brand = ref.watch(settingsProvider).colors;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Check a child in', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            ResponsiveRow(
              children: [
                TextField(
                  controller: _childName,
                  decoration: const InputDecoration(labelText: "Child's name"),
                ),
                DropdownButtonFormField<Room>(
                  initialValue: _room,
                  decoration: const InputDecoration(labelText: 'Room'),
                  items: [for (final r in rooms) DropdownMenuItem(value: r, child: Text(r.name))],
                  onChanged: (value) => setState(() => _room = value),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ResponsiveRow(
              children: [
                DropdownButtonFormField<AppUser>(
                  initialValue: _guardian,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Guardian'),
                  items: [
                    for (final m in members)
                      DropdownMenuItem(value: m, child: Text(m.displayName.isEmpty ? m.email : m.displayName)),
                  ],
                  onChanged: (value) => setState(() {
                    _guardian = value;
                    _guardianPhone.text = value?.phone ?? '';
                  }),
                ),
                TextField(
                  controller: _guardianPhone,
                  decoration: const InputDecoration(labelText: 'Phone'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ResponsiveRow(
              flex: const [1, 2],
              children: [
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _birthDate ?? DateTime(DateTime.now().year - 6),
                      firstDate: DateTime(1990),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) setState(() => _birthDate = picked);
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(labelText: 'Date of birth (optional)'),
                    child: Text(_birthDate == null ? '—' : DateFormat.yMMMd().format(_birthDate!)),
                  ),
                ),
                TextField(
                  controller: _allergy,
                  decoration: const InputDecoration(
                    labelText: 'Allergies / medical notes',
                    hintText: 'Peanut allergy - epipen in bag',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: _submit,
                icon: const Icon(Icons.login, size: 18),
                label: const Text('Check in'),
              ),
            ),
            if (_lastCode != null) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: brand.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: brand.accent),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_lastCode!.childName} is checked in to ${_lastCode!.roomName}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 10),
                    const Text('PICKUP CODE', style: TextStyle(fontSize: 11, letterSpacing: 1.5)),
                    Text(
                      _lastCode!.pickupCode,
                      style: TextStyle(
                        fontSize: 40,
                        letterSpacing: 8,
                        fontWeight: FontWeight.w700,
                        color: brand.primary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Give this to the adult dropping off. It also appears on their '
                      'phone if they have an account.',
                      style: TextStyle(color: Colors.black54, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Roster extends ConsumerWidget {
  const _Roster();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final byRoom = ref.watch(checkInsByRoomProvider);
    final rooms = ref.watch(checkInRoomsProvider);

    if (byRoom.isEmpty) {
      return const EmptyState(message: 'Nobody is checked in.', icon: Icons.child_care_outlined);
    }

    return AsyncValueWidget<List<CheckInSession>>(
      value: ref.watch(allCheckInsProvider),
      errorContext: 'the check-in roster',
      data: (_) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final entry in byRoom.entries)
            _RoomRoster(
              roomName: rooms.where((r) => r.id == entry.key).map((r) => r.name).firstOrNull ??
                  entry.value.first.roomName,
              capacity: rooms.where((r) => r.id == entry.key).map((r) => r.capacity).firstOrNull ?? 0,
              sessions: entry.value,
            ),
        ],
      ),
    );
  }
}

class _RoomRoster extends ConsumerWidget {
  final String roomName;
  final int capacity;
  final List<CheckInSession> sessions;

  const _RoomRoster({required this.roomName, required this.capacity, required this.sessions});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final over = capacity > 0 && sessions.length > capacity;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(roomName, style: Theme.of(context).textTheme.titleMedium)),
                Chip(
                  label: Text(capacity > 0 ? '${sessions.length} / $capacity' : '${sessions.length}'),
                  labelStyle: TextStyle(
                    color: over ? Theme.of(context).colorScheme.error : Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            if (over)
              Text(
                'Over capacity - check the ratio.',
                style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12),
              ),
            const SizedBox(height: 8),
            for (final session in sessions) _RosterRow(session: session),
          ],
        ),
      ),
    );
  }
}

class _RosterRow extends ConsumerWidget {
  final CheckInSession session;

  const _RosterRow({required this.session});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final age = session.ageYears;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      title: Row(
        children: [
          Text(session.childName, style: const TextStyle(fontWeight: FontWeight.w600)),
          if (age != null) ...[
            const SizedBox(width: 8),
            Text('age $age', style: const TextStyle(color: Colors.black54, fontSize: 12)),
          ],
          if (session.hasAllergyNote) ...[
            const SizedBox(width: 8),
            Tooltip(
              message: session.allergyNote,
              child: Icon(Icons.warning_amber_rounded, size: 18, color: Colors.orange.shade800),
            ),
          ],
        ],
      ),
      subtitle: Text(
        [
          if (session.guardianName.isNotEmpty) session.guardianName,
          if (session.guardianPhone.isNotEmpty) session.guardianPhone,
          'in at ${DateFormat.jm().format(session.checkedInAt)}',
        ].join(' · '),
        style: const TextStyle(fontSize: 12),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            session.pickupCode,
            style: const TextStyle(letterSpacing: 3, fontWeight: FontWeight.w700),
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'Release without a code (staff override)',
            icon: const Icon(Icons.lock_open_outlined, size: 18),
            onPressed: () async {
              final to = await showDialog<String>(
                context: context,
                builder: (_) => _OverrideDialog(childName: session.childName),
              );
              if (to == null) return;
              await ref.read(checkInControllerProvider).releaseWithoutCode(session, releasedTo: to);
            },
          ),
        ],
      ),
    );
  }
}

class _OverrideDialog extends StatefulWidget {
  final String childName;

  const _OverrideDialog({required this.childName});

  @override
  State<_OverrideDialog> createState() => _OverrideDialogState();
}

class _OverrideDialogState extends State<_OverrideDialog> {
  final _to = TextEditingController();

  @override
  void dispose() {
    _to.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Release ${widget.childName} without a code?'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Use this only when the code is genuinely lost and you have '
              'identified the adult another way. It is recorded as an override.',
              style: TextStyle(height: 1.5),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _to,
              decoration: const InputDecoration(
                labelText: 'Released to',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: () => Navigator.pop(context, _to.text.trim()),
          child: const Text('Release'),
        ),
      ],
    );
  }
}
