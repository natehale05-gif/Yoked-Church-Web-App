import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/settings_providers.dart';
import '../../../core/widgets/app_shell.dart';
import '../../../core/widgets/async_value_widget.dart';
import '../../../core/widgets/section_container.dart';
import '../../auth/application/auth_providers.dart';
import '../application/reading_plan_providers.dart';
import '../domain/reading_plan.dart';
import 'reading_plans_screen.dart';

class ReadingPlanDetailScreen extends ConsumerWidget {
  final String planId;

  const ReadingPlanDetailScreen({super.key, required this.planId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PageBody(
      children: [
        SectionContainer(
          maxWidth: 760,
          child: AsyncValueWidget<ReadingPlan?>(
            value: ref.watch(readingPlanByIdProvider(planId)),
            errorContext: 'this reading plan',
            data: (plan) => plan == null || !plan.published
                ? const EmptyState(message: 'Reading plan not found.')
                : _PlanBody(plan: plan),
          ),
        ),
      ],
    );
  }
}

class _PlanBody extends ConsumerWidget {
  final ReadingPlan plan;

  const _PlanBody({required this.plan});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final signedIn = ref.watch(isSignedInProvider);
    final progress = ref.watch(progressForPlanProvider(plan.id));
    final controller = ref.read(readingPlanControllerProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextButton.icon(
          onPressed: () => context.go('/reading-plans'),
          icon: const Icon(Icons.arrow_back),
          label: const Text('All plans'),
        ),
        const SizedBox(height: 12),
        Text(plan.title, style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 8),
        Text('${plan.dayCount} days', style: const TextStyle(color: Colors.black54)),
        if (plan.description.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(plan.description, style: const TextStyle(fontSize: 16, height: 1.7)),
        ],
        const SizedBox(height: 24),
        if (!signedIn)
          _SignInPrompt(planId: plan.id)
        else if (progress == null)
          ElevatedButton.icon(
            onPressed: () => controller.start(plan.id),
            icon: const Icon(Icons.play_arrow),
            label: const Text('Start this plan'),
          )
        else ...[
          PlanProgressBar(plan: plan, progress: progress),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Leave this plan?'),
                  content: const Text('Your progress on this plan will be removed. You can start it again later.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                    FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Leave')),
                  ],
                ),
              );
              if (confirmed ?? false) await controller.leave(plan.id);
            },
            icon: const Icon(Icons.logout, size: 16),
            label: const Text('Leave plan'),
          ),
        ],
        const SizedBox(height: 28),
        const Divider(),
        const SizedBox(height: 12),
        for (final day in plan.days)
          _DayRow(
            plan: plan,
            day: day,
            done: progress?.isDone(day.dayNumber) ?? false,
            enabled: signedIn,
          ),
      ],
    );
  }
}

class _DayRow extends ConsumerWidget {
  final ReadingPlan plan;
  final ReadingDay day;
  final bool done;
  final bool enabled;

  const _DayRow({required this.plan, required this.day, required this.done, required this.enabled});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brand = ref.watch(settingsProvider).colors;

    return CheckboxListTile(
      value: done,
      // Checking a day is what "reading" means here, so it needs an
      // account to record against.
      onChanged: enabled
          ? (value) => ref
              .read(readingPlanControllerProvider)
              .setDayComplete(plan.id, day.dayNumber, value ?? false)
          : null,
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: EdgeInsets.zero,
      title: Text(
        'Day ${day.dayNumber} · ${day.reference}',
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: done ? Colors.black45 : Colors.black87,
          decoration: done ? TextDecoration.lineThrough : null,
        ),
      ),
      subtitle: day.note.isEmpty && day.devotionalId.isEmpty
          ? null
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (day.note.isNotEmpty) Text(day.note, style: const TextStyle(color: Colors.black54)),
                if (day.devotionalId.isNotEmpty)
                  TextButton.icon(
                    style: TextButton.styleFrom(padding: EdgeInsets.zero, foregroundColor: brand.primary),
                    onPressed: () => context.go('/devotionals/${day.devotionalId}'),
                    icon: const Icon(Icons.auto_stories_outlined, size: 16),
                    label: const Text('Read the devotional'),
                  ),
              ],
            ),
    );
  }
}

class _SignInPrompt extends StatelessWidget {
  final String planId;

  const _SignInPrompt({required this.planId});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Read along without an account, or sign in to check off days and pick up where you left off.',
              style: TextStyle(height: 1.5),
            ),
            const SizedBox(height: 14),
            ElevatedButton(
              onPressed: () => context.go('/sign-in'),
              child: const Text('Sign in to track progress'),
            ),
          ],
        ),
      ),
    );
  }
}
