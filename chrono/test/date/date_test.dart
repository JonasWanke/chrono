import 'package:chrono/chrono.dart';
import 'package:glados/glados.dart';

import '../utils.dart';

void main() {
  setChronoGladosDefaults();

  // ignore: missing-test-assertion
  testDataClassBasics(
    preciseCodecs: const [
      DateAsStringCodec(),
      DateAsStringCodec(Date.isoOrdinalFormat),
      DateAsStringCodec(Date.isoWeekDateFormat),
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

  // Arithmetic with `Months` isn't always round-trippable.
  Glados2<Date, Days>().test('+, -, and daysSince(…)', (date, duration) {
    expect(date + duration - duration, date);
    expect((date + duration).daysSince(date), duration);
  });
  Glados2<Date, Date>().test('daysSince(…) and daysUntil(…)', (dateA, dateB) {
    expect(dateA.daysUntil(dateB), -dateA.daysSince(dateB));
    expect(dateA + dateA.daysUntil(dateB), dateB);
  });
  Glados<Date>().test('difference methods', (date) {
    expect(date.daysSince(date), const Days(0));
    final MonthsDays(:months, :days) = date.until(date);
    expect(months, const Months(0));
    expect(days, const Days(0));
  });
  group('until(…)', () {
    Glados2<Date, Date>().test('fulfills contract', (dateA, dateB) {
      final MonthsDays(:months, :days) = dateA.until(dateB);
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
        final dateA = Date.from(year, monthA, dayA);
        final dateB = Date.from(year, monthB, dayB);
        final MonthsDays(:months, :days) = dateA.until(dateB);
        return (months, days);
      }

      expect(until(Month.january, 1, Month.january, 1), const (
        Months(0),
        Days(0),
      ));

      // Non-negative
      expect(until(Month.january, 1, Month.january, 2), const (
        Months(0),
        Days(1),
      ));
      expect(until(Month.january, 1, Month.january, 31), const (
        Months(0),
        Days(30),
      ));
      expect(until(Month.january, 1, Month.february, 1), const (
        Months(1),
        Days(0),
      ));
      expect(until(Month.january, 1, Month.february, 2), const (
        Months(1),
        Days(1),
      ));

      expect(until(Month.january, 10, Month.february, 1), const (
        Months(0),
        Days(22),
      ));
      expect(until(Month.january, 10, Month.february, 9), const (
        Months(0),
        Days(30),
      ));
      expect(until(Month.january, 10, Month.february, 10), const (
        Months(1),
        Days(0),
      ));
      expect(until(Month.january, 10, Month.february, 11), const (
        Months(1),
        Days(1),
      ));

      // Negative
      expect(until(Month.january, 2, Month.january, 1), const (
        Months(0),
        Days(-1),
      ));
      expect(until(Month.january, 31, Month.january, 1), const (
        Months(0),
        Days(-30),
      ));
      expect(until(Month.february, 1, Month.january, 1), const (
        Months(-1),
        Days(0),
      ));
      expect(until(Month.february, 2, Month.january, 1), const (
        Months(-1),
        Days(-1),
      ));

      expect(until(Month.february, 1, Month.january, 10), const (
        Months(0),
        Days(-22),
      ));
      expect(until(Month.february, 9, Month.january, 10), const (
        Months(0),
        Days(-30),
      ));
      expect(until(Month.february, 10, Month.january, 10), const (
        Months(-1),
        Days(0),
      ));
      expect(until(Month.february, 11, Month.january, 10), const (
        Months(-1),
        Days(-1),
      ));

      expect(until(Month.september, 2, Month.november, 30), const (
        Months(2),
        Days(28),
      ));
      expect(until(Month.february, 1, Month.march, 30, const Year(0)), const (
        Months(1),
        Days(29),
      ));
    });
  });
  group('until(…) with smallestMonthUnit', () {
    Glados3<Date, Date, MonthUnit>().test('fulfills contract', (
      dateA,
      dateB,
      unit,
    ) {
      final result = dateA.until(dateB, smallestMonthUnit: unit);
      expect(dateA + result, dateB);
      expect(result.months.isMultipleOf(unit), true);
      expect(
        result.months.isNonNegative && result.days.isNonNegative ||
            result.months.isNonPositive && result.days.isNonPositive,
        true,
      );
    });
    test('edge cases', () {
      final start = Date.from(const Year(2020), Month.january, 1);
      final end = Date.from(const Year(2023), Month.march, 15);
      final years = start.until(end, smallestMonthUnit: .years);
      expect(years.months, const Months(36));
      expect(years.days, const Days(73));

      final quarters = start.until(
        Date.from(const Year(2020), Month.march, 15),
        smallestMonthUnit: .quarters,
      );
      expect(quarters.months, const Months(0));
      expect(quarters.days, const Days(74));
    });
  });
  group('since(…)', () {
    Glados3<Date, Date, MonthUnit>().test('fulfills contract', (
      dateA,
      dateB,
      unit,
    ) {
      expect(dateA - dateA.since(dateB, smallestMonthUnit: unit), dateB);
    });
    test('is anchored at the receiver', () {
      final jan30 = Date.from(const Year(2023), Month.january, 30);
      final mar1 = Date.from(const Year(2023), Month.march, 1);

      final forward = jan30.until(mar1);
      expect(forward.months, const Months(1));
      expect(forward.days, const Days(1));

      final backward = mar1.since(jan30);
      expect(backward.months, const Months(1));
      expect(backward.days, const Days(2));

      final negative = jan30.since(mar1);
      expect(negative.months, const Months(-1));
      expect(negative.days, const Days(-1));
    });
  });
  Glados2<Date, Date>().test('until(…) split into years', (dateA, dateB) {
    final MonthsDays(:months, :days) = dateA.until(dateB);
    final parts = months.split({.years, .months});
    expect(
      dateA + Months.fromYears(parts.years) + Months(parts.months) + days,
      dateB,
    );
  });

  test('date plus month landing on non-existing February 29', () {
    expect(
      Date.from(const Year(2023), Month.january, 31) + const Months(1),
      Date.from(const Year(2023), Month.february, 28),
    );
  });
  Glados<Date>().test('next and previous', (date) {
    expect(date.next.previous, date);
  });

  group('age(…)', () {
    int ageOn(Date birthday, Date onDate) => birthday.age(onDate: onDate);

    test('birthday already happened this year', () {
      expect(ageOn(Date.fromRaw(2000, 1, 1), Date.fromRaw(2024, 1, 15)), 24);
    });
    test('birthday is today', () {
      expect(ageOn(Date.fromRaw(2000, 1, 15), Date.fromRaw(2024, 1, 15)), 24);
    });
    test('birthday has not happened yet this year', () {
      expect(ageOn(Date.fromRaw(2000, 12, 1), Date.fromRaw(2024, 1, 15)), 23);
      expect(ageOn(Date.fromRaw(2000, 1, 16), Date.fromRaw(2024, 1, 15)), 23);
    });
    test('born on February 29', () {
      final birthday = Date.fromRaw(2000, 2, 29);
      expect(ageOn(birthday, Date.fromRaw(2023, 2, 28)), 22);
      expect(ageOn(birthday, Date.fromRaw(2023, 3, 1)), 23);
      expect(ageOn(birthday, Date.fromRaw(2024, 2, 29)), 24);
    });
    test('age is never negative for a past birthday', () {
      expect(ageOn(Date.fromRaw(2024, 1, 15), Date.fromRaw(2024, 1, 15)), 0);
    });
  });

  test('toString()', () {
    expect(Date.unixEpoch.toString(), '1970-01-01');
    expect(Date.fromRaw(2026, 05, 12).toString(), '2026-05-12');
  });
  test('toOrdinalString()', () {
    expect(Date.unixEpoch.toString(Date.isoOrdinalFormat), '1970-001');
    expect(
      Date.fromRaw(2026, 05, 12).toString(Date.isoOrdinalFormat),
      '2026-132',
    );
  });
}
