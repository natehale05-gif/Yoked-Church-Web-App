import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/giving_record.dart';

class GivingService {
  CollectionReference<Map<String, dynamic>> get _records => FirebaseFirestore.instance.collection('givingRecords');

  Future<List<GivingRecord>> fetchMyGivingHistory(String uid) async {
    final snapshot = await _records.where('uid', isEqualTo: uid).orderBy('date', descending: true).get();
    return snapshot.docs.map((doc) => GivingRecord.fromMap(doc.id, doc.data())).toList();
  }
}
