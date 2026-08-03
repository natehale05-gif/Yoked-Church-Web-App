import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/church_settings.dart';
import '../../../core/config/settings_providers.dart';
import '../../audit_log/application/audit_providers.dart';

final settingsControllerProvider =
    StateNotifierProvider<SettingsController, AsyncValue<void>>((ref) => SettingsController(ref));

/// Saves church branding/config, and records who changed it.
class SettingsController extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;

  SettingsController(this._ref) : super(const AsyncValue.data(null));

  Future<bool> save(ChurchSettings settings) async {
    state = const AsyncValue.loading();
    try {
      await _ref.read(settingsRepositoryProvider).save(settings);
      // Push the new values into the live app immediately rather than
      // waiting for the next stream emission, so the admin sees their
      // rebrand take effect the moment they hit save.
      _ref.invalidate(churchSettingsProvider);
      await _ref.read(auditLoggerProvider).record(
            action: 'updated',
            entity: 'church settings',
            details: settings.churchName,
          );
      state = const AsyncValue.data(null);
      return true;
    } catch (error, stack) {
      state = AsyncValue.error(error, stack);
      return false;
    }
  }
}
