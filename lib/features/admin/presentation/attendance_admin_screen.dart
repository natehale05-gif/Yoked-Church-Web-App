import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../app/theme.dart';
import '../../../core/config/settings_providers.dart';
import '../../../core/widgets/app_shell.dart';
import '../../../core/widgets/async_value_widget.dart';
import '../../../core/widgets/responsive.dart';
import '../../../core/widgets/section_container.dart';
import '../../attendance/application/attendance_providers.dart';
import '../../attendance/domain/attendance_record.dart';
import '../../groups/application/group_providers.dart';
import '../../groups/domain/group.dart';
import 'admin_header.dart';

/// Take attendance, then look back at it. Deliberately one screen: the
/// number you just entered only means something next to the last few
/// weeks, and a church that has to navigate to see that won't bother.
class AttendanceAdminScreen extends ConsumerWidget {
  const AttendanceAdminScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final series = ref.watch(attendanceSeriesProvider);

    return PageBody(
      children: [
        AdminHeader(
          title: 'Attendance',
          subtitle: series.isEmpty
              ? 'Nothing recorded yet. Start with last Sunday.'
              : '${series.length} gathering${series.length == 1 ? '' : 's'} tracked.',
        ),
        SectionContainer(
          maxWidth: 900,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _RecordPanel(),
              const SizedBox(height: 32),
              Text('History', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              AsyncValueWidget<List<AttendanceRecord>>(
                value: ref.watch(allAttendanceProvider),
                errorContext: 'attendance records',
                data: (_) => series.isEmpty
                    ? const EmptyState(
                        message: 'No attendance recorded yet.',
                        icon: Icons.how_to_reg_outlined,
                      )
                    : Column(children: [for (final s in series) _SeriesCard(series: s)]),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RecordPanel extends ConsumerStatefulWidget {
  const _RecordPanel();

  @override
  ConsumerState<_RecordPanel> createState() => _RecordPanelState();
}

class _RecordPanelState extends ConsumerState<_RecordPanel> {
  final _headcount = TextEditingController();
  final _note = TextEditingController();
  Gathering? _gathering;
  DateTime _date = dayOf(DateTime.now());
  final Set<String> _present = {};
  bool _saved = false;

  @override
  void dispose() {
    _headcount.dispose();
    _note.dispose();
    super.dispose();
  }

  bool get _isGroup => _gathering?.type == GatheringType.group;

  Future<void> _submit() async {
    final gathering = _gathering;
    if (gathering == null) return;

    final controller = ref.read(attendanceControllerProvider);
    if (_isGroup) {
      await controller.recordRoster(
        gathering: gathering,
        date: _date,
        presentUids: _present.toList(),
        note: _note.text,
      );
    } else {
      final count = int.tryParse(_headcount.text.trim());
      if (count == null) return;
      await controller.recordHeadcount(
        gathering: gathering,
        date: _date,
        headcount: count,
        note: _note.text,
      );
    }
    if (!mounted) return;

    _headcount.clear();
    _note.clear();
    setState(() {
      _present.clear();
      _saved = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final gatherings = ref.watch(gatheringsProvider);
    final brand = ref.watch(settingsProvider).colors;

    return Card(
      color: brand.primary.withValues(alpha: 0.04),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Record attendance', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            if (gatherings.isEmpty)
              const Text(
                'Add a service time in Settings, or an event or group, before '
                'recording attendance.',
                style: TextStyle(color: Colors.black54),
              )
            else ...[
              // Side by side these two left the date sixty-three pixels on
              // a phone, which is not enough to write a date on one line.
              ResponsiveRow(
                flex: const [2, 1],
                children: [
                  DropdownButtonFormField<Gathering>(
                    initialValue: _gathering,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Gathering'),
                    items: [
                      for (final g in gatherings)
                        DropdownMenuItem(value: g, child: Text('${_typeLabel(g.type)} · ${g.name}')),
                    ],
                    onChanged: (value) => setState(() {
                      _gathering = value;
                      _present.clear();
                      _saved = false;
                    }),
                  ),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _date,
                        firstDate: DateTime(DateTime.now().year - 5),
                        lastDate: DateTime.now().add(const Duration(days: 1)),
                      );
                      if (picked != null) setState(() => _date = dayOf(picked));
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(labelText: 'Date'),
                      child: Text(DateFormat.yMMMEd().format(_date)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (_isGroup)
                _RosterPicker(
                  groupId: _gathering!.id,
                  present: _present,
                  onToggle: (uid, on) => setState(() {
                    _saved = false;
                    on ? _present.add(uid) : _present.remove(uid);
                  }),
                )
              else
                SizedBox(
                  // Full width on a phone; a 200px box beside nothing just
                  // looks like something failed to load.
                  width: Breakpoints.isMobile(context) ? double.infinity : 200,
                  child: TextField(
                    controller: _headcount,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Headcount',
                      hintText: '124',
                    ),
                    onChanged: (_) => setState(() => _saved = false),
                  ),
                ),
              const SizedBox(height: 8),
              TextField(
                controller: _note,
                decoration: const InputDecoration(
                  labelText: 'Note (optional)',
                  hintText: 'Snow - roads were bad',
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  if (_saved)
                    const Expanded(
                      child: Row(
                        children: [
                          Icon(Icons.check_circle_outline, size: 18, color: Colors.green),
                          SizedBox(width: 8),
                          Text('Saved.', style: TextStyle(color: Colors.green)),
                        ],
                      ),
                    )
                  else
                    const Spacer(),
                  ElevatedButton.icon(
                    onPressed: _gathering == null ? null : _submit,
                    icon: const Icon(Icons.save_outlined, size: 18),
                    label: const Text('Save'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Recording the same gathering and date again replaces that '
                'record rather than adding a second one.',
                style: TextStyle(color: Colors.black54, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// The group's approved roster, as checkboxes. Pending members are left
/// out: they haven't been let into the group yet, so marking them present
/// would put someone on a roster they were never added to.
class _RosterPicker extends ConsumerWidget {
  final String groupId;
  final Set<String> present;
  final void Function(String uid, bool on) onToggle;

  const _RosterPicker({required this.groupId, required this.present, required this.onToggle});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memberships = ref.watch(groupMembershipsProvider(groupId)).valueOrNull;
    if (memberships == null) {
      return const Padding(padding: EdgeInsets.all(16), child: LinearProgressIndicator());
    }

    final roster = memberships.where((m) => m.status == MembershipStatus.approved).toList()
      ..sort((a, b) => a.memberName.compareTo(b.memberName));

    if (roster.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Text(
          'Nobody has been approved into this group yet.',
          style: TextStyle(color: Colors.black54),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${present.length} of ${roster.length} present',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            for (final m in roster)
              FilterChip(
                label: Text(m.memberName.isEmpty ? m.uid : m.memberName),
                selected: present.contains(m.uid),
                onSelected: (on) => onToggle(m.uid, on),
              ),
          ],
        ),
      ],
    );
  }
}

class _SeriesCard extends ConsumerWidget {
  final AttendanceSeries series;

  const _SeriesCard({required this.series});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        title: Text(series.gatheringName, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(
          '${_typeLabel(series.type)} · averaging ${series.average} '
          'over ${series.occasions} ${series.occasions == 1 ? 'occasion' : 'occasions'}',
          style: const TextStyle(fontSize: 12),
        ),
        children: [
          for (final record in series.records)
            ListTile(
              dense: true,
              title: Text(DateFormat.yMMMEd().format(record.date)),
              subtitle: record.note.isEmpty
                  ? null
                  : Text(record.note, style: const TextStyle(fontStyle: FontStyle.italic)),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${record.effectiveCount}',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                  if (record.isPerPerson)
                    const Padding(
                      padding: EdgeInsets.only(left: 6),
                      child: Tooltip(
                        message: 'Counted person by person',
                        child: Icon(Icons.checklist_rtl, size: 16, color: Colors.black45),
                      ),
                    ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 18),
                    tooltip: 'Delete this record',
                    onPressed: () async {
                      if (!await confirmDelete(
                        context,
                        'the ${DateFormat.yMMMd().format(record.date)} record for '
                        '${record.gatheringName}',
                      )) {
                        return;
                      }
                      await ref.read(attendanceControllerProvider).deleteRecord(record.id);
                    },
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

String _typeLabel(GatheringType type) => switch (type) {
      GatheringType.service => 'Service',
      GatheringType.event => 'Event',
      GatheringType.group => 'Group',
    };
