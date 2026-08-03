import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_providers.dart';
import '../../auth/domain/app_user.dart';
import '../../groups/application/group_providers.dart';
import '../../groups/domain/group.dart';
import '../../notifications/application/notification_providers.dart';
import '../data/announcement_repository.dart';
import '../domain/announcement.dart';

final announcementRepositoryProvider = Provider<AnnouncementRepository>((ref) {
  throw UnimplementedError('announcementRepositoryProvider must be overridden in ProviderScope');
});

final announcementRefreshProvider = StateProvider<int>((ref) => 0);

final announcementsProvider = FutureProvider<List<Announcement>>((ref) {
  ref.watch(announcementRefreshProvider);
  return ref.watch(announcementRepositoryProvider).fetchAll();
});

final announcementControllerProvider =
    StateNotifierProvider<AnnouncementController, AsyncValue<void>>((ref) => AnnouncementController(ref));

class AnnouncementController extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;

  AnnouncementController(this._ref) : super(const AsyncValue.data(null));

  /// Stores the announcement so members can browse past ones, then fans
  /// it out to each recipient's notification inbox.
  ///
  /// Fan-out is client-side because there is no server here yet; for a
  /// large congregation this belongs in a Cloud Function, which the
  /// `NotificationSender` seam already allows without touching callers.
  Future<bool> send({
    required String title,
    required String body,
    required AnnouncementAudience audience,
    ChurchGroup? group,
  }) async {
    state = const AsyncValue.loading();
    try {
      final recipients = await _recipients(audience, group);

      await _ref.read(announcementRepositoryProvider).create(
            Announcement(
              title: title,
              body: body,
              audience: audience,
              groupId: group?.id ?? '',
              groupName: group?.name ?? '',
              sentByName: _ref.read(currentUserProvider)?.displayName ?? '',
              recipientCount: recipients.length,
              sentAt: DateTime.now(),
            ),
          );

      await _ref.read(notificationSenderProvider).sendToMany(
            uids: recipients,
            title: title,
            message: body,
            linkPath: '/account/notifications',
            category: 'announcements',
          );

      _ref.read(announcementRefreshProvider.notifier).state++;
      state = const AsyncValue.data(null);
      return true;
    } catch (error, stack) {
      state = AsyncValue.error(error, stack);
      return false;
    }
  }

  Future<List<String>> _recipients(AnnouncementAudience audience, ChurchGroup? group) async {
    switch (audience) {
      case AnnouncementAudience.group:
        if (group == null) return const [];
        final memberships = await _ref.read(membershipRepositoryProvider).forGroup(group.id);
        return memberships
            .where((m) => m.status == MembershipStatus.approved)
            .map((m) => m.uid)
            .toList();
      case AnnouncementAudience.staff:
        final all = await _ref.read(userRepositoryProvider).fetchAll();
        return all.where((u) => u.isStaff).map((u) => u.uid).toList();
      case AnnouncementAudience.everyone:
        final all = await _ref.read(userRepositoryProvider).fetchAll();
        return all.map((u) => u.uid).toList();
    }
  }
}

/// Exposed for the compose screen's audience picker.
final announcementGroupsProvider = Provider<List<ChurchGroup>>((ref) {
  return ref.watch(groupsProvider).valueOrNull ?? const [];
});

/// Convenience so the compose screen can show reach before sending.
final memberCountProvider = Provider<int>((ref) {
  return (ref.watch(allMembersProvider).valueOrNull ?? const <AppUser>[]).length;
});
