import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/volunteer_assignment.dart';
import '../../models/volunteer_position.dart';
import '../../providers/auth_provider.dart';
import '../../services/volunteer_service.dart';
import '../../widgets/account_header.dart';
import '../../widgets/section_container.dart';

class VolunteeringScreen extends StatefulWidget {
  const VolunteeringScreen({super.key});

  @override
  State<VolunteeringScreen> createState() => _VolunteeringScreenState();
}

class _VolunteeringScreenState extends State<VolunteeringScreen> {
  final VolunteerService _service = VolunteerService();
  late Future<_VolunteeringData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_VolunteeringData> _load() async {
    final uid = context.read<AuthProvider>().currentUser?.uid ?? '';
    final positions = await _service.fetchPositions();
    final myAssignments = uid.isEmpty ? <VolunteerAssignment>[] : await _service.fetchMyAssignments(uid);

    final openCounts = <String, int>{};
    for (final position in positions) {
      final assignments = await _service.fetchAssignmentsForPosition(position.id);
      final filled = assignments.where((a) => a.status != AssignmentStatus.declined).length;
      openCounts[position.id] = position.slotsNeeded - filled;
    }

    return _VolunteeringData(positions: positions, myAssignments: myAssignments, openSlots: openCounts);
  }

  void _refresh() => setState(() => _future = _load());

  Future<void> _signUp(String positionId) async {
    final uid = context.read<AuthProvider>().currentUser?.uid;
    if (uid == null) return;
    await _service.selfSignUp(positionId: positionId, uid: uid);
    _refresh();
  }

  Future<void> _decline(String assignmentId) async {
    await _service.declineAssignment(assignmentId);
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const AccountHeader(title: 'Volunteering', subtitle: 'See where you\'re serving or sign up to help.'),
        SectionContainer(
          maxWidth: 800,
          child: FutureBuilder<_VolunteeringData>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 60),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final data = snapshot.data!;
              final myPositionIds = data.myAssignments.map((a) => a.positionId).toSet();
              final openPositions =
                  data.positions.where((p) => !myPositionIds.contains(p.id) && (data.openSlots[p.id] ?? 0) > 0);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('My Assignments', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 22)),
                  const SizedBox(height: 12),
                  if (data.myAssignments.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 24),
                      child: Text("You haven't signed up to serve anywhere yet.", style: TextStyle(color: Colors.black54)),
                    )
                  else
                    ...data.myAssignments.map((assignment) {
                      final position = data.positions.where((p) => p.id == assignment.positionId).firstOrNull;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          title: Text(position?.title ?? 'Unknown position',
                              style: const TextStyle(fontWeight: FontWeight.w700)),
                          subtitle: Text(
                            position == null
                                ? _statusLabel(assignment.status)
                                : '${DateFormat.yMMMd().format(position.date)} · ${_statusLabel(assignment.status)}',
                          ),
                          trailing: assignment.status == AssignmentStatus.declined
                              ? null
                              : TextButton(
                                  onPressed: () => _decline(assignment.id),
                                  child: const Text('Decline'),
                                ),
                        ),
                      );
                    }),
                  const SizedBox(height: 24),
                  Text('Open Positions', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 22)),
                  const SizedBox(height: 12),
                  if (openPositions.isEmpty)
                    const Text('No open positions right now - check back soon.', style: TextStyle(color: Colors.black54))
                  else
                    ...openPositions.map((position) {
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          title: Text(position.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                          subtitle: Text(
                              '${DateFormat.yMMMd().format(position.date)} · ${position.location} · ${data.openSlots[position.id]} spot(s) open'),
                          trailing: ElevatedButton(
                            onPressed: () => _signUp(position.id),
                            child: const Text('Sign Up'),
                          ),
                        ),
                      );
                    }),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  String _statusLabel(AssignmentStatus status) {
    switch (status) {
      case AssignmentStatus.pending:
        return 'Pending approval';
      case AssignmentStatus.approved:
        return "You're confirmed";
      case AssignmentStatus.declined:
        return 'Declined';
    }
  }
}

class _VolunteeringData {
  final List<VolunteerPosition> positions;
  final List<VolunteerAssignment> myAssignments;
  final Map<String, int> openSlots;

  const _VolunteeringData({required this.positions, required this.myAssignments, required this.openSlots});
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
