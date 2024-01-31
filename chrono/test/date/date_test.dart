import 'package:chrono/chrono.dart';
import 'package:glados/glados.dart';

import '../utils.dart';

void main() {
  setChronoGladosDefaults();

  testDataClassBasics(jsonConverters: [const DateAsIsoStringJsonConverter()]);

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

  // Arithmetic with `MonthsDuration` isn't always round-trippable.
  Glados2<Date, FixedDaysDuration>().test(
    '+, -, and difference(…)',
    (date, duration) {
      expect(date + duration - duration, date);
      expect((date + duration).difference(date), duration);
    },
  );
  test('date plus month landing on non-existing February 29', () {
    expect(
      Date.from(const Year(2023), Month.january, 31).unwrap() + const Months(1),
      Date.from(const Year(2023), Month.february, 28).unwrap(),
    );
  });
  Glados<Date>().test('next and previous', (date) {
    expect(date.next.previous, date);
  });
}
