import 'package:flutter_test/flutter_test.dart';
import 'package:yoked_church_app/core/firestore/sample_data.dart';
import 'package:yoked_church_app/features/attendance/data/attendance_repository.dart';
import 'package:yoked_church_app/features/events/data/event_repository.dart';
import 'package:yoked_church_app/features/forms/data/form_repository.dart';
import 'package:yoked_church_app/features/rooms/data/room_repository.dart';
import 'package:yoked_church_app/features/volunteering/data/volunteering_repository.dart';

/// The bundled demo is what sells this template, and left alone it has a
/// hard expiry: the sign-up form closes, the events page empties, and the
/// reports fall to zero as real time passes the hand-written dates by.
/// These tests are what stops that coming back.
void main() {
  final epoch = DateTime(2026, 7, 29); // a Wednesday

  group('the shift', () {
    test('is zero on the day the data was written', () {
      expect(sampleDataShift(now: epoch, epoch: epoch), Duration.zero);
    });

    test('is always a whole number of weeks', () {
      // Weekday alignment is load-bearing: the sample Sunday service is
      // on a Sunday and the Tuesday group books its room on a Tuesday.
      for (var days = 0; days < 400; days++) {
        final shift = sampleDataShift(now: epoch.add(Duration(days: days)), epoch: epoch);
        expect(shift.inDays % 7, 0, reason: '$days days after the epoch gave $shift');
      }
    });

    test('never runs backwards on a badly set clock', () {
      expect(sampleDataShift(now: epoch.subtract(const Duration(days: 400)), epoch: epoch), Duration.zero);
      expect(sampleDataShift(now: epoch.subtract(const Duration(days: 1)), epoch: epoch), Duration.zero);
    });

    test('keeps the data at most six days behind', () {
      for (var days = 0; days < 400; days++) {
        final now = epoch.add(Duration(days: days));
        final behind = now.difference(epoch.add(sampleDataShift(now: now, epoch: epoch))).inDays;
        expect(behind, inInclusiveRange(0, 6));
      }
    });
  });

  group('rolling the data forward', () {
    /// A year and a bit later - long enough that untouched sample data
    /// would be entirely in the past.
    Duration aYearOn() => sampleDataShift(now: epoch.add(const Duration(days: 400)), epoch: epoch);

    test('a future-dated entry is still in the future a year later', () {
      final rolled = rollSampleDates(
        // 2026-08-02, four days after the epoch.
        {'start': '2026-08-02T09:00:00'},
        aYearOn(),
      ) as Map;

      final start = DateTime.parse(rolled['start'] as String);
      expect(start.isAfter(epoch.add(const Duration(days: 400))), isTrue);
    });

    test('every shifted date lands on the same weekday', () {
      const dates = ['2026-08-02', '2026-08-04', '2026-08-08', '2026-07-26'];
      for (final date in dates) {
        final before = DateTime.parse(date);
        final after = DateTime.parse(rollSampleDates(date, aYearOn())! as String);
        expect(
          after.weekday,
          before.weekday,
          reason: '$date is a weekday-bearing date in the sample data',
        );
      }
    });

    test('walks nested maps and lists', () {
      final rolled = rollSampleDates(
        [
          {
            'title': 'Camp',
            'closesAt': '2026-08-01T23:59:59',
            'fields': [
              {'label': 'When?', 'default': '2026-08-05'},
            ],
          },
        ],
        const Duration(days: 7),
      ) as List;

      final form = rolled.single as Map;
      expect(form['closesAt'], startsWith('2026-08-08'));
      expect(((form['fields'] as List).single as Map)['default'], '2026-08-12');
      expect(form['title'], 'Camp');
    });

    test('leaves a year mentioned inside prose alone', () {
      // The staff bio in the sample data really does say this, and a
      // looser pattern over raw file text is exactly how it drifts.
      const bio = 'John has served here since 2014. He and his wife Anna have three kids.';
      expect(rollSampleDates(bio, const Duration(days: 365)), bio);
      expect(
        rollSampleDates('Meets 2026-08-02 in the hall', const Duration(days: 7)),
        'Meets 2026-08-02 in the hall',
        reason: 'a date embedded in a sentence is copy, not a field',
      );
    });

    test('leaves other values untouched', () {
      final rolled = rollSampleDates(
        {'headcount': 118, 'published': true, 'slug': 'summer-camp', 'note': null},
        const Duration(days: 7),
      ) as Map;

      expect(rolled['headcount'], 118);
      expect(rolled['published'], isTrue);
      expect(rolled['slug'], 'summer-camp');
      expect(rolled['note'], isNull);
    });

    test('keeps a date-only field date-only', () {
      // These files are meant to be edited by hand; a bare date coming
      // back as a full timestamp reads as noise.
      expect(rollSampleDates('2026-07-26', const Duration(days: 7)), '2026-08-02');
      expect(
        rollSampleDates('2026-07-26T09:00:00', const Duration(days: 7)),
        startsWith('2026-08-02T09:00:00'),
      );
    });

    test('does nothing at all when there is nothing to shift', () {
      const data = {'date': '2026-07-26'};
      expect(rollSampleDates(data, Duration.zero), same(data));
    });
  });

  /// The claim the rest of this file exists to support, made against the
  /// real bundled assets rather than a fixture: whenever someone runs the
  /// demo, it has something to show.
  group('the bundled demo, today', () {
    // Plain `test`, not `testWidgets`: loading a real asset is real I/O,
    // and real I/O inside a widget test's fake-async zone hangs. The
    // binding is still needed for rootBundle to exist at all.
    setUpAll(TestWidgetsFlutterBinding.ensureInitialized);
    test('has events still to come', () async {
      final events = await LocalEventRepository().fetchAll();
      expect(events, isNotEmpty, reason: 'assets/data/events.json should load');
      expect(
        events.where((e) => !e.isPast),
        isNotEmpty,
        reason: 'a demo with no upcoming events looks broken, not unconfigured',
      );
    });

    test('has a sign-up form still open', () async {
      final forms = await LocalFormRepository().fetchAll();
      expect(forms, isNotEmpty);
      expect(
        forms.where((f) => f.isAcceptingSubmissions),
        isNotEmpty,
        reason: 'the public form is the first thing a visitor is asked to do',
      );
    });

    test('has attendance inside the reports window', () async {
      // Reports total over the last 90 days. Sample data that has drifted
      // out of that window makes every tile read zero.
      final records = await LocalAttendanceRepository().fetchAll();
      final cutoff = DateTime.now().subtract(const Duration(days: 90));
      expect(records.where((r) => r.date.isAfter(cutoff)), isNotEmpty);
    });

    test('has volunteer slots and room bookings still ahead', () async {
      final positions = await LocalVolunteerPositionRepository().fetchAll();
      expect(positions.where((p) => p.date.isAfter(DateTime.now())), isNotEmpty);

      final bookings = await LocalBookingRepository().fetchAll();
      expect(bookings.where((b) => !b.isPast), isNotEmpty);
    });

    test('keeps its Sunday services on a Sunday', () async {
      final events = await LocalEventRepository().fetchAll();
      final sunday = events.where((e) => e.title.startsWith('Sunday')).toList();
      expect(sunday, isNotEmpty, reason: 'the sample data has a Sunday gathering');
      for (final event in sunday) {
        expect(event.start.weekday, DateTime.sunday, reason: '"${event.title}" moved off Sunday');
      }
    });
  });
}
