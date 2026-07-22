import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../config/church_config.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/account_header.dart';
import '../../widgets/section_container.dart';

class AccountHomeScreen extends StatelessWidget {
  const AccountHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;

    return Column(
      children: [
        AccountHeader(
          title: 'Hi, ${user?.displayName.split(' ').first ?? 'there'}',
          subtitle: 'Manage your profile, groups, events, and giving.',
        ),
        SectionContainer(
          maxWidth: 800,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 20,
                runSpacing: 20,
                children: [
                  _AccountTile(icon: Icons.person_outline, label: 'Profile', path: '/account/profile'),
                  _AccountTile(icon: Icons.groups_outlined, label: 'Groups', path: '/account/groups'),
                  _AccountTile(icon: Icons.event_available_outlined, label: 'My Events', path: '/account/events'),
                  _AccountTile(icon: Icons.people_alt_outlined, label: 'Directory', path: '/account/directory'),
                  _AccountTile(icon: Icons.favorite_outline, label: 'Giving', path: '/account/giving'),
                ],
              ),
              const SizedBox(height: 32),
              const Divider(),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () async {
                  await context.read<AuthProvider>().signOut();
                  if (context.mounted) context.go('/');
                },
                icon: const Icon(Icons.logout),
                label: const Text('Sign Out'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AccountTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String path;

  const _AccountTile({required this.icon, required this.label, required this.path});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.go(path),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 160,
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Icon(icon, size: 30, color: ChurchConfig.primaryColor),
            const SizedBox(height: 10),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
