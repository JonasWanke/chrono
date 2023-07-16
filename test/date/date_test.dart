import 'package:chrono/chrono.dart';
import 'package:glados/glados.dart';

import '../utils.dart';

void main() {
  setChronoGladosDefaults();

  testDataClassBasics(Date.fromJson);

  Glados<Date>().test('daysSinceUnixEpoch', (date) {
    expect(Date.fromDaysSinceUnixEpoch(date.daysSinceUnixEpoch), date);
  });

  // `asWeekDate` and `asOrdinalDate` are tested with `WeekDate` and
  // `OrdinalDate`, respectively.

  Glados<Date>().test('atMidnight', (date) {
    final atMidnight = date.atMidnight;
    expect(atMidnight.date, date);
    expect(atMidnight.time, Time.midnight);
  });
  Glados<Date>().test('atNoon', (date) {
    final atNoon = date.atNoon;
    expect(atNoon.date, date);
    expect(atNoon.time, Time.noon);
  });

  test('date plus month landing on non-existing February 29', () {
    expect(
      Date.fromThrowing(const Year(2023), Month.january, 31) + const Months(1),
      Date.fromThrowing(const Year(2023), Month.february, 28),
    );
  });
  Glados<Date>().test('next and previous', (date) {
    expect(date.next.previous, date);
  });
}
