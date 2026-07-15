import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/member.dart';
import '../../state/attendance_controller.dart';
import '../../state/auth_controller.dart';
import '../../state/members_controller.dart';
import '../../state/serving_controller.dart';
import '../../theme/app_colors.dart';
import '../../widgets/admin_ui.dart';
import '../../widgets/buttons.dart';
import '../admin/admin_attendance_page.dart' show formatDate;

class MemberHomePage extends StatelessWidget {
  const MemberHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final user = auth.currentUser;
    final memberId = user?.memberId;
    final members = context.watch<MembersController>();
    final serving = context.watch<ServingController>();
    final attendance = context.watch<AttendanceController>();

    final member = members.byId(memberId);
    final mySlots = memberId == null ? [] : serving.slotsForMember(memberId);
    final attended = memberId == null ? 0 : attendance.attendedCountFor(memberId);
    final firstName = (user?.name ?? 'Friend').split(' ').first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AdminHeader(
          title: 'Hi $firstName',
          subtitle: 'Welcome to your member portal.',
        ),
        Row(
          children: [
            Expanded(
              child: StatCard(
                icon: Icons.volunteer_activism_outlined,
                value: '${mySlots.length}',
                label: 'Upcoming serving',
                accent: AppColors.gold,
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: StatCard(
                icon: Icons.event_available_outlined,
                value: '$attended',
                label: 'Gatherings attended',
                accent: AppColors.navy,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('My serving schedule',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink)),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () => context.go('/app/serve'),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Find a spot'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (mySlots.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 18),
                  child: Text(
                      'You are not signed up to serve yet. Tap “Find a spot” '
                      'to jump in!',
                      style: TextStyle(color: AppColors.inkSoft)),
                )
              else
                for (final s in mySlots) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: AppColors.cream,
                            borderRadius: BorderRadius.circular(11),
                          ),
                          child: const Icon(Icons.check_circle_outline,
                              color: AppColors.navy),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${serving.teamById(s.teamId)?.name ?? 'Team'} · ${s.title}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.ink),
                              ),
                              Text('${formatDate(s.date)}  ·  ${s.time}',
                                  style: const TextStyle(
                                      fontSize: 13, color: AppColors.inkSoft)),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () => context
                              .read<ServingController>()
                              .toggleSignup(s.id, memberId!),
                          child: const Text('Cancel'),
                        ),
                      ],
                    ),
                  ),
                ],
            ],
          ),
        ),
        const SizedBox(height: 24),
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('My details',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink)),
              const SizedBox(height: 14),
              _detail(Icons.person_outline, 'Name', user?.name ?? '—'),
              _detail(Icons.mail_outline, 'Email', user?.email ?? '—'),
              if (member != null)
                _detail(Icons.badge_outlined, 'Status', member.status.label),
              if (member != null && member.phone.isNotEmpty)
                _detail(Icons.call_outlined, 'Phone', member.phone),
            ],
          ),
        ),
        const SizedBox(height: 20),
        SecondaryButton(
          label: 'View church website',
          icon: Icons.public,
          onPressed: () => context.go('/'),
        ),
      ],
    );
  }

  Widget _detail(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.inkSoft),
          const SizedBox(width: 14),
          SizedBox(
            width: 90,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.inkSoft,
                    fontWeight: FontWeight.w600)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(fontSize: 15, color: AppColors.ink)),
          ),
        ],
      ),
    );
  }
}
