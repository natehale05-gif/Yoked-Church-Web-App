import 'package:flutter/foundation.dart';

@immutable
class GivingRecord {
  final String id;
  final String uid;
  final double amount;
  final DateTime date;
  final String fund;
  final String method;
  final String note;

  const GivingRecord({
    this.id = '',
    required this.uid,
    required this.amount,
    required this.date,
    this.fund = 'General Fund',
    this.method = '',
    this.note = '',
  });

  factory GivingRecord.fromMap(String id, Map<String, dynamic> map) => GivingRecord(
        id: id,
        uid: map['uid'] as String? ?? '',
        amount: (map['amount'] as num?)?.toDouble() ?? 0,
        date: DateTime.tryParse(map['date'] as String? ?? '') ?? DateTime.now(),
        fund: map['fund'] as String? ?? 'General Fund',
        method: map['method'] as String? ?? '',
        note: map['note'] as String? ?? '',
      );

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'amount': amount,
        'date': date.toIso8601String(),
        'fund': fund,
        'method': method,
        'note': note,
      };

  GivingRecord copyWith({String? id}) => GivingRecord(
        id: id ?? this.id,
        uid: uid,
        amount: amount,
        date: date,
        fund: fund,
        method: method,
        note: note,
      );
}

/// Per-year totals for the giving history screen and the annual statement.
@immutable
class GivingSummary {
  final int year;
  final double total;
  final List<GivingRecord> records;

  const GivingSummary({required this.year, required this.total, required this.records});

  static List<GivingSummary> byYear(List<GivingRecord> records) {
    final grouped = <int, List<GivingRecord>>{};
    for (final record in records) {
      grouped.putIfAbsent(record.date.year, () => []).add(record);
    }
    final summaries = grouped.entries.map((entry) {
      final sorted = entry.value..sort((a, b) => b.date.compareTo(a.date));
      final total = sorted.fold<double>(0, (sum, r) => sum + r.amount);
      return GivingSummary(year: entry.key, total: total, records: sorted);
    }).toList();
    summaries.sort((a, b) => b.year.compareTo(a.year));
    return summaries;
  }
}
