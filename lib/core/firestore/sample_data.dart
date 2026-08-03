/// Keeping the bundled demo alive.
///
/// The zero-backend build is what sells this template: clone it, run it,
/// click through a working church site with no Firebase account. Every
/// date in `assets/data/*.json` is written by hand, so left alone that
/// demo has a hard expiry - the sign-up form closes, the events page
/// empties, and the reports page falls to zero as real time passes it by.
///
/// So the sample data is read as *relative* to the day it was authored,
/// and shifted forward on load.
library;

/// The day the bundled sample data was written.
///
/// Everything in `assets/data/` is relative to this. Move it when the
/// sample content is next rewritten wholesale; do not move it to "fix"
/// one stale entry, because the whole set shifts together.
final DateTime sampleDataEpoch = DateTime(2026, 7, 29);

/// A full ISO-8601 date or date-time, and nothing else.
///
/// Anchored at both ends deliberately. A staff bio in the sample data
/// reads "John has served here since 2014", and a looser pattern applied
/// to prose is exactly how that becomes 2015.
final RegExp _isoDate = RegExp(
  r'^\d{4}-\d{2}-\d{2}'
  r'(?:[T ]\d{2}:\d{2}(?::\d{2}(?:\.\d+)?)?)?$',
);

/// How far to move the sample data so it reads as "recent".
///
/// **Whole weeks, never whole days.** Weekday alignment is load-bearing
/// here: the sample "Sunday Worship Gathering" is on a Sunday, the
/// Tuesday morning group books its room on a Tuesday, Men's Breakfast is
/// on a Saturday. Shifting by an arbitrary number of days would put the
/// Sunday service on a Thursday and quietly make the demo nonsense.
///
/// The cost is that the data can be up to six days behind, which nobody
/// notices, versus a weekday that is visibly wrong, which everybody does.
///
/// Never negative: a machine with a badly set clock should leave the
/// sample data where it is rather than drag it into the past.
Duration sampleDataShift({DateTime? now, DateTime? epoch}) {
  final from = epoch ?? sampleDataEpoch;
  final to = now ?? DateTime.now();
  final weeks = to.difference(from).inDays ~/ 7;
  return Duration(days: weeks < 0 ? 0 : weeks * 7);
}

/// Returns [decoded] with every ISO date string moved forward by [shift].
///
/// Walks maps and lists so it applies to nested structures - a form's
/// `fields`, a member's `household` - without any model knowing about it.
/// Anything that is not a date passes through untouched.
Object? rollSampleDates(Object? decoded, Duration shift) {
  if (shift == Duration.zero) return decoded;

  if (decoded is Map) {
    return {
      for (final entry in decoded.entries) entry.key: rollSampleDates(entry.value, shift),
    };
  }
  if (decoded is List) {
    return [for (final item in decoded) rollSampleDates(item, shift)];
  }
  if (decoded is String) return _shiftIfDate(decoded, shift);
  return decoded;
}

String _shiftIfDate(String value, Duration shift) {
  if (!_isoDate.hasMatch(value)) return value;

  final parsed = DateTime.tryParse(value);
  if (parsed == null) return value;

  final shifted = parsed.add(shift);

  // Preserve the shape it arrived in. A bare `2026-07-26` that came back
  // as a full timestamp would still parse, but it reads as noise in a
  // file a church is meant to edit by hand.
  return value.length == 10
      ? shifted.toIso8601String().substring(0, 10)
      : shifted.toIso8601String();
}
