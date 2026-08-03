import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/settings_providers.dart';
import '../../../core/widgets/app_shell.dart';
import '../../../core/widgets/async_value_widget.dart';
import '../../../core/widgets/section_container.dart';
import '../application/reading_plan_providers.dart';
import '../domain/reading_plan.dart';

class ReadingPlansScreen extends ConsumerWidget {
  const ReadingPlansScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PageBody(
      children: [
        const PageBanner(
          eyebrow: 'Grow',
          title: 'Reading Plans',
          subtitle: 'Read through Scripture at a pace you can keep.',
        ),
        SectionContainer(
          maxWidth: 820,
          child: AsyncListWidget<ReadingPlan>(
            value: ref.watch(publishedReadingPlansProvider),
            errorContext: 'reading plans',
            emptyMessage: 'No reading plans yet. Check back soon.',
            data: (plans) => Column(
              children: [for (final plan in plans) PlanCard(plan: plan)],
            ),
          ),
        ),
      ],
    );
  }
}

class PlanCard extends ConsumerWidget {
  final ReadingPlan plan;

  const PlanCard({super.key, required this.plan});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(progressForPlanProvider(plan.id));

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => context.go('/reading-plans/${plan.id}'),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text(plan.title, style: Theme.of(context).textTheme.titleLarge)),
                  Chip(label: Text('${plan.dayCount} days')),
                ],
              ),
              if (plan.description.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(plan.description, style: const TextStyle(height: 1.6, color: Colors.black87)),
              ],
              if (progress != null) ...[
                const SizedBox(height: 16),
                PlanProgressBar(plan: plan, progress: progress),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Shared by the plan list, the detail page, and the account tab so the
/// same plan never reads as two different percentages.
class PlanProgressBar extends ConsumerWidget {
  final ReadingPlan plan;
  final PlanProgress progress;

  const PlanProgressBar({super.key, required this.plan, required this.progress});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brand = ref.watch(settingsProvider).colors;
    final fraction = progress.fractionOf(plan);
    final done = plan.days.where((d) => progress.isDone(d.dayNumber)).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: fraction,
            minHeight: 8,
            backgroundColor: brand.primary.withValues(alpha: 0.12),
            valueColor: AlwaysStoppedAnimation(brand.accent),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          fraction >= 1
              ? 'Finished - all $done days'
              : '$done of ${plan.dayCount} days · ${(fraction * 100).round()}%',
          style: const TextStyle(color: Colors.black54, fontSize: 13),
        ),
      ],
    );
  }
}
