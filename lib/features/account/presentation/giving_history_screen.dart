import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/config/settings_providers.dart';
import '../../../core/widgets/app_shell.dart';
import '../../../core/widgets/async_value_widget.dart';
import '../../../core/widgets/section_container.dart';
import '../../giving/domain/giving_record.dart';
import '../../giving/application/giving_providers.dart';
import 'account_header.dart';

class GivingHistoryScreen extends ConsumerWidget {
  const GivingHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final currency = NumberFormat.simpleCurrency();

    return PageBody(
      children: [
        const AccountHeader(title: 'Giving', subtitle: 'A record of your gifts to the church.'),
        SectionContainer(
          maxWidth: 720,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (settings.social.givingUrl.isNotEmpty)
                ElevatedButton.icon(
                  onPressed: () =>
                      launchUrl(Uri.parse(settings.social.givingUrl), webOnlyWindowName: '_blank'),
                  icon: const Icon(Icons.favorite),
                  label: const Text('Give Online'),
                ),
              const SizedBox(height: 28),
              AsyncValueWidget<List<GivingSummary>>(
                value: ref.watch(myGivingByYearProvider),
                errorContext: 'your giving history',
                data: (years) => years.isEmpty
                    ? const EmptyState(
                        icon: Icons.receipt_long_outlined,
                        message: "No giving on file yet. Once the church office records a gift, "
                            "it'll show up here.",
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (final year in years) _YearSection(summary: year, currency: currency),
                        ],
                      ),
              ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 12),
              Text(
                'Statements reflect gifts recorded by the church office. If '
                'something looks wrong, contact ${settings.contact.email.isEmpty ? "the office" : settings.contact.email}.',
                style: const TextStyle(color: Colors.black54, fontSize: 13),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _YearSection extends ConsumerWidget {
  final GivingSummary summary;
  final NumberFormat currency;

  const _YearSection({required this.summary, required this.currency});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brand = ref.watch(settingsProvider).colors;

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('${summary.year}', style: Theme.of(context).textTheme.titleLarge),
              ),
              Text(
                currency.format(summary.total),
                style: TextStyle(color: brand.primary, fontWeight: FontWeight.w700, fontSize: 18),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                for (final record in summary.records)
                  ListTile(
                    title: Text(record.fund),
                    subtitle: Text(
                      [
                        DateFormat.yMMMd().format(record.date),
                        if (record.method.isNotEmpty) record.method,
                      ].join(' · '),
                    ),
                    trailing: Text(
                      currency.format(record.amount),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
