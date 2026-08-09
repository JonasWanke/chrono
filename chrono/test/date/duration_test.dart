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

  group('MonthsDuration', () {
    Glados<MonthsDuration>().test('absolute', (duration) {
      expect(duration.absolute.isNonNegative, true);
    });
    group('splitYearsMonths', () {
      Glados<MonthsDuration>().test('glados', (duration) {
        final (years, months) = duration.splitYearsMonths;
        expect(
          years.isNonNegative && months.isNonNegative ||
              years.isNonPositive && months.isNonPositive,
          true,
        );
        expect(months + years, duration);
      });
      test('edge cases', () {
        expect(const Months(13).splitYearsMonths, const (Years(1), Months(1)));
        // ignore: use_named_constants
        expect(const Months(12).splitYearsMonths, const (Years(1), Months(0)));
        expect(const Months(11).splitYearsMonths, const (Years(0), Months(11)));
        expect(const Months(1).splitYearsMonths, const (Years(0), Months(1)));
        expect(const Months(0).splitYearsMonths, const (Years(0), Months(0)));
        expect(const Months(-1).splitYearsMonths, const (Years(0), Months(-1)));
        expect(const Months(-11).splitYearsMonths, const (
          Years(0),
          Months(-11),
        ));
        expect(const Months(-12).splitYearsMonths, const (
          Years(-1),
          Months(0),
        ));
        expect(const Months(-13).splitYearsMonths, const (
          Years(-1),
          Months(-1),
        ));
      });
    });
  });
  group('Months', () {
    // ignore: missing-test-assertion
    _testDurationBasics<Months>();
    Glados2<Months, MonthsDuration>().test('+ and -', (first, second) {
      expect(first + second - second, first);
    });
  });
  group('Years', () {
    // ignore: missing-test-assertion
    _testDurationBasics<Years>();
    Glados2<Years, Years>().test('+ and -', (first, second) {
      expect(first + second - second, first);
    });

    Glados<Years>().test('asNormalTime agrees with asNormalDays', (years) {
      expect(years.asNormalTime, years.asNormalDays.asTime);
      expect(years.asNormalLeapTime, years.asLeapDays.asTime);
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
