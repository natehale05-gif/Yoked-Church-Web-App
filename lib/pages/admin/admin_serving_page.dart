import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/app_icons.dart';
import '../../models/serving.dart';
import '../../state/members_controller.dart';
import '../../state/serving_controller.dart';
import '../../theme/app_colors.dart';
import '../../widgets/admin_ui.dart';
import '../../widgets/buttons.dart';
import 'admin_attendance_page.dart' show formatDate;

class AdminServingPage extends StatelessWidget {
  const AdminServingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final serving = context.watch<ServingController>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AdminHeader(
          title: 'Serving',
          subtitle: 'Organize teams and schedule volunteers to serve.',
          action: PrimaryButton(
            label: 'Add team',
            icon: Icons.add,
            onPressed: () => _editTeam(context),
          ),
        ),
        if (serving.teams.isEmpty)
          const Panel(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Text('No serving teams yet. Create one to start '
                  'scheduling volunteers.',
                  style: TextStyle(color: AppColors.inkSoft)),
            ),
          )
        else
          for (final team in serving.teams) ...[
            _TeamPanel(team: team),
            const SizedBox(height: 18),
          ],
      ],
    );
  }

  static Future<void> _editTeam(BuildContext context, {ServingTeam? existing}) async {
    final result = await showDialog<ServingTeam>(
      context: context,
      builder: (_) => _TeamEditor(existing: existing),
    );
    if (result != null && context.mounted) {
      context.read<ServingController>().upsertTeam(result);
    }
  }
}

class _TeamPanel extends StatelessWidget {
  final ServingTeam team;
  const _TeamPanel({required this.team});

  @override
  Widget build(BuildContext context) {
    final serving = context.watch<ServingController>();
    final members = context.watch<MembersController>();
    final slots = serving.slotsForTeam(team.id);

    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.cream,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(iconForKey(team.iconKey), color: AppColors.navy),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(team.name,
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink)),
                    Text(team.description,
                        style: const TextStyle(
                            fontSize: 13.5, color: AppColors.inkSoft)),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Edit team',
                icon: const Icon(Icons.edit_outlined, size: 20),
                color: AppColors.inkSoft,
                onPressed: () => AdminServingPage._editTeam(context, existing: team),
              ),
              IconButton(
                tooltip: 'Delete team',
                icon: const Icon(Icons.delete_outline, size: 20),
                color: AppColors.inkSoft,
                onPressed: () =>
                    context.read<ServingController>().removeTeam(team.id),
              ),
            ],
          ),
          const Divider(height: 24),
          if (slots.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('No scheduled slots yet.',
                  style: TextStyle(color: AppColors.inkSoft)),
            )
          else
            for (final s in slots)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s.title,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                  color: AppColors.ink)),
                          const SizedBox(height: 2),
                          Text('${formatDate(s.date)}  ·  ${s.time}',
                              style: const TextStyle(
                                  fontSize: 13, color: AppColors.inkSoft)),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              for (final id in s.memberIds)
                                StatusPill(
                                  label:
                                      members.byId(id)?.fullName ?? 'Member',
                                  color: AppColors.navy,
                                ),
                              if (s.remaining > 0)
                                StatusPill(
                                    label: '${s.remaining} spot'
                                        '${s.remaining == 1 ? '' : 's'} open',
                                    color: AppColors.gold),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Text('${s.filled}/${s.needed}',
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.navy)),
                    IconButton(
                      tooltip: 'Edit slot',
                      icon: const Icon(Icons.edit_outlined, size: 19),
                      color: AppColors.inkSoft,
                      onPressed: () => _editSlot(context, team, existing: s),
                    ),
                    IconButton(
                      tooltip: 'Delete slot',
                      icon: const Icon(Icons.delete_outline, size: 19),
                      color: AppColors.inkSoft,
                      onPressed: () =>
                          context.read<ServingController>().removeSlot(s.id),
                    ),
                  ],
                ),
              ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => _editSlot(context, team),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add serving slot'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _editSlot(BuildContext context, ServingTeam team,
      {ServingSlot? existing}) async {
    final result = await showDialog<ServingSlot>(
      context: context,
      builder: (_) => _SlotEditor(teamId: team.id, existing: existing),
    );
    if (result != null && context.mounted) {
      context.read<ServingController>().upsertSlot(result);
    }
  }
}

class _TeamEditor extends StatefulWidget {
  final ServingTeam? existing;
  const _TeamEditor({this.existing});

  @override
  State<_TeamEditor> createState() => _TeamEditorState();
}

class _TeamEditorState extends State<_TeamEditor> {
  late final _name = TextEditingController(text: widget.existing?.name);
  late final _desc = TextEditingController(text: widget.existing?.description);
  late String _iconKey = widget.existing?.iconKey ?? 'handshake';

  @override
  void dispose() {
    _name.dispose();
    _desc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: Text(widget.existing == null ? 'Add team' : 'Edit team'),
      content: SizedBox(
        width: 440,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const FieldLabel('Team name'),
            AdminField(controller: _name),
            const SizedBox(height: 12),
            const FieldLabel('Description'),
            AdminField(controller: _desc, maxLines: 2),
            const SizedBox(height: 12),
            const FieldLabel('Icon'),
            IconPicker(
              selected: _iconKey,
              onSelected: (k) => setState(() => _iconKey = k),
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
          onPressed: () {
            if (_name.text.trim().isEmpty) return;
            final base = widget.existing ??
                ServingTeam(name: '', description: '', iconKey: _iconKey);
            Navigator.pop(
              context,
              base.copyWith(
                name: _name.text.trim(),
                description: _desc.text.trim(),
                iconKey: _iconKey,
              ),
            );
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class _SlotEditor extends StatefulWidget {
  final String teamId;
  final ServingSlot? existing;
  const _SlotEditor({required this.teamId, this.existing});

  @override
  State<_SlotEditor> createState() => _SlotEditorState();
}

class _SlotEditorState extends State<_SlotEditor> {
  late final _title = TextEditingController(text: widget.existing?.title);
  late final _time = TextEditingController(text: widget.existing?.time ?? '9:00 AM');
  late final _needed =
      TextEditingController(text: (widget.existing?.needed ?? 1).toString());
  late DateTime _date = widget.existing?.date ?? DateTime.now();

  @override
  void dispose() {
    _title.dispose();
    _time.dispose();
    _needed.dispose();
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

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: Text(widget.existing == null ? 'Add serving slot' : 'Edit slot'),
      content: SizedBox(
        width: 440,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const FieldLabel('Role / title'),
            AdminField(controller: _title, hint: 'e.g. Door Greeter'),
            const SizedBox(height: 12),
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
                              horizontal: 12, vertical: 14),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 110,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const FieldLabel('Needed'),
                      AdminField(
                          controller: _needed,
                          keyboardType: TextInputType.number),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const FieldLabel('Time'),
            AdminField(controller: _time),
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
          onPressed: () {
            if (_title.text.trim().isEmpty) return;
            final needed = int.tryParse(_needed.text.trim()) ?? 1;
            final base = widget.existing ??
                ServingSlot(
                    teamId: widget.teamId,
                    title: '',
                    date: _date,
                    time: _time.text);
            Navigator.pop(
              context,
              base.copyWith(
                title: _title.text.trim(),
                date: _date,
                time: _time.text.trim(),
                needed: needed < 1 ? 1 : needed,
              ),
            );
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

/// A compact grid of selectable icons used by team + content editors.
class IconPicker extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelected;
  const IconPicker({super.key, required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final key in kAppIconKeys)
          InkWell(
            onTap: () => onSelected(key),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: selected == key ? AppColors.navy : AppColors.ivory,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: selected == key ? AppColors.navy : AppColors.line,
                ),
              ),
              child: Icon(
                iconForKey(key),
                color: selected == key ? AppColors.onDark : AppColors.inkSoft,
                size: 22,
              ),
            ),
          ),
      ],
    );
  }
}
