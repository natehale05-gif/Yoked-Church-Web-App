import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../audit_log/application/audit_providers.dart';
import '../../audit_log/domain/audit_entry.dart';
import 'admin_header.dart';

class AuditAdminScreen extends ConsumerWidget {
  const AuditAdminScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AdminListScaffold<AuditEntry>(
      title: 'Audit Log',
      subtitle: 'Who changed settings, roles, and content - and when.',
      value: ref.watch(auditLogProvider),
      errorContext: 'the audit log',
      emptyMessage: 'Nothing recorded yet. Settings, role, and deletion changes appear here.',
      maxWidth: 820,
      itemBuilder: (entry) => Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          dense: true,
          leading: const Icon(Icons.history, size: 20),
          title: Text(entry.summary),
          subtitle: Text(
            '${entry.actorName} · ${DateFormat.yMMMd().add_jm().format(entry.at)}',
          ),
        ),
      ),
    );
  }
}
