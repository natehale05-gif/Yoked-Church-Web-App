import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/volunteer_assignment.dart';
import '../models/volunteer_position.dart';
import 'notification_service.dart';

class VolunteerService {
  final NotificationService _notifications = NotificationService();

  CollectionReference<Map<String, dynamic>> get _positions => FirebaseFirestore.instance.collection('volunteerPositions');
  CollectionReference<Map<String, dynamic>> get _assignments =>
      FirebaseFirestore.instance.collection('volunteerAssignments');

  Future<List<VolunteerPosition>> fetchPositions() async {
    final snapshot = await _positions.orderBy('date').get();
    return snapshot.docs.map((doc) => VolunteerPosition.fromMap(doc.id, doc.data())).toList();
  }

  Future<void> createPosition(VolunteerPosition position) {
    return _positions.add(position.toMap());
  }

  Future<void> updatePosition(VolunteerPosition position) {
    return _positions.doc(position.id).update(position.toMap());
  }

  Future<void> deletePosition(String id) {
    return _positions.doc(id).delete();
  }

  Future<List<VolunteerAssignment>> fetchAssignmentsForPosition(String positionId) async {
    final snapshot = await _assignments.where('positionId', isEqualTo: positionId).get();
    return snapshot.docs.map((doc) => VolunteerAssignment.fromMap(doc.id, doc.data())).toList();
  }

  Future<List<VolunteerAssignment>> fetchMyAssignments(String uid) async {
    final snapshot = await _assignments.where('uid', isEqualTo: uid).get();
    return snapshot.docs.map((doc) => VolunteerAssignment.fromMap(doc.id, doc.data())).toList();
  }

  /// Staff-only: assign a member directly - immediately `approved` since
  /// the admin already made the call, and notifies the member right away.
  Future<void> assignMember({
    required VolunteerPosition position,
    required String uid,
    required String adminUid,
  }) async {
    final assignment = VolunteerAssignment(
      id: '',
      positionId: position.id,
      uid: uid,
      status: AssignmentStatus.approved,
      assignedBy: adminUid,
      assignedAt: DateTime.now(),
    );
    await _assignments.add(assignment.toMap());
    await _notifyAssigned(position: position, uid: uid);
  }

  /// Member-only: request an open position - starts `pending` until a
  /// staff member approves it (see `approveAssignment`).
  Future<void> selfSignUp({required String positionId, required String uid}) {
    final assignment = VolunteerAssignment(
      id: '',
      positionId: positionId,
      uid: uid,
      status: AssignmentStatus.pending,
      assignedBy: 'self',
      assignedAt: DateTime.now(),
    );
    return _assignments.add(assignment.toMap());
  }

  /// Staff-only: approve a pending self-signup - this is the moment it
  /// actually becomes a confirmed assignment, so it's what triggers the
  /// notification for a self-signup (there's nothing to notify about
  /// while it's merely pending).
  Future<void> approveAssignment({required VolunteerAssignment assignment, required VolunteerPosition position}) async {
    await _assignments.doc(assignment.id).update({'status': 'approved'});
    await _notifyAssigned(position: position, uid: assignment.uid);
  }

  Future<void> declineAssignment(String id) {
    return _assignments.doc(id).update({'status': 'declined'});
  }

  Future<void> deleteAssignment(String id) {
    return _assignments.doc(id).delete();
  }

  Future<void> _notifyAssigned({required VolunteerPosition position, required String uid}) {
    return _notifications.create(
      uid: uid,
      title: "You're serving!",
      message: 'You have been assigned to "${position.title}".',
      linkPath: '/account/volunteering',
    );
  }
}
