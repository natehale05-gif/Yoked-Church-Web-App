import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/church_group.dart';
import '../models/group_membership.dart';

class GroupService {
  CollectionReference<Map<String, dynamic>> get _groups => FirebaseFirestore.instance.collection('groups');
  CollectionReference<Map<String, dynamic>> get _memberships =>
      FirebaseFirestore.instance.collection('groupMemberships');

  Future<List<ChurchGroup>> fetchGroups() async {
    final snapshot = await _groups.orderBy('name').get();
    return snapshot.docs.map((doc) => ChurchGroup.fromMap(doc.id, doc.data())).toList();
  }

  Future<ChurchGroup?> fetchGroup(String id) async {
    final doc = await _groups.doc(id).get();
    if (!doc.exists) return null;
    return ChurchGroup.fromMap(doc.id, doc.data()!);
  }

  Future<List<GroupMembership>> fetchMyMemberships(String uid) async {
    final snapshot = await _memberships.where('uid', isEqualTo: uid).get();
    return snapshot.docs.map((doc) => GroupMembership.fromMap(doc.id, doc.data())).toList();
  }

  Future<void> requestToJoin({required String groupId, required String uid}) {
    final membership = GroupMembership(
      id: '',
      groupId: groupId,
      uid: uid,
      status: MembershipStatus.pending,
      joinedAt: DateTime.now(),
    );
    return _memberships.add(membership.toMap());
  }
}
