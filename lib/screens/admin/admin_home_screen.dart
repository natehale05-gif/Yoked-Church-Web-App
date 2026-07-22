import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../config/church_config.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/admin_header.dart';
import '../../widgets/section_container.dart';

class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;

    return Column(
      children: [
        AdminHeader(
          title: 'Welcome, ${user?.displayName.split(' ').first ?? 'there'}',
          subtitle: "Manage this church's content from one place.",
        ),
        SectionContainer(
          maxWidth: 800,
          child: Wrap(
            spacing: 20,
            runSpacing: 20,
            children: const [
              _AdminTile(icon: Icons.play_circle_outline, label: 'Sermons', path: '/admin/sermons'),
              _AdminTile(icon: Icons.event_outlined, label: 'Events', path: '/admin/events'),
              _AdminTile(icon: Icons.mail_outline, label: 'Connect Inbox', path: '/admin/connect'),
              _AdminTile(icon: Icons.groups_outlined, label: 'Groups', path: '/admin/groups'),
            ],
          ),
        ),
      ],
    );
  }
}

class _AdminTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String path;

  const _AdminTile({required this.icon, required this.label, required this.path});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.go(path),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 180,
        padding: const EdgeInsets.symmetric(vertical: 28),
        decoration: BoxDecoration(border: Border.all(color: Colors.black12), borderRadius: BorderRadius.circular(10)),
        child: Column(
          children: [
            Icon(icon, size: 32, color: ChurchConfig.primaryColor),
            const SizedBox(height: 12),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
