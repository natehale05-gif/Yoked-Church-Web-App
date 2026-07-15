import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/member.dart';
import '../../state/attendance_controller.dart';
import '../../state/auth_controller.dart';
import '../../state/members_controller.dart';
import '../../state/serving_controller.dart';
import '../../theme/app_colors.dart';
import '../../theme/responsive.dart';
import '../../widgets/admin_ui.dart';

class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final members = context.watch<MembersController>();
    final attendance = context.watch<AttendanceController>();
    final serving = context.watch<ServingController>();
    final user = context.watch<AuthController>().currentUser;
    final cols = context.responsive(mobile: 1, tablet: 2, desktop: 4);
    final latest = attendance.latest;

    final firstName = (user?.name ?? '').split(' ').first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AdminHeader(
          title: 'Welcome back${firstName.isEmpty ? '' : ', $firstName'}',
          subtitle: "Here's how your church community is doing.",
        ),
        _grid(cols, [
          StatCard(
            icon: Icons.people_alt_outlined,
            value: '${members.count}',
            label: 'People tracked',
            accent: AppColors.navy,
          ),
          StatCard(
            icon: Icons.verified_user_outlined,
            value: '${members.countByStatus(MemberStatus.member)}',
            label: 'Members',
            accent: const Color(0xFF3E7C5A),
          ),
          StatCard(
            icon: Icons.fact_check_outlined,
            value: latest == null ? '—' : '${latest.total}',
            label: 'Last attendance',
            accent: const Color(0xFF2F6DB0),
          ),
          StatCard(
            icon: Icons.volunteer_activism_outlined,
            value: '${serving.openSlotCount}',
            label: 'Open serving spots',
            accent: AppColors.gold,
          ),
        ]),
        const SizedBox(height: 28),
        LayoutBuilder(
          builder: (context, c) {
            final wide = c.maxWidth >= 760;
            final left = _RecentAttendance();
            final right = _QuickActions();
            if (!wide) {
              return Column(
                children: [left, const SizedBox(height: 20), right],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 6, child: left),
                const SizedBox(width: 20),
                Expanded(flex: 4, child: right),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _grid(int cols, List<Widget> children) {
    return LayoutBuilder(builder: (context, c) {
      const gap = 18.0;
      final w = (c.maxWidth - gap * (cols - 1)) / cols;
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: [for (final child in children) SizedBox(width: w, child: child)],
      );
    });
  }
}

class _RecentAttendance extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final attendance = context.watch<AttendanceController>();
    final records = attendance.records.take(6).toList();
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Recent attendance',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  )),
              const Spacer(),
              TextButton(
                onPressed: () => context.go('/app/attendance'),
                child: const Text('View all'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (records.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Text('No attendance recorded yet.',
                  style: TextStyle(color: AppColors.inkSoft)),
            )
          else
            for (final r in records) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.cream,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.event_available,
                          size: 20, color: AppColors.navy),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(r.serviceLabel,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.ink)),
                          Text(_fmt(r.date),
                              style: const TextStyle(
                                  fontSize: 13, color: AppColors.inkSoft)),
                        ],
                      ),
                    ),
                    Text('${r.total}',
                        style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppColors.navy)),
                    const SizedBox(width: 6),
                    const Text('present',
                        style:
                            TextStyle(fontSize: 12, color: AppColors.inkSoft)),
                  ],
                ),
              ),
              if (r != records.last) const Divider(height: 1),
            ],
        ],
      ),
    );
  }

  static String _fmt(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }
}

class _QuickActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final actions = [
      (Icons.edit_note_outlined, 'Edit your website', '/app/editor'),
      (Icons.person_add_alt, 'Add a member', '/app/members'),
      (Icons.add_task, 'Record attendance', '/app/attendance'),
      (Icons.groups_2_outlined, 'Manage serving', '/app/serving'),
    ];
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Quick actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              )),
          const SizedBox(height: 12),
          for (final a in actions)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Material(
                color: AppColors.ivory,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => context.go(a.$3),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 14),
                    child: Row(
                      children: [
                        Icon(a.$1, color: AppColors.navy, size: 20),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(a.$2,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.ink)),
                        ),
                        const Icon(Icons.chevron_right,
                            color: AppColors.inkSoft),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
