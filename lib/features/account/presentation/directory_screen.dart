import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/settings_providers.dart';
import '../../../core/widgets/app_shell.dart';
import '../../../core/widgets/async_value_widget.dart';
import '../../../core/widgets/section_container.dart';
import '../../auth/application/auth_providers.dart';
import '../../auth/domain/app_user.dart';
import 'account_header.dart';

class DirectoryScreen extends ConsumerWidget {
  const DirectoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(currentUserProvider);

    return PageBody(
      children: [
        const AccountHeader(
          title: 'Member Directory',
          subtitle: 'Members who have chosen to be listed here.',
        ),
        SectionContainer(
          maxWidth: 720,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (me != null && !me.directoryOptIn) _OptInPrompt(),
              AsyncListWidget<AppUser>(
                value: ref.watch(memberDirectoryProvider),
                errorContext: 'the directory',
                emptyMessage: 'No members have opted into the directory yet.',
                data: (members) => Column(
                  children: [for (final member in members) _MemberTile(member: member)],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _OptInPrompt extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.visibility_off_outlined),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                "You're not listed in the directory. You can opt in from your profile.",
                style: TextStyle(color: Colors.black87),
              ),
            ),
            TextButton(
              onPressed: () => context.go('/account/profile'),
              child: const Text('Profile'),
            ),
          ],
        ),
      ),
    );
  }
}

class _MemberTile extends ConsumerWidget {
  final AppUser member;

  const _MemberTile({required this.member});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brand = ref.watch(settingsProvider).colors;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: brand.primary.withValues(alpha: 0.1),
          child: Text(member.initial, style: TextStyle(color: brand.primary, fontWeight: FontWeight.w700)),
        ),
        title: Text(member.displayName, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text([member.email, member.phone].where((s) => s.isNotEmpty).join(' · ')),
      ),
    );
  }
}
