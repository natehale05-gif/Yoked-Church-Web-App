class GivingRecord {
  final String id;
  final String uid;
  final double amount;
  final DateTime date;
  final String fund;
  final String note;

  const GivingRecord({
    required this.id,
    required this.uid,
    required this.amount,
    required this.date,
    required this.fund,
    this.note = '',
  });

  factory GivingRecord.fromMap(String id, Map<String, dynamic> map) {
    return GivingRecord(
      id: id,
      uid: map['uid'] as String? ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0,
      date: DateTime.tryParse(map['date'] as String? ?? '') ?? DateTime.now(),
      fund: map['fund'] as String? ?? 'General Fund',
      note: map['note'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'amount': amount,
        'date': date.toIso8601String(),
        'fund': fund,
        'note': note,
      };
}
