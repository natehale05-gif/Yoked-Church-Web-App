import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/attendance.dart';
import '../../models/member.dart';
import '../../state/attendance_controller.dart';
import '../../state/members_controller.dart';
import '../../theme/app_colors.dart';
import '../../widgets/admin_ui.dart';
import '../../widgets/buttons.dart';

String formatDate(DateTime d) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
  return '${months[d.month - 1]} ${d.day}, ${d.year}';
}

class AdminAttendancePage extends StatelessWidget {
  const AdminAttendancePage({super.key});

  @override
  Widget build(BuildContext context) {
    final attendance = context.watch<AttendanceController>();
    final records = attendance.records;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AdminHeader(
          title: 'Attendance',
          subtitle: 'Record who was present and watch your trends over time.',
          action: PrimaryButton(
            label: 'Record attendance',
            icon: Icons.add_task,
            onPressed: () => _record(context),
          ),
        ),
        Row(
          children: [
            Expanded(
              child: StatCard(
                icon: Icons.groups_outlined,
                value: attendance.averageTotal.round().toString(),
                label: 'Average attendance',
                accent: AppColors.navy,
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: StatCard(
                icon: Icons.event_available_outlined,
                value: '${records.length}',
                label: 'Gatherings recorded',
                accent: const Color(0xFF2F6DB0),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('History',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink)),
              const SizedBox(height: 8),
              if (records.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 28),
                  child: Text('No attendance recorded yet. Tap “Record '
                      'attendance” to add your first entry.',
                      style: TextStyle(color: AppColors.inkSoft)),
                )
              else
                for (final r in records) ...[
                  _row(context, r),
                  if (r != records.last) const Divider(height: 1),
                ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _row(BuildContext context, AttendanceRecord r) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.cream,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.event_available, color: AppColors.navy),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(r.serviceLabel,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: AppColors.ink)),
                Text(
                    '${formatDate(r.date)}  ·  ${r.presentMemberIds.length} members'
                    '  ·  ${r.visitorCount} visitors',
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.inkSoft)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${r.total}',
                  style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.navy)),
              const Text('total',
                  style: TextStyle(fontSize: 11, color: AppColors.inkSoft)),
            ],
          ),
          IconButton(
            tooltip: 'Edit',
            icon: const Icon(Icons.edit_outlined, size: 20),
            color: AppColors.inkSoft,
            onPressed: () => _record(context, existing: r),
          ),
          IconButton(
            tooltip: 'Delete',
            icon: const Icon(Icons.delete_outline, size: 20),
            color: AppColors.inkSoft,
            onPressed: () =>
                context.read<AttendanceController>().remove(r.id),
          ),
        ],
      ),
    );
  }

  Future<void> _record(BuildContext context, {AttendanceRecord? existing}) async {
    final result = await showDialog<AttendanceRecord>(
      context: context,
      builder: (_) => _AttendanceEditor(existing: existing),
    );
    if (result != null && context.mounted) {
      context.read<AttendanceController>().upsert(result);
    }
  }
}

class _AttendanceEditor extends StatefulWidget {
  final AttendanceRecord? existing;
  const _AttendanceEditor({this.existing});

  @override
  State<_AttendanceEditor> createState() => _AttendanceEditorState();
}

class _AttendanceEditorState extends State<_AttendanceEditor> {
  late DateTime _date = widget.existing?.date ?? DateTime.now();
  late final _label = TextEditingController(
      text: widget.existing?.serviceLabel ?? 'Sunday Morning');
  late final _visitors = TextEditingController(
      text: (widget.existing?.visitorCount ?? 0).toString());
  late final Set<String> _present = {...?widget.existing?.presentMemberIds};

  @override
  void dispose() {
    _label.dispose();
    _visitors.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2015),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _date = picked);
  }

  void _save() {
    final base = widget.existing ??
        AttendanceRecord(date: _date, serviceLabel: _label.text);
    Navigator.pop(
      context,
      base.copyWith(
        date: _date,
        serviceLabel: _label.text.trim().isEmpty
            ? 'Gathering'
            : _label.text.trim(),
        presentMemberIds: _present.toList(),
        visitorCount: int.tryParse(_visitors.text.trim()) ?? 0,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final members = context.watch<MembersController>().members;
    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: Text(widget.existing == null
          ? 'Record attendance'
          : 'Edit attendance'),
      content: SizedBox(
        width: 480,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const FieldLabel('Date'),
                      OutlinedButton.icon(
                        onPressed: _pickDate,
                        icon: const Icon(Icons.calendar_today, size: 16),
                        label: Text(formatDate(_date)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.ink,
                          side: const BorderSide(color: AppColors.line),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 14),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const FieldLabel('Visitors'),
                      AdminField(
                          controller: _visitors,
                          keyboardType: TextInputType.number),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const FieldLabel('Gathering'),
            AdminField(controller: _label),
            const SizedBox(height: 16),
            Row(
              children: [
                const FieldLabel('Who was present?'),
                const Spacer(),
                Text('${_present.length} selected',
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.inkSoft)),
              ],
            ),
            const SizedBox(height: 4),
            Container(
              constraints: const BoxConstraints(maxHeight: 260),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.line),
                borderRadius: BorderRadius.circular(12),
              ),
              child: members.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(20),
                      child: Text('Add members first to check them in.',
                          style: TextStyle(color: AppColors.inkSoft)),
                    )
                  : ListView(
                      shrinkWrap: true,
                      children: [
                        for (final Member m in members)
                          CheckboxListTile(
                            dense: true,
                            controlAffinity:
                                ListTileControlAffinity.leading,
                            activeColor: AppColors.navy,
                            value: _present.contains(m.id),
                            title: Text(m.fullName,
                                style: const TextStyle(fontSize: 14)),
                            onChanged: (v) => setState(() {
                              if (v == true) {
                                _present.add(m.id);
                              } else {
                                _present.remove(m.id);
                              }
                            }),
                          ),
                      ],
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel')),
        FilledButton(
          style: FilledButton.styleFrom(
              backgroundColor: AppColors.navy,
              foregroundColor: AppColors.onDark),
          onPressed: _save,
          child: const Text('Save'),
        ),
      ],
    );
  }
}
