import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../config/church_config.dart';
import '../../models/church_group.dart';
import '../../providers/auth_provider.dart';
import '../../services/group_service.dart';
import '../../widgets/section_container.dart';

class GroupDetailScreen extends StatefulWidget {
  final String groupId;
  final ChurchGroup? initialGroup;

  const GroupDetailScreen({super.key, required this.groupId, this.initialGroup});

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen> {
  final GroupService _service = GroupService();
  late Future<ChurchGroup?> _future;
  bool _requested = false;

  @override
  void initState() {
    super.initState();
    _future = widget.initialGroup != null ? Future.value(widget.initialGroup) : _service.fetchGroup(widget.groupId);
  }

  Future<void> _join() async {
    final uid = context.read<AuthProvider>().currentUser?.uid;
    if (uid == null) return;
    await _service.requestToJoin(groupId: widget.groupId, uid: uid);
    setState(() => _requested = true);
  }

  @override
  Widget build(BuildContext context) {
    return SectionContainer(
      maxWidth: 700,
      child: FutureBuilder<ChurchGroup?>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 80),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final group = snapshot.data;
          if (group == null) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 80),
              child: Center(child: Text('Group not found.')),
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextButton.icon(
                onPressed: () => context.go('/account/groups'),
                icon: const Icon(Icons.arrow_back),
                label: const Text('All groups'),
              ),
              const SizedBox(height: 12),
              Text(group.category.toUpperCase(),
                  style: TextStyle(color: ChurchConfig.accentColor, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text(group.name, style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 8),
              Text('${group.meetingDay} · ${group.meetingTime} · ${group.location}',
                  style: const TextStyle(color: Colors.black54)),
              const SizedBox(height: 8),
              Text('Led by ${group.leaderName}', style: const TextStyle(color: Colors.black54)),
              const SizedBox(height: 20),
              Text(group.description, style: const TextStyle(fontSize: 16, height: 1.6)),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _requested ? null : _join,
                child: Text(_requested ? 'Request Sent' : 'Request to Join'),
              ),
            ],
          );
        },
      ),
    );
  }
}
