import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../core/config/settings_providers.dart';
import '../../audit_log/application/audit_providers.dart';
import '../../auth/application/auth_providers.dart';
import '../../auth/domain/app_user.dart';
import 'admin_header.dart';

class MembersAdminScreen extends ConsumerStatefulWidget {
  const MembersAdminScreen({super.key});

  @override
  ConsumerState<MembersAdminScreen> createState() => _MembersAdminScreenState();
}

class _MembersAdminScreenState extends ConsumerState<MembersAdminScreen> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _search.text.trim().toLowerCase();
    final members = ref.watch(allMembersProvider).whenData(
          (list) => query.isEmpty
              ? list
              : list
                  .where((m) =>
                      m.displayName.toLowerCase().contains(query) || m.email.toLowerCase().contains(query))
                  .toList(),
        );

    return AdminListScaffold<AppUser>(
      title: 'Members',
      subtitle: 'Search the congregation and set who can manage the app.',
      value: members,
      errorContext: 'members',
      emptyMessage: query.isEmpty ? 'No members yet.' : 'No members match that search.',
      maxWidth: 820,
      aboveList: TextField(
        controller: _search,
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          hintText: 'Search by name or email',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: query.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _search.clear();
                    setState(() {});
                  },
                ),
        ),
      ),
      itemBuilder: (member) => _MemberRow(member: member),
    );
  }
}

class _MemberRow extends ConsumerWidget {
  final AppUser member;

  const _MemberRow({required this.member});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(currentUserProvider);
    final isSelf = me?.uid == member.uid;
    final brand = ref.watch(settingsProvider).colors;

    final avatar = CircleAvatar(
      backgroundColor: brand.primary.withValues(alpha: 0.1),
      child: Text(member.initial, style: TextStyle(color: brand.primary, fontWeight: FontWeight.w700)),
    );
    final name = Text(
      member.displayName.isEmpty ? member.email : member.displayName,
      style: const TextStyle(fontWeight: FontWeight.w600),
    );
    final email = Text(member.email);

    final rolePicker = DropdownButtonFormField<UserRole>(
      isExpanded: true,
      initialValue: member.role,
      decoration: InputDecoration(
        isDense: true,
        // An admin demoting themselves could lock the church out of
        // its own settings, so that one path is blocked.
        helperText: isSelf ? "Can't change your own role" : null,
        helperMaxLines: 2,
      ),
      items: [
        for (final role in UserRole.values)
          DropdownMenuItem(value: role, child: Text(_label(role))),
      ],
      onChanged: isSelf
          ? null
          : (role) async {
              if (role == null || role == member.role) return;
              await ref.read(userRepositoryProvider).updateRole(member.uid, role);
              await ref.read(auditLoggerProvider).record(
                    action: 'changed role',
                    entity: 'member',
                    details: '${member.displayName} → ${role.name}',
                  );
              ref.invalidate(allMembersProvider);
            },
    );

    // A 170px role picker in `ListTile.trailing` left sixty-eight pixels
    // for the email beside it, which is enough to spell an address one
    // letter per line. On a phone the picker goes underneath instead.
    if (Breakpoints.isMobile(context)) {
      return Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  avatar,
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        name,
                        DefaultTextStyle.merge(
                          style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color),
                          child: email,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              rolePicker,
            ],
          ),
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: avatar,
        title: name,
        subtitle: email,
        trailing: SizedBox(width: 170, child: rolePicker),
      ),
    );
  }

  static String _label(UserRole role) => switch (role) {
        UserRole.member => 'Member',
        UserRole.staff => 'Staff',
        UserRole.admin => 'Admin',
      };
}
