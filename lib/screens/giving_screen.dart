import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/giving_fund.dart';
import '../state/site_controller.dart';
import '../utils/color_utils.dart';
import '../utils/launch_helper.dart';
import '../widgets/responsive.dart';
import '../widgets/section_header.dart';
import '../widgets/site_footer.dart';

class GivingScreen extends StatelessWidget {
  const GivingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final site = context.watch<SiteController>();
    final config = site.config;
    final theme = Theme.of(context);
    final accent = ColorUtils.fromHex(config.accentColorHex);

    return SingleChildScrollView(
      child: Column(
        children: [
          ContentContainer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionHeader(
                  eyebrow: 'Give',
                  title: config.givingTitle.isNotEmpty
                      ? config.givingTitle
                      : 'Generosity changes everything',
                  subtitle: config.givingBody,
                ),
                const SizedBox(height: 28),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        accent,
                        ColorUtils.fromHex(config.secondaryColorHex),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(config.cornerRadius),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.volunteer_activism,
                          color: ColorUtils.onColor(accent), size: 34),
                      const SizedBox(height: 16),
                      Text('Give securely online',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: ColorUtils.onColor(accent),
                            fontWeight: FontWeight.w800,
                          )),
                      const SizedBox(height: 20),
                      FilledButton.icon(
                        onPressed: () =>
                            openUrl(context, config.primaryGiveUrl),
                        style: FilledButton.styleFrom(
                          backgroundColor: ColorUtils.onColor(accent),
                          foregroundColor: accent,
                        ),
                        icon: const Icon(Icons.favorite),
                        label: const Text('Give Now'),
                      ),
                    ],
                  ),
                ),
                if (config.givingFunds.isNotEmpty) ...[
                  const SizedBox(height: 40),
                  Text('Ways to give',
                      style: theme.textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 16),
                  GridView.count(
                    crossAxisCount: Responsive.gridColumns(context),
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: Responsive.isMobile(context) ? 2.2 : 1.3,
                    children: [
                      for (final fund in config.givingFunds)
                        _FundCard(fund: fund),
                    ],
                  ),
                ],
              ],
            ),
          ),
          SiteFooter(config: config),
        ],
      ),
    );
  }
}

class _FundCard extends StatelessWidget {
  final GivingFund fund;

  const _FundCard({required this.fund});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: InkWell(
        onTap:
            fund.url.trim().isNotEmpty ? () => openUrl(context, fund.url) : null,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(fund.name,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700)),
              if (fund.description.isNotEmpty) ...[
                const SizedBox(height: 8),
                Expanded(
                  child: Text(fund.description,
                      style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          height: 1.5)),
                ),
              ],
              if (fund.url.trim().isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text('Give',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        )),
                    Icon(Icons.arrow_forward,
                        size: 16, color: theme.colorScheme.primary),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
