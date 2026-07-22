import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../config/church_config.dart';
import '../../models/church_group.dart';
import '../../models/group_membership.dart';
import '../../providers/auth_provider.dart';
import '../../services/group_service.dart';
import '../../widgets/account_header.dart';
import '../../widgets/section_container.dart';

class GroupsScreen extends StatefulWidget {
  const GroupsScreen({super.key});

  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen> {
  final GroupService _service = GroupService();
  late Future<(List<ChurchGroup>, List<GroupMembership>)> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<(List<ChurchGroup>, List<GroupMembership>)> _load() async {
    final uid = context.read<AuthProvider>().currentUser?.uid ?? '';
    final groups = await _service.fetchGroups();
    final memberships = uid.isEmpty ? <GroupMembership>[] : await _service.fetchMyMemberships(uid);
    return (groups, memberships);
  }

  Future<void> _join(ChurchGroup group) async {
    final uid = context.read<AuthProvider>().currentUser?.uid;
    if (uid == null) return;
    await _service.requestToJoin(groupId: group.id, uid: uid);
    setState(() => _future = _load());
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const AccountHeader(title: 'Groups', subtitle: 'Find a small group or ministry team to join.'),
        SectionContainer(
          maxWidth: 800,
          child: FutureBuilder<(List<ChurchGroup>, List<GroupMembership>)>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 60),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (snapshot.hasError) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 60),
                  child: Center(child: Text('Could not load groups: ${snapshot.error}')),
                );
              }
              final (groups, memberships) = snapshot.data!;
              if (groups.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 60),
                  child: Center(child: Text('No groups have been posted yet - check back soon.')),
                );
              }
              return Column(
                children: groups.map((group) {
                  final membership = memberships.where((m) => m.groupId == group.id).firstOrNull;
                  return _GroupTile(group: group, membership: membership, onJoin: () => _join(group));
                }).toList(),
              );
            },
          ),
        ),
      ],
    );
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

class _GroupTile extends StatelessWidget {
  final ChurchGroup group;
  final GroupMembership? membership;
  final VoidCallback onJoin;

  const _GroupTile({required this.group, required this.membership, required this.onJoin});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(group.category.toUpperCase(),
                      style: TextStyle(color: ChurchConfig.accentColor, fontSize: 12, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: () => context.go('/account/groups/${group.id}', extra: group),
                    child: Text(group.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
                  ),
                  const SizedBox(height: 4),
                  Text('${group.meetingDay} · ${group.meetingTime} · ${group.location}',
                      style: const TextStyle(color: Colors.black54)),
                  const SizedBox(height: 8),
                  Text(group.description),
                ],
              ),
            ),
            const SizedBox(width: 16),
            _JoinButton(membership: membership, onJoin: onJoin),
          ],
        ),
      ),
    );
  }
}

class _JoinButton extends StatelessWidget {
  final GroupMembership? membership;
  final VoidCallback onJoin;

  const _JoinButton({required this.membership, required this.onJoin});

  @override
  Widget build(BuildContext context) {
    if (membership == null) {
      return ElevatedButton(onPressed: onJoin, child: const Text('Request to Join'));
    }
    final label = membership!.status == MembershipStatus.approved ? 'Member' : 'Pending';
    return OutlinedButton(onPressed: null, child: Text(label));
  }
}
