import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/app_icons.dart';
import '../../models/serving.dart';
import '../../state/auth_controller.dart';
import '../../state/serving_controller.dart';
import '../../theme/app_colors.dart';
import '../../widgets/admin_ui.dart';
import '../admin/admin_attendance_page.dart' show formatDate;

class MemberServePage extends StatelessWidget {
  const MemberServePage({super.key});

  @override
  Widget build(BuildContext context) {
    final serving = context.watch<ServingController>();
    final memberId = context.watch<AuthController>().currentUser?.memberId;
    final teams = serving.teams;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AdminHeader(
          title: 'Serve',
          subtitle: 'Find a team and a time that works for you.',
        ),
        for (final team in teams) ...[
          Builder(builder: (context) {
            final slots = serving
                .slotsForTeam(team.id)
                .where((s) => s.date.isAfter(
                    DateTime.now().subtract(const Duration(days: 1))))
                .toList();
            if (slots.isEmpty) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: Panel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.cream,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(iconForKey(team.iconKey),
                              color: AppColors.navy),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(team.name,
                                  style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.ink)),
                              Text(team.description,
                                  style: const TextStyle(
                                      fontSize: 13.5,
                                      color: AppColors.inkSoft)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    for (final s in slots)
                      _SlotRow(slot: s, memberId: memberId),
                  ],
                ),
              ),
            );
          }),
        ],
      ],
    );
  }
}

class _SlotRow extends StatelessWidget {
  final ServingSlot slot;
  final String? memberId;
  const _SlotRow({required this.slot, required this.memberId});

  @override
  Widget build(BuildContext context) {
    final signedUp = memberId != null && slot.memberIds.contains(memberId);
    final canJoin = memberId != null && (!slot.isFull || signedUp);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(slot.title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: AppColors.ink)),
                Text('${formatDate(slot.date)}  ·  ${slot.time}',
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.inkSoft)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: StatusPill(
              label: slot.isFull && !signedUp
                  ? 'Full'
                  : '${slot.remaining} open',
              color: slot.isFull && !signedUp
                  ? AppColors.inkSoft
                  : AppColors.gold,
            ),
          ),
          if (signedUp)
            OutlinedButton.icon(
              onPressed: () => context
                  .read<ServingController>()
                  .toggleSignup(slot.id, memberId!),
              icon: const Icon(Icons.check, size: 16),
              label: const Text("You're in"),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF3E7C5A),
                side: const BorderSide(color: Color(0xFF3E7C5A)),
              ),
            )
          else
            FilledButton(
              onPressed: canJoin
                  ? () => context
                      .read<ServingController>()
                      .toggleSignup(slot.id, memberId!)
                  : null,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.navy,
                foregroundColor: AppColors.onDark,
              ),
              child: const Text('Sign up'),
            ),
        ],
      ),
    );
  }
}
