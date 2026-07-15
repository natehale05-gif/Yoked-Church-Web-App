import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/member.dart';
import '../../state/attendance_controller.dart';
import '../../state/members_controller.dart';
import '../../theme/app_colors.dart';
import '../../widgets/admin_ui.dart';
import '../../widgets/buttons.dart';

class AdminMembersPage extends StatefulWidget {
  const AdminMembersPage({super.key});

  @override
  State<AdminMembersPage> createState() => _AdminMembersPageState();
}

class _AdminMembersPageState extends State<AdminMembersPage> {
  String _query = '';
  MemberStatus? _filter;

  Color _statusColor(MemberStatus s) => switch (s) {
        MemberStatus.member => const Color(0xFF3E7C5A),
        MemberStatus.regular => const Color(0xFF2F6DB0),
        MemberStatus.visitor => AppColors.gold,
        MemberStatus.inactive => AppColors.inkSoft,
      };

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<MembersController>();
    var list = controller.members;
    if (_query.isNotEmpty) {
      final q = _query.toLowerCase();
      list = list
          .where((m) =>
              m.fullName.toLowerCase().contains(q) ||
              m.email.toLowerCase().contains(q))
          .toList();
    }
    if (_filter != null) {
      list = list.where((m) => m.status == _filter).toList();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AdminHeader(
          title: 'Members',
          subtitle: 'Keep track of everyone in your church community.',
          action: PrimaryButton(
            label: 'Add member',
            icon: Icons.person_add_alt,
            onPressed: () => _openEditor(context),
          ),
        ),
        Panel(
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      onChanged: (v) => setState(() => _query = v),
                      decoration: InputDecoration(
                        hintText: 'Search by name or email…',
                        prefixIcon: const Icon(Icons.search),
                        isDense: true,
                        filled: true,
                        fillColor: AppColors.ivory,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.line),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.line),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Align(
                alignment: Alignment.centerLeft,
                child: Wrap(
                  spacing: 8,
                  children: [
                    _filterChip('All', null),
                    for (final s in MemberStatus.values)
                      _filterChip(s.label, s),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              const Divider(height: 24),
              if (list.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Text('No members match your search.',
                      style: TextStyle(color: AppColors.inkSoft)),
                )
              else
                for (final m in list) _memberRow(context, controller, m),
            ],
          ),
        ),
      ],
    );
  }

  Widget _filterChip(String label, MemberStatus? status) {
    final selected = _filter == status;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() => _filter = status),
      showCheckmark: false,
      selectedColor: AppColors.navy,
      backgroundColor: AppColors.ivory,
      labelStyle: TextStyle(
        color: selected ? AppColors.onDark : AppColors.ink,
        fontWeight: FontWeight.w600,
        fontSize: 13,
      ),
      side: const BorderSide(color: AppColors.line),
    );
  }

  Widget _memberRow(
      BuildContext context, MembersController controller, Member m) {
    final attended = context.read<AttendanceController>().attendedCountFor(m.id);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.cream,
            child: Text(m.initials,
                style: const TextStyle(
                    color: AppColors.navy, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 14),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(m.fullName,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: AppColors.ink)),
                if (m.email.isNotEmpty)
                  Text(m.email,
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.inkSoft)),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: StatusPill(label: m.status.label, color: _statusColor(m.status)),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text('$attended gatherings',
                style: const TextStyle(fontSize: 13, color: AppColors.inkSoft)),
          ),
          IconButton(
            tooltip: 'Edit',
            icon: const Icon(Icons.edit_outlined, size: 20),
            color: AppColors.inkSoft,
            onPressed: () => _openEditor(context, existing: m),
          ),
          IconButton(
            tooltip: 'Delete',
            icon: const Icon(Icons.delete_outline, size: 20),
            color: AppColors.inkSoft,
            onPressed: () => _confirmDelete(context, controller, m),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, MembersController controller, Member m) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remove member?'),
        content: Text('Remove ${m.fullName} from your records?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFB3261E)),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (ok == true) controller.remove(m.id);
  }

  Future<void> _openEditor(BuildContext context, {Member? existing}) async {
    final result = await showDialog<Member>(
      context: context,
      builder: (_) => _MemberEditor(existing: existing),
    );
    if (result != null && context.mounted) {
      context.read<MembersController>().upsert(result);
    }
  }
}

class _MemberEditor extends StatefulWidget {
  final Member? existing;
  const _MemberEditor({this.existing});

  @override
  State<_MemberEditor> createState() => _MemberEditorState();
}

class _MemberEditorState extends State<_MemberEditor> {
  final _formKey = GlobalKey<FormState>();
  late final _first = TextEditingController(text: widget.existing?.firstName);
  late final _last = TextEditingController(text: widget.existing?.lastName);
  late final _email = TextEditingController(text: widget.existing?.email);
  late final _phone = TextEditingController(text: widget.existing?.phone);
  late final _household = TextEditingController(text: widget.existing?.household);
  late final _notes = TextEditingController(text: widget.existing?.notes);
  late MemberStatus _status = widget.existing?.status ?? MemberStatus.visitor;

  @override
  void dispose() {
    _first.dispose();
    _last.dispose();
    _email.dispose();
    _phone.dispose();
    _household.dispose();
    _notes.dispose();
    super.dispose();
  }

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final base = widget.existing ??
        Member(firstName: '', lastName: '', status: _status);
    Navigator.pop(
      context,
      base.copyWith(
        firstName: _first.text.trim(),
        lastName: _last.text.trim(),
        email: _email.text.trim(),
        phone: _phone.text.trim(),
        household: _household.text.trim(),
        notes: _notes.text.trim(),
        status: _status,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: Text(widget.existing == null ? 'Add member' : 'Edit member'),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
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
                          const FieldLabel('First name'),
                          AdminField(
                            controller: _first,
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Required'
                                : null,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const FieldLabel('Last name'),
                          AdminField(controller: _last),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const FieldLabel('Email'),
                AdminField(
                    controller: _email, keyboardType: TextInputType.emailAddress),
                const SizedBox(height: 12),
                const FieldLabel('Phone'),
                AdminField(controller: _phone),
                const SizedBox(height: 12),
                const FieldLabel('Household'),
                AdminField(controller: _household),
                const SizedBox(height: 12),
                const FieldLabel('Status'),
                DropdownButtonFormField<MemberStatus>(
                  initialValue: _status,
                  decoration: InputDecoration(
                    isDense: true,
                    filled: true,
                    fillColor: AppColors.ivory,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.line),
                    ),
                  ),
                  items: [
                    for (final s in MemberStatus.values)
                      DropdownMenuItem(value: s, child: Text(s.label)),
                  ],
                  onChanged: (v) =>
                      setState(() => _status = v ?? MemberStatus.visitor),
                ),
                const SizedBox(height: 12),
                const FieldLabel('Notes'),
                AdminField(controller: _notes, maxLines: 3),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          style: FilledButton.styleFrom(
              backgroundColor: AppColors.navy, foregroundColor: AppColors.onDark),
          onPressed: _save,
          child: const Text('Save'),
        ),
      ],
    );
  }
}
