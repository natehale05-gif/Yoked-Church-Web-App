import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../groups/application/group_providers.dart';
import '../../groups/domain/group.dart';
import '../application/attendance_providers.dart';
import '../domain/attendance_record.dart';

/// What a group leader actually needs from attendance: not a total, but
/// the roster ordered by who was last here. A bare number cannot show
/// that someone quietly stopped coming six weeks ago.
class GroupAttendancePanel extends ConsumerWidget {
  final ChurchGroup group;

  const GroupAttendancePanel({super.key, required this.group});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final records = ref.watch(gatheringHistoryProvider(group.id)).valueOrNull ?? const [];
    final memberships = ref.watch(groupMembershipsProvider(group.id)).valueOrNull ?? const [];
    final roster = memberships.where((m) => m.status == MembershipStatus.approved).toList();

    final series = AttendanceSeries(
      type: GatheringType.group,
      gatheringId: group.id,
      gatheringName: group.name,
      records: records,
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.insights_outlined, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${group.name} · attendance',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              records.isEmpty
                  ? 'No attendance has been recorded for this group yet.'
                  : 'Averaging ${series.average} over ${series.occasions} '
                      '${series.occasions == 1 ? 'meeting' : 'meetings'}.',
              style: const TextStyle(color: Colors.black54),
            ),
            if (records.isNotEmpty) ...[
              const SizedBox(height: 16),
              _LastSeen(roster: roster, records: records),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              const Text('Recent meetings', style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              for (final record in records.take(6))
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      Expanded(child: Text(DateFormat.yMMMEd().format(record.date))),
                      Text(
                        '${record.effectiveCount}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
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

class _LastSeen extends StatelessWidget {
  final List<GroupMembership> roster;
  final List<AttendanceRecord> records;

  const _LastSeen({required this.roster, required this.records});

  @override
  Widget build(BuildContext context) {
    if (roster.isEmpty) {
      return const Text('No approved members yet.', style: TextStyle(color: Colors.black54));
    }

    // Records arrive newest-first, so the first hit per member is their
    // most recent attendance.
    final lastSeen = <String, DateTime>{};
    for (final record in records) {
      for (final uid in record.presentUids) {
        lastSeen.putIfAbsent(uid, () => record.date);
      }
    }

    final ordered = roster.toList()
      ..sort((a, b) {
        final aDate = lastSeen[a.uid];
        final bDate = lastSeen[b.uid];
        // Never-seen first, then longest-absent - the order a leader
        // would want to work down.
        if (aDate == null && bDate == null) return a.memberName.compareTo(b.memberName);
        if (aDate == null) return -1;
        if (bDate == null) return 1;
        return aDate.compareTo(bDate);
      });

    final mostRecent = records.first.date;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Last here', style: TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        for (final m in ordered)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              children: [
                Expanded(child: Text(m.memberName.isEmpty ? m.uid : m.memberName)),
                Builder(builder: (context) {
                  final date = lastSeen[m.uid];
                  if (date == null) {
                    return Text(
                      'not yet',
                      style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12),
                    );
                  }
                  final missed = records.where((r) => r.date.isAfter(date)).length;
                  return Text(
                    date == mostRecent
                        ? 'last meeting'
                        : '${DateFormat.yMMMd().format(date)} · missed $missed',
                    style: TextStyle(
                      fontSize: 12,
                      color: missed >= 3 ? Theme.of(context).colorScheme.error : Colors.black54,
                    ),
                  );
                }),
              ],
            ),
          ),
      ],
    );
  }
}
