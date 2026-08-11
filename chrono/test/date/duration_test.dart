import 'package:chrono/chrono.dart';
import 'package:glados/glados.dart';
import 'package:meta/meta.dart';

import '../utils.dart';

void main() {
  setChronoGladosDefaults();

  group('CompoundCalendarDuration', () {
    // ignore: missing-test-assertion
    _testDurationBasics<CompoundCalendarDuration>();
    Glados2<CompoundCalendarDuration, CalendarDuration>().test(
      '+ and -',
      (first, second) => expect(first + second - second, first),
    );
  });

  group('MonthUnit', () {
    test('per(…) is consistent with monthsPer', () {
      for (final smaller in MonthUnit.values) {
        for (final larger in MonthUnit.values) {
          if (larger.monthsPer < smaller.monthsPer) continue;
          expect(smaller.per(larger) * smaller.monthsPer, larger.monthsPer);
        }
      }
    });
    test('per(…) edge cases', () {
      expect(MonthUnit.months.per(.years), 12);
      expect(MonthUnit.months.per(.quarters), 3);
      expect(MonthUnit.quarters.per(.years), 4);
      expect(MonthUnit.years.per(.decades), 10);
      expect(MonthUnit.years.per(.millennia), 1000);
      expect(MonthUnit.decades.per(.centuries), 10);
      expect(MonthUnit.years.per(.years), 1);
    });
  });

  group('Months', () {
    // ignore: missing-test-assertion
    _testDurationBasics<Months>();
    Glados2<Months, Months>().test('+ and -', (first, second) {
      expect(first + second - second, first);
    });
    Glados<Months>().test('absolute', (duration) {
      expect(duration.absolute.isNonNegative, true);
    });
    Glados<Months>().test('fromYears(…) agrees with roundTo(…)', (duration) {
      final years = duration.inMonths;
      expect(Months.fromYears(years).roundTo(.years), years);
    });

    test('totalIn(…) edge cases', () {
      expect(const Months(12).totalIn(.years), 1.0);
      expect(const Months(-12).totalIn(.years), -1.0);
      expect(const Months(6).totalIn(.quarters), 2.0);
      expect(const Months(12000).totalIn(.millennia), 1.0);
    });

    group('isMultipleOf(…)', () {
      test('edge cases', () {
        expect(const Months(24).isMultipleOf(.years), true);
        expect(const Months(-24).isMultipleOf(.years), true);
        expect(const Months(25).isMultipleOf(.years), false);
        expect(const Months(24).isMultipleOf(.years, increment: 2), true);
        expect(const Months(12).isMultipleOf(.years, increment: 2), false);
      });
      Glados2<Months, MonthUnit>().test('agrees with round(…)', (
        duration,
        unit,
      ) {
        expect(duration.isMultipleOf(unit), duration.round(unit) == duration);
      });
    });

    group('split(…)', () {
      test('empty units throws', () {
        expect(() => const Months(1).split({}), throwsA(isA<AssertionError>()));
      });
      test('years and months edge cases', () {
        void expectYearsMonths(Months duration, int years, int months) {
          final parts = duration.split({.years, .months});
          expect(parts.years, years);
          expect(parts.months, months);
        }

        expectYearsMonths(const Months(13), 1, 1);
        expectYearsMonths(const Months(12), 1, 0);
        expectYearsMonths(const Months(11), 0, 11);
        expectYearsMonths(const Months(1), 0, 1);
        expectYearsMonths(const Months(0), 0, 0);
        expectYearsMonths(const Months(-1), 0, -1);
        expectYearsMonths(const Months(-11), 0, -11);
        expectYearsMonths(const Months(-12), -1, 0);
        expectYearsMonths(const Months(-13), -1, -1);
      });
      test('skipping intermediate units', () {
        final parts = const Months(1234).split({.centuries, .months});
        expect(parts.centuries, 1);
        expect(parts.months, 34);
      });
      test('rounding carries into the next unit up', () {
        // 11 months rounds to one year, which is four quarters.
        final parts = const Months(11).split({.years, .quarters});
        expect(parts.years, 1);
        expect(parts.quarters, 0);

        final negative = const Months(-11).split({.years, .quarters});
        expect(negative.years, -1);
        expect(negative.quarters, 0);
      });
      Glados<Months>().test('years and months recombine', (duration) {
        final parts = duration.split({.years, .months});
        expect(Months.fromYears(parts.years) + Months(parts.months), duration);
      });
      Glados<Months>().test('components share the sign', (duration) {
        final parts = duration.split({
          .millennia,
          .centuries,
          .decades,
          .years,
          .quarters,
          .months,
        });
        final values = [
          parts.millennia,
          parts.centuries,
          parts.decades,
          parts.years,
          parts.quarters,
          parts.months,
        ];
        expect(
          values.every((it) => it >= 0) || values.every((it) => it <= 0),
          true,
        );
      });
      Glados<Months>().test('single unit rounds', (duration) {
        expect(duration.split({.years}).years, duration.roundTo(.years));
      });
    });

    group('MonthParts', () {
      test('unrequested units throw', () {
        final parts = const Months(13).split({.months});
        expect(parts.months, 13);
        expect(() => parts.years, throwsStateError);
        expect(parts.maybe(.years), null);
        expect(parts.has(.years), false);
        expect(parts.has(.months), true);
        expect(parts.units, {MonthUnit.months});
      });
      test('equality includes the requested units', () {
        expect(
          const Months(3).split({.months}),
          const Months(3).split({.months}),
        );
        expect(
          const Months(3).split({.months}),
          isNot(const Months(3).split({.years, .months})),
        );
      });
      test('toString() prints only requested units', () {
        expect(const Months(13).split({.months}).toString(), '13 months');
        expect(
          const Months(13).split({.years, .months}).toString(),
          '1 years, 1 months',
        );
      });
    });
  });

  group('DayUnit', () {
    test('per(…) is consistent with daysPer', () {
      for (final smaller in DayUnit.values) {
        for (final larger in DayUnit.values) {
          if (larger.daysPer < smaller.daysPer) continue;
          expect(smaller.per(larger) * smaller.daysPer, larger.daysPer);
        }
      }
    });
    test('per(…) edge cases', () {
      expect(DayUnit.days.per(.weeks), 7);
      expect(DayUnit.days.per(.fortnights), 14);
      expect(DayUnit.weeks.per(.fortnights), 2);
      expect(DayUnit.weeks.per(.weeks), 1);
    });
  });

  group('Days', () {
    // ignore: missing-test-assertion
    _testDurationBasics<Days>();
    Glados2<Days, Days>().test('+ and -', (first, second) {
      expect(first + second - second, first);
    });
    Glados<Days>().test('absolute', (duration) {
      expect(duration.absolute.isNonNegative, true);
    });
    Glados<Days>().test('fromWeeks(…) agrees with roundTo(…)', (duration) {
      final weeks = duration.inDays;
      expect(Days.fromWeeks(weeks).roundTo(.weeks), weeks);
    });

    group('totalIn(…)', () {
      test('edge cases', () {
        expect(Days.week.totalIn(.weeks), 1.0);
        expect(const Days(-7).totalIn(.weeks), -1.0);
        expect(const Days(14).totalIn(.fortnights), 1.0);
        expect(const Days(3).totalIn(.days), 3.0);
      });
    });

    group('isMultipleOf(…)', () {
      test('edge cases', () {
        expect(const Days(14).isMultipleOf(.weeks), true);
        expect(const Days(-14).isMultipleOf(.weeks), true);
        expect(const Days(15).isMultipleOf(.weeks), false);
        expect(const Days(14).isMultipleOf(.weeks, increment: 2), true);
        expect(Days.week.isMultipleOf(.weeks, increment: 2), false);
      });
      Glados2<Days, DayUnit>().test('agrees with round(…)', (duration, unit) {
        expect(duration.isMultipleOf(unit), duration.round(unit) == duration);
      });
    });

    group('split(…)', () {
      test('edge cases', () {
        final parts = const Days(17).split({.weeks, .days});
        expect(parts.weeks, 2);
        expect(parts.days, 3);

        final negative = const Days(-17).split({.weeks, .days});
        expect(negative.weeks, -2);
        expect(negative.days, -3);

        final skipping = const Days(17).split({.fortnights, .days});
        expect(skipping.fortnights, 1);
        expect(skipping.days, 3);

        // The rounded weeks carry into the fortnights.
        final roundingUp = const Days(13).split({.fortnights, .weeks});
        expect(roundingUp.fortnights, 1);
        expect(roundingUp.weeks, 0);

        final roundingDown = const Days(-13).split({.fortnights, .weeks});
        expect(roundingDown.fortnights, -1);
        expect(roundingDown.weeks, 0);
      });
      Glados<Days>().test('weeks and days recombine', (duration) {
        final parts = duration.split({.weeks, .days});
        expect(Days.fromWeeks(parts.weeks) + Days(parts.days), duration);
      });
      Glados<Days>().test('components share the sign', (duration) {
        final parts = duration.split({.fortnights, .weeks, .days});
        final values = [parts.fortnights, parts.weeks, parts.days];
        expect(
          values.every((it) => it >= 0) || values.every((it) => it <= 0),
          true,
        );
      });
      Glados<Days>().test('single unit rounds', (duration) {
        expect(duration.split({.weeks}).weeks, duration.roundTo(.weeks));
      });
    });

    group('DayParts', () {
      test('unrequested units throw', () {
        final parts = const Days(17).split({.days});
        expect(parts.days, 17);
        expect(() => parts.weeks, throwsStateError);
        expect(parts.maybe(.weeks), null);
        expect(parts.has(.weeks), false);
        expect(parts.has(.days), true);
        expect(parts.units, {DayUnit.days});
      });
      test('equality includes the requested units', () {
        expect(const Days(3).split({.days}), const Days(3).split({.days}));
        expect(
          const Days(3).split({.days}),
          isNot(const Days(3).split({.weeks, .days})),
        );
      });
      test('toString() prints only requested units', () {
        expect(const Days(17).split({.days}).toString(), '17 days');
        expect(
          const Days(17).split({.weeks, .days}).toString(),
          '2 weeks, 3 days',
        );
      });
    });
  });
}

@isTest
void _testDurationBasics<T extends CalendarDuration>() {
  // ignore: unnecessary_parenthesis
  Glados<T>().test('unary -', (duration) => expect(-(-duration), duration));

  Glados<T>().test('multiply with zero', (duration) {
    expect((duration * 0).isZero, true);
  });
  Glados2<T, int>(null, any.intExcept0).test('*, ~/, %, and remainder(…)', (
    duration,
    factor,
  ) {
    expect(duration * factor ~/ factor, duration);
    expect((duration * factor % factor).isZero, true);
    expect((duration * factor).remainder(factor).isZero, true);
  });
}
