import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/settings_providers.dart';
import '../../../core/widgets/app_shell.dart';
import '../../../core/widgets/async_value_widget.dart';
import '../../../core/widgets/section_container.dart';
import '../../reports/application/report_providers.dart';
import '../../reports/domain/report_metrics.dart';
import 'admin_header.dart';

class ReportsAdminScreen extends ConsumerWidget {
  const ReportsAdminScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sections = ref.watch(reportSectionsProvider);

    return PageBody(
      children: [
        const AdminHeader(
          title: 'Reports',
          subtitle: 'Totalled from what the church has actually recorded.',
        ),
        SectionContainer(
          maxWidth: 900,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (sections.isEmpty)
                const EmptyState(
                  message: 'Every feature these reports draw on is switched off.',
                  icon: Icons.bar_chart_outlined,
                )
              else
                for (final section in sections) _Section(section: section),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 12),
              // Said out loud rather than shipped as a tile of invented
              // numbers. Nothing in this app records a page view or a
              // sermon play, and a fabricated figure a church might quote
              // in a board meeting is worse than an absent one.
              const Text(
                'Not shown: sermon plays and website traffic. This app does not '
                'record either, and a number nobody measured is worse than a '
                'missing one. Point your video host and web analytics at those '
                'questions instead.',
                style: TextStyle(color: Colors.black54, fontSize: 12, height: 1.6),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Section extends ConsumerWidget {
  final ReportSection section;

  const _Section({required this.section});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (section.metrics.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(section.title, style: Theme.of(context).textTheme.titleLarge),
          if (section.description.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(section.description, style: const TextStyle(color: Colors.black54)),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [for (final metric in section.metrics) _MetricCard(metric: metric)],
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends ConsumerWidget {
  final Metric metric;

  const _MetricCard({required this.metric});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brand = ref.watch(settingsProvider).colors;
    final trend = metric.trend;
    final change = trend?.changeLabel;

    return SizedBox(
      width: 260,
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                metric.label.toUpperCase(),
                style: const TextStyle(fontSize: 11, letterSpacing: 1.1, color: Colors.black54),
              ),
              const SizedBox(height: 8),
              Text(
                metric.value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: brand.primary),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  if (metric.detail.isNotEmpty)
                    Expanded(
                      child: Text(
                        metric.detail,
                        style: const TextStyle(color: Colors.black54, fontSize: 12),
                      ),
                    )
                  else
                    const Spacer(),
                  if (change != null)
                    Row(
                      children: [
                        Icon(
                          trend!.isUp
                              ? Icons.trending_up
                              : (trend.isDown ? Icons.trending_down : Icons.trending_flat),
                          size: 16,
                          color: trend.isDown ? Colors.orange.shade800 : Colors.green.shade700,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          change,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: trend.isDown ? Colors.orange.shade800 : Colors.green.shade700,
                          ),
                        ),
                      ],
                    )
                  else if (trend != null)
                    // No prior window to compare against. "+100%" from a
                    // zero baseline would be a lie dressed as a metric.
                    const Text(
                      'no baseline yet',
                      style: TextStyle(fontSize: 11, color: Colors.black38),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
