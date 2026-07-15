import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/auth_controller.dart';
import '../../state/site_controller.dart';
import '../../widgets/responsive.dart';
import 'account_screen.dart';
import 'branding_editor_screen.dart';
import 'content/events_admin.dart';
import 'content/lists_admin.dart';
import 'content/ministries_admin.dart';
import 'content/sermons_admin.dart';
import 'content/staff_admin.dart';
import 'data_tools_screen.dart';

class _AdminItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final WidgetBuilder builder;

  const _AdminItem(this.title, this.subtitle, this.icon, this.builder);
}

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final site = context.watch<SiteController>();
    final theme = Theme.of(context);

    final items = <_AdminItem>[
      _AdminItem('Branding & Content', 'Name, colors, fonts, hero, text',
          Icons.palette_outlined, (_) => const BrandingEditorScreen()),
      _AdminItem('Messages', '${site.sermons.length} sermons',
          Icons.play_circle_outline, (_) => const SermonsAdminScreen()),
      _AdminItem('Events', '${site.events.length} events',
          Icons.event_outlined, (_) => const EventsAdminScreen()),
      _AdminItem('Ministries', '${site.ministries.length} ministries',
          Icons.diversity_3_outlined, (_) => const MinistriesAdminScreen()),
      _AdminItem('Staff & Leaders', '${site.staff.length} people',
          Icons.badge_outlined, (_) => const StaffAdminScreen()),
      _AdminItem(
          'Service Times',
          '${site.config.serviceTimes.length} times',
          Icons.schedule,
          (_) => const ServiceTimesAdminScreen()),
      _AdminItem(
          'Giving Funds',
          '${site.config.givingFunds.length} funds',
          Icons.savings_outlined,
          (_) => const GivingFundsAdminScreen()),
      _AdminItem(
          'Social Links',
          '${site.config.socialLinks.length} links',
          Icons.share_outlined,
          (_) => const SocialLinksAdminScreen()),
      _AdminItem('Provisioning & Data', 'Import / export JSON, reset',
          Icons.cloud_sync_outlined, (_) => const DataToolsScreen()),
      _AdminItem('Admin Account', 'Credentials & sign out',
          Icons.manage_accounts_outlined, (_) => const AccountScreen()),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Console'),
        actions: [
          IconButton(
            tooltip: 'View site',
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.visibility_outlined),
          ),
          IconButton(
            tooltip: 'Sign out',
            onPressed: () => context.read<AuthController>().signOut(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                theme.colorScheme.primary,
                theme.colorScheme.secondary,
              ]),
              borderRadius: BorderRadius.circular(site.config.cornerRadius),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Customizing',
                    style: theme.textTheme.labelLarge?.copyWith(
                        color: Colors.white.withOpacity(0.85))),
                const SizedBox(height: 4),
                Text(site.config.churchName,
                    style: theme.textTheme.headlineSmall?.copyWith(
                        color: Colors.white, fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Text('Every change saves instantly and updates the live app.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withOpacity(0.9))),
              ],
            ),
          ),
          GridView.count(
            crossAxisCount: Responsive.gridColumns(context,
                mobile: 1, tablet: 2, desktop: 3),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: Responsive.isMobile(context) ? 4 : 2.4,
            children: [
              for (final item in items)
                Card(
                  child: InkWell(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: item.builder),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor:
                                theme.colorScheme.primaryContainer,
                            child: Icon(item.icon,
                                color: theme.colorScheme.onPrimaryContainer),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(item.title,
                                    style: theme.textTheme.titleSmall?.copyWith(
                                        fontWeight: FontWeight.w700)),
                                Text(item.subtitle,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                        color: theme
                                            .colorScheme.onSurfaceVariant)),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
