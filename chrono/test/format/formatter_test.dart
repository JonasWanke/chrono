import 'package:chrono/chrono.dart';
import 'package:test/test.dart';

void main() {
  group('month names', () {
    const names = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    for (final (index, name) in names.indexed) {
      test(name, () {
        final date = Date.fromRaw(2024, index + 1, 1);
        expect(date.toString(const [.monthName(.full)]), name);
        expect(date.toString(const [.monthName(.short)]), name.substring(0, 3));
      });
    }
  });

  group('weekday names', () {
    const names = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];

    for (final (index, name) in names.indexed) {
      test(name, () {
        // 2024-01-01 is a Monday.
        final date = Date.fromRaw(2024, 1, index + 1);
        expect(date.toString(const [.weekdayName(.full)]), name);
        expect(
          date.toString(const [.weekdayName(.short)]),
          name.substring(0, 3),
        );
      });
    }
  });

  group('AM/PM', () {
    String format(int hour, ChronoCasing casing) =>
        Time.from(hour)
            .toString([const .hour12(), const .literal(' '), .amPm(casing)]);

    test('after midnight and before noon', () {
      expect(format(0, .upper), '12 AM');
      expect(format(0, .lower), '12 am');
      expect(format(1, .upper), '01 AM');
      expect(format(11, .lower), '11 am');
    });
    test('from noon to midnight', () {
      expect(format(12, .upper), '12 PM');
      expect(format(12, .lower), '12 pm');
      expect(format(13, .upper), '01 PM');
      expect(format(23, .lower), '11 pm');
    });
  });
}
