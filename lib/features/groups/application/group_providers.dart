import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_providers.dart';
import '../data/group_repository.dart';
import '../domain/group.dart';

final groupRepositoryProvider = Provider<GroupRepository>((ref) {
  throw UnimplementedError('groupRepositoryProvider must be overridden in ProviderScope');
});

final membershipRepositoryProvider = Provider<MembershipRepository>((ref) {
  throw UnimplementedError('membershipRepositoryProvider must be overridden in ProviderScope');
});

final groupsProvider = StreamProvider<List<ChurchGroup>>((ref) {
  return ref.watch(groupRepositoryProvider).watchAll();
});

final groupByIdProvider = FutureProvider.family<ChurchGroup?, String>((ref, id) {
  return ref.watch(groupRepositoryProvider).fetchById(id);
});

/// Bumped after a join request so dependent views refetch.
final groupRefreshProvider = StateProvider<int>((ref) => 0);

final myMembershipsProvider = FutureProvider<List<GroupMembership>>((ref) async {
  ref.watch(groupRefreshProvider);
  final uid = ref.watch(currentUserProvider)?.uid;
  if (uid == null) return const [];
  return ref.watch(membershipRepositoryProvider).forMember(uid);
});

final groupMembershipsProvider = FutureProvider.family<List<GroupMembership>, String>((ref, groupId) {
  ref.watch(groupRefreshProvider);
  return ref.watch(membershipRepositoryProvider).forGroup(groupId);
});

final groupControllerProvider = Provider<GroupController>((ref) => GroupController(ref));

class GroupController {
  final Ref _ref;

  GroupController(this._ref);

  MembershipRepository get _memberships => _ref.read(membershipRepositoryProvider);

  /// A member's own request always starts pending - approval is a staff
  /// action, and the Firestore rules enforce that too.
  Future<void> requestToJoin(String groupId) async {
    final user = _ref.read(currentUserProvider);
    if (user == null) return;
    await _memberships.create(GroupMembership(
      groupId: groupId,
      uid: user.uid,
      memberName: user.displayName,
      status: MembershipStatus.pending,
      joinedAt: DateTime.now(),
    ));
    _bump();
  }

  Future<void> approve(GroupMembership membership) async {
    await _memberships.update(membership.copyWith(status: MembershipStatus.approved));
    _bump();
  }

  Future<void> remove(String membershipId) async {
    await _memberships.delete(membershipId);
    _bump();
  }

  void _bump() => _ref.read(groupRefreshProvider.notifier).state++;
}
