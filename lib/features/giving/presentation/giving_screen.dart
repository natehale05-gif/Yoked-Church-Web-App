import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/config/settings_providers.dart';
import '../../../core/widgets/app_shell.dart';
import '../../../core/widgets/section_container.dart';

class GivingScreen extends ConsumerWidget {
  const GivingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final givingUrl = settings.social.givingUrl;

    return PageBody(
      children: [
        const PageBanner(
          title: 'Give',
          subtitle: 'Your generosity fuels ministry here and around the world. '
              'Thank you for your faithfulness.',
        ),
        SectionContainer(
          maxWidth: 700,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (givingUrl.isNotEmpty)
                ElevatedButton.icon(
                  onPressed: () => launchUrl(Uri.parse(givingUrl), webOnlyWindowName: '_blank'),
                  icon: const Icon(Icons.favorite),
                  label: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 4),
                    child: Text('Give Online', style: TextStyle(fontSize: 16)),
                  ),
                ),
              const SizedBox(height: 40),
              Text(
                'Other ways to give',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 22),
              ),
              const SizedBox(height: 16),
              const _GivingOption(
                icon: Icons.mail_outline,
                title: 'By Mail',
                description: 'Checks can be mailed to our church office address below.',
              ),
              _GivingOption(
                icon: Icons.location_on_outlined,
                title: 'In Person',
                description: settings.contact.address.isEmpty
                    ? 'Giving boxes are available at every service.'
                    : 'Giving boxes are available at every service at ${settings.contact.address}.',
              ),
              const _GivingOption(
                icon: Icons.repeat,
                title: 'Recurring Giving',
                description: 'Set up automatic weekly or monthly giving through our online giving portal.',
              ),
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 12),
              Text(
                '${settings.churchName} is a registered non-profit. All gifts are '
                'tax-deductible to the extent allowed by law.',
                style: const TextStyle(color: Colors.black54, fontSize: 13),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _GivingOption extends ConsumerWidget {
  final IconData icon;
  final String title;
  final String description;

  const _GivingOption({required this.icon, required this.title, required this.description});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: ref.watch(settingsProvider).colors.primary),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                const SizedBox(height: 4),
                Text(description, style: const TextStyle(color: Colors.black54)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
