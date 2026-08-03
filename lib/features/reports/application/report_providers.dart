import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/config/church_settings.dart';
import '../../../core/config/settings_providers.dart';
import '../../attendance/application/attendance_providers.dart';
import '../../attendance/domain/attendance_record.dart';
import '../../auth/application/auth_providers.dart';
import '../../auth/domain/app_user.dart';
import '../../connect/application/connect_providers.dart';
import '../../connect/domain/connect_submission.dart';
import '../../forms/application/form_providers.dart';
import '../../forms/domain/form_submission.dart';
import '../../giving/application/giving_providers.dart';
import '../../giving/domain/giving_record.dart';
import '../../groups/application/group_providers.dart';
import '../../groups/domain/group.dart';
import '../../prayer_wall/application/prayer_providers.dart';
import '../../prayer_wall/domain/prayer_post.dart';
import '../../volunteering/application/volunteering_providers.dart';
import '../../volunteering/domain/volunteering.dart';
import '../domain/report_metrics.dart';

/// A named block of numbers on the reports page.
class ReportSection {
  final String title;
  final String description;
  final List<Metric> metrics;

  const ReportSection({required this.title, this.description = '', required this.metrics});
}

/// Everything on /admin/reports, derived from collections that already
/// exist. No `reports` collection and no nightly rollup: a church's data
/// is small enough to total on the fly, and a stored aggregate is one
/// more thing to get out of step with the truth.
final reportSectionsProvider = Provider<List<ReportSection>>((ref) {
  final now = DateTime.now();
  final flags = ref.watch(featureFlagsProvider);
  final members = ref.watch(allMembersProvider).valueOrNull ?? const <AppUser>[];

  return [
    if (flags.attendance) _attendance(ref, now),
    if (flags.giving) _giving(ref, now),
    if (flags.forms) _forms(ref, now),
    if (flags.groups || flags.volunteering) _participation(ref, members, flags),
    if (flags.prayerWall || flags.connect) _pastoral(ref, now, flags),
  ];
});

ReportSection _attendance(Ref ref, DateTime now) {
  final records = ref.watch(allAttendanceProvider).valueOrNull ?? const <AttendanceRecord>[];
  final services = records.where((r) => r.gatheringType == GatheringType.service).toList();
  final groups = records.where((r) => r.gatheringType == GatheringType.group).toList();

  Metric total(String label, List<AttendanceRecord> from) {
    final trend = trendOver<AttendanceRecord>(
      from,
      dateOf: (r) => r.date,
      valueOf: (r) => r.effectiveCount.toDouble(),
      now: now,
    );
    return Metric(
      label: label,
      value: _round(trend.current),
      detail: 'last 90 days',
      trend: trend,
    );
  }

  final series = AttendanceSeries.group(services);
  final busiest = series.isEmpty
      ? null
      : series.reduce((a, b) => a.average >= b.average ? a : b);

  return ReportSection(
    title: 'Attendance',
    description: 'Totals across the last 90 days, next to the 90 before them.',
    metrics: [
      total('People at services', services),
      total('People at small groups', groups),
      if (busiest != null)
        Metric(
          label: 'Best-attended gathering',
          value: busiest.gatheringName,
          detail: 'averaging ${busiest.average}',
        ),
    ],
  );
}

ReportSection _giving(Ref ref, DateTime now) {
  final records = ref.watch(allGivingProvider).valueOrNull ?? const <GivingRecord>[];
  final money = NumberFormat.simpleCurrency(decimalDigits: 0);

  final trend = trendOver<GivingRecord>(
    records,
    dateOf: (r) => r.date,
    valueOf: (r) => r.amount,
    now: now,
  );

  // Reuses the same per-year grouping the member's annual statement is
  // built from, rather than re-implementing the maths beside it.
  final years = GivingSummary.byYear(records);

  return ReportSection(
    title: 'Giving',
    description: 'Recorded gifts. Entry is manual, so this reflects what staff have entered.',
    metrics: [
      Metric(
        label: 'Given',
        value: money.format(trend.current),
        detail: 'last 90 days',
        trend: trend,
      ),
      if (years.isNotEmpty)
        Metric(
          label: '${years.first.year} to date',
          value: money.format(years.first.total),
          detail: '${years.first.records.length} gifts',
        ),
      Metric(
        label: 'People who have given',
        value: '${records.map((r) => r.uid).toSet().length}',
        detail: 'all time',
      ),
    ],
  );
}

ReportSection _forms(Ref ref, DateTime now) {
  final submissions = ref.watch(allSubmissionsProvider).valueOrNull ?? const <FormSubmission>[];
  final forms = ref.watch(formsProvider).valueOrNull ?? const [];
  final trend = trendOver<FormSubmission>(submissions, dateOf: (s) => s.submittedAt, now: now);

  final byForm = <String, int>{};
  for (final s in submissions) {
    byForm[s.formTitle] = (byForm[s.formTitle] ?? 0) + 1;
  }
  final busiest = byForm.entries.isEmpty
      ? null
      : byForm.entries.reduce((a, b) => a.value >= b.value ? a : b);

  return ReportSection(
    title: 'Forms',
    metrics: [
      Metric(
        label: 'Responses',
        value: _round(trend.current),
        detail: 'last 90 days',
        trend: trend,
      ),
      Metric(
        label: 'Forms open',
        value: '${forms.where((f) => f.isAcceptingSubmissions).length}',
        detail: 'of ${forms.length} built',
      ),
      if (busiest != null)
        Metric(label: 'Most responses', value: busiest.key, detail: '${busiest.value} in total'),
    ],
  );
}

ReportSection _participation(Ref ref, List<AppUser> members, FeatureFlags flags) {
  final memberships = ref.watch(allMembershipsProvider).valueOrNull ?? const <GroupMembership>[];
  final assignments = ref.watch(allAssignmentsProvider).valueOrNull ?? const <VolunteerAssignment>[];
  final groups = ref.watch(groupsProvider).valueOrNull ?? const <ChurchGroup>[];

  final inGroups = Participation(
    engaged: memberships
        .where((m) => m.status == MembershipStatus.approved)
        .map((m) => m.uid)
        .toSet()
        .length,
    total: members.length,
  );
  final serving = Participation(
    engaged: assignments
        .where((a) => a.status == AssignmentStatus.approved)
        .map((a) => a.uid)
        .toSet()
        .length,
    total: members.length,
  );

  return ReportSection(
    title: 'Participation',
    description: 'Counted against everyone with an account, so it moves as the roll grows.',
    metrics: [
      if (flags.groups) ...[
        Metric(
          label: 'In a small group',
          value: inGroups.percentLabel ?? '—',
          detail: inGroups.label,
        ),
        Metric(label: 'Groups running', value: '${groups.length}'),
      ],
      if (flags.volunteering)
        Metric(
          label: 'Serving on a team',
          value: serving.percentLabel ?? '—',
          detail: serving.label,
        ),
    ],
  );
}

ReportSection _pastoral(Ref ref, DateTime now, FeatureFlags flags) {
  final prayers = ref.watch(allPrayerPostsProvider).valueOrNull ?? const <PrayerPost>[];
  final connect = ref.watch(submissionsProvider).valueOrNull ?? const <ConnectSubmission>[];

  final prayerTrend = trendOver<PrayerPost>(prayers, dateOf: (p) => p.createdAt, now: now);
  final connectTrend = trendOver<ConnectSubmission>(connect, dateOf: (c) => c.submittedAt, now: now);

  return ReportSection(
    title: 'Pastoral care',
    description: 'What people have asked for, and what is still waiting on someone.',
    metrics: [
      if (flags.prayerWall) ...[
        Metric(
          label: 'Prayer requests',
          value: _round(prayerTrend.current),
          detail: 'last 90 days',
          trend: prayerTrend,
        ),
        Metric(
          label: 'Waiting for moderation',
          value: '${prayers.where((p) => p.status == PrayerStatus.pending).length}',
        ),
      ],
      if (flags.connect) ...[
        Metric(
          label: 'Connect cards',
          value: _round(connectTrend.current),
          detail: 'last 90 days',
          trend: connectTrend,
        ),
        Metric(
          label: 'Still open',
          value: '${connect.where((c) => c.status == SubmissionStatus.open).length}',
        ),
      ],
    ],
  );
}

String _round(double value) => value.round().toString();
