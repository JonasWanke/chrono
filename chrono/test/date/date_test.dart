import 'package:chrono/chrono.dart';
import 'package:glados/glados.dart';

import '../utils.dart';

void main() {
  setChronoGladosDefaults();

  testDataClassBasics(
    jsonConverters: [
      const DateAsIsoStringJsonConverter(),
      const DateAsOrdinalDateIsoStringJsonConverter(),
      const DateAsWeekDateIsoStringJsonConverter(),
    ],
  );

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
    '+, -, and differenceInDays(…)',
    (date, duration) {
      expect(date + duration - duration, date);
      expect((date + duration).differenceInDays(date), duration);
    },
  );
  Glados<Date>().test(
    'difference methods',
    (date) {
      expect(date.differenceInDays(date), const Days(0));
      expect(date.untilInMonthsDays(date), const (Months(0), Days(0)));
    },
  );
  group('untilInMonthsDays(…)', () {
    Glados2<Date, Date>().test('fulfills contract', (dateA, dateB) {
      final (months, days) = dateA.untilInMonthsDays(dateB);
      expect(dateA + months + days, dateB);
    });
    test('edge cases', () {
      (Months, Days) until(
        Month monthA,
        int dayA,
        Month monthB,
        int dayB, [
        Year year = const Year(2024),
      ]) {
        final dateA = Date.from(year, monthA, dayA).unwrap();
        final dateB = Date.from(year, monthB, dayB).unwrap();
        return dateA.untilInMonthsDays(dateB);
      }

      expect(
        until(Month.january, 1, Month.january, 1),
        const (Months(0), Days(0)),
      );

      // Non-negative
      expect(
        until(Month.january, 1, Month.january, 2),
        const (Months(0), Days(1)),
      );
      expect(
        until(Month.january, 1, Month.january, 31),
        const (Months(0), Days(30)),
      );
      expect(
        until(Month.january, 1, Month.february, 1),
        const (Months(1), Days(0)),
      );
      expect(
        until(Month.january, 1, Month.february, 2),
        const (Months(1), Days(1)),
      );

      expect(
        until(Month.january, 10, Month.february, 1),
        const (Months(0), Days(22)),
      );
      expect(
        until(Month.january, 10, Month.february, 9),
        const (Months(0), Days(30)),
      );
      expect(
        until(Month.january, 10, Month.february, 10),
        const (Months(1), Days(0)),
      );
      expect(
        until(Month.january, 10, Month.february, 11),
        const (Months(1), Days(1)),
      );

      // Negative
      expect(
        until(Month.january, 2, Month.january, 1),
        const (Months(0), Days(-1)),
      );
      expect(
        until(Month.january, 31, Month.january, 1),
        const (Months(0), Days(-30)),
      );
      expect(
        until(Month.february, 1, Month.january, 1),
        const (Months(-1), Days(0)),
      );
      expect(
        until(Month.february, 2, Month.january, 1),
        const (Months(-1), Days(-1)),
      );

      expect(
        until(Month.february, 1, Month.january, 10),
        const (Months(0), Days(-22)),
      );
      expect(
        until(Month.february, 9, Month.january, 10),
        const (Months(0), Days(-30)),
      );
      expect(
        until(Month.february, 10, Month.january, 10),
        const (Months(-1), Days(0)),
      );
      expect(
        until(Month.february, 11, Month.january, 10),
        const (Months(-1), Days(-1)),
      );

      expect(
        until(Month.september, 2, Month.november, 30),
        const (Months(2), Days(28)),
      );
      expect(
        until(Month.february, 1, Month.march, 30, const Year(0)),
        const (Months(1), Days(29)),
      );
    });
  });
  Glados2<Date, Date>().test('untilInYearsMonthsDays(…)', (dateA, dateB) {
    final (years, months, days) = dateA.untilInYearsMonthsDays(dateB);
    expect(dateA + years + months + days, dateB);
  });

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
