import 'dart:math' as math;

import 'package:fixed/fixed.dart';
import 'package:glados/glados.dart';

import 'date/date.dart';
import 'date/duration.dart';
import 'date/month/month.dart';
import 'date/month/year_month.dart';
import 'date/ordinal_date.dart';
import 'date/week/week_date.dart';
import 'date/week/year_week.dart';
import 'date/weekday.dart';
import 'date/year.dart';
import 'date_time/date_time.dart';
import 'date_time/instant.dart';
import 'time/duration.dart';
import 'time/time.dart';

void setChronoGladosDefaults() {
  Any.setDefault(any.instant);
  Any.setDefault(any.date);
  Any.setDefault(any.dateTimeChrono);
  Any.setDefault(any.month);
  Any.setDefault(any.time);
  Any.setDefault(any.ordinalDate);
  Any.setDefault(any.weekDate);
  Any.setDefault(any.year);
  Any.setDefault(any.yearMonth);
  Any.setDefault(any.yearWeek);
  Any.setDefault(any.weekday);

  Any.setDefault(any.daysDuration);
  Any.setDefault(any.fixedDaysDuration);
  Any.setDefault(any.days);
  Any.setDefault(any.weeks);
  Any.setDefault(any.monthsDuration);
  Any.setDefault(any.months);
  Any.setDefault(any.years);
  // TODO: `Duration` and all `TimeDuration`s
}

extension ChronoAny on Any {
  Generator<Instant> get instant => dateTimeChrono.map((it) => it.inUtc);
  Generator<Date> get date {
    return simple(
      generate: (random, size) {
        final yearMonth = this.yearMonth(random, size);
        final day =
            intInRange(1, yearMonth.value.lengthInDays.value + 1)(random, size);
        return (yearMonth, day);
      },
      shrink: (input) sync* {
        final (yearMonth, day) = input;
        yield* yearMonth.shrink().map((yearMonth) {
          final actualDay = day.value <= yearMonth.value.lengthInDays.value
              ? day
              : day.shrink().firstWhere(
                    (it) => it.value <= yearMonth.value.lengthInDays.value,
                  );
          return (yearMonth, actualDay);
        });
        yield* day.shrink().map((it) => (yearMonth, it));
      },
    ).map(
      (it) => Date.fromYearMonthAndDayUnchecked(it.$1.value, it.$2.value),
    );
  }

  Generator<DateTime> get dateTimeChrono => combine2(date, time, DateTime.new);
  Generator<Month> get month => choose(Month.values);
  Generator<Time> get time {
    return combine4(
      intInRange(0, 24),
      intInRange(0, 60),
      intInRange(0, 60),
      _fraction,
      Time.fromUnchecked,
    );
  }

  Generator<OrdinalDate> get ordinalDate {
    return simple(
      generate: (random, size) {
        final year = this.year(random, size);
        final day =
            intInRange(1, year.value.lengthInDays.value + 1)(random, size);
        return (year, day);
      },
      shrink: (input) sync* {
        final (year, day) = input;
        yield* year.shrink().map((year) {
          final actualDay = day.value <= year.value.lengthInDays.value
              ? day
              : day.shrink().firstWhere(
                    (it) => it.value <= year.value.lengthInDays.value,
                  );
          return (year, actualDay);
        });
        yield* day.shrink().map((it) => (year, it));
      },
    ).map(
      (it) => OrdinalDate.fromUnchecked(it.$1.value, it.$2.value),
    );
  }

  Generator<WeekDate> get weekDate => combine2(yearWeek, weekday, WeekDate.new);
  Generator<Year> get year => this.int.map(Year.new);
  Generator<YearMonth> get yearMonth => combine2(year, month, YearMonth.new);
  Generator<YearWeek> get yearWeek {
    return simple(
      generate: (random, size) {
        final weekBasedYear = year(random, size);
        final week =
            intInRange(1, weekBasedYear.value.numberOfWeeks + 1)(random, size);
        return (weekBasedYear, week);
      },
      shrink: (input) sync* {
        final (weekBasedYear, week) = input;
        yield* weekBasedYear.shrink().map((weekBasedYear) {
          final actualWeek = week.value <= weekBasedYear.value.numberOfWeeks
              ? week
              : week.shrink().firstWhere(
                    (it) => it.value <= weekBasedYear.value.numberOfWeeks,
                  );
          return (weekBasedYear, actualWeek);
        });
        yield* week.shrink().map((it) => (weekBasedYear, it));
      },
    ).map((it) => YearWeek.fromUnchecked(it.$1.value, it.$2.value));
  }

  Generator<Weekday> get weekday => choose(Weekday.values);

  Generator<FractionalSeconds> get _fraction {
    return simple(
      generate: (random, size) {
        final scale = positiveInt(random, math.log(size).ceil()).value;
        final minorUnits = bigIntInRange(
          BigInt.zero,
          BigInt.from(10).pow(scale),
        )(random, size)
            .value;
        return FractionalSeconds(Fixed.fromBigInt(minorUnits, scale: scale));
      },
      shrink: (input) sync* {
        if (input.isPositive) {
          yield FractionalSeconds(Fixed.fromBigInt(
            input.value.minorUnits - BigInt.one,
            scale: input.value.scale,
          ));
        }
        if (input.value.scale > 1) {
          yield FractionalSeconds(Fixed.fromBigInt(
            input.value.minorUnits ~/ BigInt.from(10),
            scale: input.value.scale - 1,
          ));
        }
      },
    );
  }

  Generator<DaysDuration> get daysDuration =>
      either(fixedDaysDuration, monthsDuration);

  Generator<FixedDaysDuration> get fixedDaysDuration => either(days, weeks);
  Generator<Days> get days => this.int.map(Days.new);
  Generator<Weeks> get weeks => this.int.map(Weeks.new);

  Generator<MonthsDuration> get monthsDuration => either(months, years);
  Generator<Months> get months => this.int.map(Months.new);
  Generator<Years> get years => this.int.map(Years.new);
}
