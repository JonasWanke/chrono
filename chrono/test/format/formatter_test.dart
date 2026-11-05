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
}
