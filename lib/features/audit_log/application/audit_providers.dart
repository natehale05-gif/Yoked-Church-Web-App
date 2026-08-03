import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_providers.dart';
import '../data/audit_repository.dart';
import '../domain/audit_entry.dart';

final auditRepositoryProvider = Provider<AuditRepository>((ref) {
  throw UnimplementedError('auditRepositoryProvider must be overridden in ProviderScope');
});

final auditRefreshProvider = StateProvider<int>((ref) => 0);

final auditLogProvider = FutureProvider<List<AuditEntry>>((ref) {
  ref.watch(auditRefreshProvider);
  return ref.watch(auditRepositoryProvider).fetchAll();
});

final auditLoggerProvider = Provider<AuditLogger>((ref) => AuditLogger(ref));

class AuditLogger {
  final Ref _ref;

  AuditLogger(this._ref);

  /// Records who did what. Never throws into the caller: failing to write
  /// an audit line must not roll back or block the action itself.
  Future<void> record({required String action, required String entity, String details = ''}) async {
    final actor = _ref.read(currentUserProvider);
    try {
      await _ref.read(auditRepositoryProvider).create(
            AuditEntry(
              actorUid: actor?.uid ?? 'unknown',
              actorName: actor?.displayName ?? 'Unknown',
              action: action,
              entity: entity,
              details: details,
              at: DateTime.now(),
            ),
          );
      _ref.read(auditRefreshProvider.notifier).state++;
    } catch (_) {
      // Intentionally swallowed - see above.
    }
  }
}
