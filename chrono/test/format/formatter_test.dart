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
        final date = Date(2024, index + 1, 1);
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
        final date = Date(2024, 1, index + 1);
        expect(date.toString(const [.weekdayName(.full)]), name);
        expect(
          date.toString(const [.weekdayName(.short)]),
          name.substring(0, 3),
        );
      });
    }
  });

  group('week numbers from Sunday and Monday', () {
    String format(Date date) =>
        date.toString(const [.weekFromSun(), .literal(' '), .weekFromMon()]);

    test('known dates', () {
      // 2023-01-01 is a Sunday.
      expect(format(Date(2023, 1, 1)), '01 00');
      expect(format(Date(2023, 1, 2)), '01 01');
      expect(format(Date(2023, 1, 7)), '01 01');
      expect(format(Date(2023, 1, 8)), '02 01');
      // 2022-01-01 is a Saturday.
      expect(format(Date(2022, 1, 1)), '00 00');
      expect(format(Date(2022, 1, 2)), '01 00');
      expect(format(Date(2022, 1, 3)), '01 01');
      expect(format(Date(2022, 12, 31)), '52 52');
      expect(Date(2023, 1, 1).weekNumberStartingOn(.sunday), 1);
      expect(Date(2023, 1, 1).weekNumberStartingOn(.monday), 0);
    });

    test('round trip through parsing', () {
      const fromSun = <DateFormatItem>[
        .year(),
        .literal(' '),
        .weekFromSun(),
        .weekday(),
      ];
      const fromMon = <DateFormatItem>[
        .year(),
        .literal(' '),
        .weekFromMon(),
        .weekday(),
      ];

      var date = Date(2020, 1, 1);
      for (var i = 0; i < 3 * 366; i++, date = date.next) {
        expect(Date.parse(date.toString(fromSun), fromSun), date);
        expect(Date.parse(date.toString(fromMon), fromMon), date);
      }
    });
  });

  group('AM/PM', () {
    String format(int hour, ChronoCasing casing) =>
        Time(hour)
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
