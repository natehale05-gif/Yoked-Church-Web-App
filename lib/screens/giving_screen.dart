import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/church_config.dart';
import '../theme/app_theme.dart';
import '../widgets/section_container.dart';

class GivingScreen extends StatelessWidget {
  const GivingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = Breakpoints.isMobile(context);

    return Column(
      children: [
        Container(
          width: double.infinity,
          color: ChurchConfig.primaryColor,
          padding: EdgeInsets.symmetric(horizontal: isMobile ? 24 : 60, vertical: isMobile ? 48 : 72),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Give', style: Theme.of(context).textTheme.displayMedium?.copyWith(color: Colors.white)),
              const SizedBox(height: 12),
              const Text(
                'Your generosity fuels ministry here and around the world. Thank you for '
                'your faithfulness.',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
            ],
          ),
        ),
        SectionContainer(
          maxWidth: 700,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ElevatedButton.icon(
                onPressed: () => launchUrl(Uri.parse(ChurchConfig.givingUrl), webOnlyWindowName: '_blank'),
                icon: const Icon(Icons.favorite),
                label: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 4),
                  child: Text('Give Online', style: TextStyle(fontSize: 16)),
                ),
              ),
              const SizedBox(height: 40),
              Text('Other ways to give', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 22)),
              const SizedBox(height: 16),
              const _GivingOption(
                icon: Icons.mail_outline,
                title: 'By Mail',
                description: 'Checks can be mailed to our church office address below.',
              ),
              _GivingOption(
                icon: Icons.location_on_outlined,
                title: 'In Person',
                description: 'Giving boxes are available at every service at ${ChurchConfig.address}.',
              ),
              const _GivingOption(
                icon: Icons.repeat,
                title: 'Recurring Giving',
                description: 'Set up automatic weekly or monthly giving through our online giving portal.',
              ),
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 12),
              const Text(
                'Yoked Church is a registered non-profit. All gifts are tax-deductible '
                'to the extent allowed by law.',
                style: TextStyle(color: Colors.black54, fontSize: 13),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _GivingOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _GivingOption({required this.icon, required this.title, required this.description});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: ChurchConfig.primaryColor),
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
