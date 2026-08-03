import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/settings_providers.dart';
import '../../../core/widgets/app_shell.dart';
import '../../../core/widgets/async_value_widget.dart';
import '../../../core/widgets/section_container.dart';
import '../../reading_plans/application/reading_plan_providers.dart';
import '../../reading_plans/presentation/reading_plans_screen.dart';
import 'account_header.dart';

class MyReadingScreen extends ConsumerWidget {
  const MyReadingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rows = ref.watch(plansInProgressProvider);
    final brand = ref.watch(settingsProvider).colors;

    return PageBody(
      children: [
        const AccountHeader(title: 'My Reading', subtitle: 'Pick up where you left off.'),
        SectionContainer(
          maxWidth: 760,
          child: rows.isEmpty
              ? Column(
                  children: [
                    const EmptyState(
                      message: "You haven't started a reading plan yet.",
                      icon: Icons.menu_book_outlined,
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () => context.go('/reading-plans'),
                      child: const Text('Browse reading plans'),
                    ),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final row in rows)
                      Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: InkWell(
                          onTap: () => context.go('/reading-plans/${row.plan.id}'),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(row.plan.title, style: Theme.of(context).textTheme.titleLarge),
                                const SizedBox(height: 14),
                                PlanProgressBar(plan: row.plan, progress: row.progress),
                                const SizedBox(height: 14),
                                Builder(
                                  builder: (context) {
                                    final next = row.progress.nextDay(row.plan);
                                    if (next == null) {
                                      return Row(
                                        children: [
                                          Icon(Icons.check_circle, size: 18, color: brand.accent),
                                          const SizedBox(width: 8),
                                          const Text(
                                            'Plan complete',
                                            style: TextStyle(fontWeight: FontWeight.w600),
                                          ),
                                        ],
                                      );
                                    }
                                    return Text(
                                      'Up next · Day ${next.dayNumber} · ${next.reference}',
                                      style: TextStyle(color: brand.primary, fontWeight: FontWeight.w600),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => context.go('/reading-plans'),
                      child: const Text('Browse all plans'),
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}
