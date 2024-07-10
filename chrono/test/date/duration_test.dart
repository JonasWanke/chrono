import 'package:chrono/chrono.dart';
import 'package:glados/glados.dart';
import 'package:meta/meta.dart';

import '../utils.dart';

void main() {
  setChronoGladosDefaults();

  group('CompoundDaysDuration', () {
    _testDurationBasics<CompoundDaysDuration>();
    Glados2<CompoundDaysDuration, DaysDuration>().test(
      '+ and -',
      (first, second) => expect(first + second - second, first),
    );
  });

  group('MonthsDuration', () {
    Glados<MonthsDuration>().test('absolute', (duration) {
      expect(duration.absolute.isNonNegative, true);
    });
    group('asYearsAndMonths', () {
      Glados<MonthsDuration>().test('glados', (duration) {
        final (years, months) = duration.asYearsAndMonths;
        expect(
          years.isNonNegative && months.isNonNegative ||
              years.isNonPositive && months.isNonPositive,
          true,
        );
        expect(months + years, duration);
      });
      test('edge cases', () {
        expect(const Months(13).asYearsAndMonths, const (Years(1), Months(1)));
        // ignore: use_named_constants
        expect(const Months(12).asYearsAndMonths, const (Years(1), Months(0)));
        expect(const Months(11).asYearsAndMonths, const (Years(0), Months(11)));
        expect(const Months(1).asYearsAndMonths, const (Years(0), Months(1)));
        expect(const Months(0).asYearsAndMonths, const (Years(0), Months(0)));
        expect(const Months(-1).asYearsAndMonths, const (Years(0), Months(-1)));
        expect(
          const Months(-11).asYearsAndMonths,
          const (Years(0), Months(-11)),
        );
        expect(
          const Months(-12).asYearsAndMonths,
          const (Years(-1), Months(0)),
        );
        expect(
          const Months(-13).asYearsAndMonths,
          const (Years(-1), Months(-1)),
        );
      });
    });
  });
  group('Months', () {
    _testDurationBasics<Months>();
    Glados2<Months, MonthsDuration>().test('+ and -', (first, second) {
      expect(first + second - second, first);
    });
  });
  group('Years', () {
    _testDurationBasics<Years>();
    Glados2<Years, Years>().test('+ and -', (first, second) {
      expect(first + second - second, first);
    });
  });

  group('FixedDaysDuration', () {
    Glados<FixedDaysDuration>().test('absolute', (duration) {
      expect(duration.absolute.isNonNegative, true);
    });
    Glados<FixedDaysDuration>().test('asWeeksAndDays', (duration) {
      final (weeks, days) = duration.asWeeksAndDays;
      expect(
        weeks.isNonNegative && days.isNonNegative ||
            weeks.isNonPositive && days.isNonPositive,
        true,
      );
      expect(days + weeks, duration);
    });
  });
  group('Days', () {
    _testDurationBasics<Days>();
    Glados2<Days, FixedDaysDuration>().test('+ and -', (first, second) {
      expect(first + second - second, first);
    });
  });
  group('Weeks', () {
    _testDurationBasics<Weeks>();
    Glados2<Weeks, Weeks>().test('+ and -', (first, second) {
      expect(first + second - second, first);
    });
  });
}

@isTest
void _testDurationBasics<T extends DaysDuration>() {
  Glados<T>().test('unary -', (duration) => expect(-(-duration), duration));

  Glados<T>().test('multiply with zero', (duration) {
    expect((duration * 0).isZero, true);
  });
  Glados2<T, int>(null, any.intExcept0).test(
    '*, ~/, %, and remainder(…)',
    (duration, factor) {
      expect(duration * factor ~/ factor, duration);
      expect((duration * factor % factor).isZero, true);
      expect((duration * factor).remainder(factor).isZero, true);
    },
  );
}
