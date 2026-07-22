import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/app_user.dart';
import '../../providers/auth_provider.dart';
import '../../services/user_service.dart';
import '../../widgets/admin_header.dart';
import '../../widgets/section_container.dart';

class MembersAdminScreen extends StatefulWidget {
  const MembersAdminScreen({super.key});

  @override
  State<MembersAdminScreen> createState() => _MembersAdminScreenState();
}

class _MembersAdminScreenState extends State<MembersAdminScreen> {
  final UserService _service = UserService();
  late Future<List<AppUser>> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.fetchAllUsers();
  }

  void _refresh() => setState(() => _future = _service.fetchAllUsers());

  Future<void> _changeRole(AppUser member, UserRole newRole) async {
    if (newRole == member.role) return;
    await _service.updateRole(member.uid, newRole);
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final myUid = context.watch<AuthProvider>().currentUser?.uid;

    return Column(
      children: [
        const AdminHeader(title: 'Members', subtitle: 'Promote or demote member roles.'),
        SectionContainer(
          maxWidth: 800,
          child: FutureBuilder<List<AppUser>>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 60),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final members = snapshot.data ?? [];
              if (members.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 60),
                  child: Center(child: Text('No members yet.')),
                );
              }
              return Column(
                children: members.map((member) {
                  final isSelf = member.uid == myUid;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      title: Text(
                        member.displayName.isEmpty ? member.email : member.displayName,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(member.email),
                      trailing: SizedBox(
                        width: 160,
                        child: DropdownButtonFormField<UserRole>(
                          initialValue: member.role,
                          items: UserRole.values
                              .map((role) => DropdownMenuItem(value: role, child: Text(_roleLabel(role))))
                              .toList(),
                          onChanged: isSelf ? null : (role) => role != null ? _changeRole(member, role) : null,
                          decoration: InputDecoration(
                            isDense: true,
                            border: const OutlineInputBorder(),
                            helperText: isSelf ? "Can't change your own role" : null,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ),
      ],
    );
  }

  String _roleLabel(UserRole role) {
    switch (role) {
      case UserRole.member:
        return 'Member';
      case UserRole.staff:
        return 'Staff';
      case UserRole.admin:
        return 'Admin';
    }
  }
}
