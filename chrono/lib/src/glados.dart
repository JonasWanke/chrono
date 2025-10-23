import 'package:glados/glados.dart';

import 'date/date.dart';
import 'date/duration.dart';
import 'date/month/month.dart';
import 'date/month/month_day.dart';
import 'date/month/year_month.dart';
import 'date/week/iso_year_week.dart';
import 'date/week/week_config.dart';
import 'date/week/year_week.dart';
import 'date/weekday.dart';
import 'date/year.dart';
import 'date_time/date_time.dart';
import 'date_time/duration.dart';
import 'instant.dart';
import 'time/duration.dart';
import 'time/time.dart';

/// Sets all Glados generators for Chrono classes as defaults.
///
/// See also:
///
/// - [ChronoAny], which defines all these generators.
void setChronoGladosDefaults() {
  Any.setDefault(any.instant);

  Any.setDefault(any.date);
  Any.setDefault(any.dateTimeChrono);
  Any.setDefault(any.month);
  Any.setDefault(any.time);
  Any.setDefault(any.year);
  Any.setDefault(any.yearMonth);
  Any.setDefault(any.isoYearWeek);
  Any.setDefault(any.yearWeek);
  Any.setDefault(any.weekConfig);
  Any.setDefault(any.monthDay);
  Any.setDefault(any.weekday);

  Any.setDefault(any.durationChrono);
  Any.setDefault(any.compoundDuration);
  Any.setDefault(any.calendarDuration);
  Any.setDefault(any.compoundCalendarDuration);
  Any.setDefault(any.monthsDuration);
  Any.setDefault(any.months);
  Any.setDefault(any.years);
  Any.setDefault(any.daysDuration);
  Any.setDefault(any.days);
  Any.setDefault(any.weeks);
  Any.setDefault(any.timeDelta);
}

/// Glados generators for Chrono classes.
///
/// See also:
///
/// - [setChronoGladosDefaults], which registers all these generators as
///   default.
extension ChronoAny on Any {
  Generator<Instant> get instant =>
      timeDelta.map(Instant.fromDurationSinceUnixEpoch);
  Generator<Date> get date {
    return simple(
      generate: (random, size) {
        final yearMonth = this.yearMonth(random, size);
        final day = intInRange(1, yearMonth.value.length.inDays + 1)(
          random,
          size,
        );
        return (yearMonth, day);
      },
      shrink: (input) sync* {
        final (yearMonth, day) = input;
        yield* yearMonth.shrink().map((yearMonth) {
          final actualDay = day.value <= yearMonth.value.length.inDays
              ? day
              : day.shrink().firstWhere(
                  (it) => it.value <= yearMonth.value.length.inDays,
                );
          return (yearMonth, actualDay);
        });
        yield* day.shrink().map((it) => (yearMonth, it));
      },
    ).map((it) => Date.fromYearMonthAndDay(it.$1.value, it.$2.value));
  }

  Generator<CDateTime> get dateTimeChrono =>
      combine2(date, time, CDateTime.new);
  Generator<Month> get month => choose(Month.values);
  Generator<Time> get time {
    return combine6(
      intInRange(0, TimeDelta.hoursPerNormalDay),
      intInRange(0, TimeDelta.minutesPerHour),
      intInRange(0, TimeDelta.secondsPerMinute),
      intInRange(0, TimeDelta.millisPerSecond),
      intInRange(0, TimeDelta.microsPerMillisecond),
      intInRange(0, TimeDelta.nanosPerMicrosecond),
      (hour, minute, second, millis, micros, nanos) =>
          Time.from(hour, minute, second, millis, micros, nanos),
    );
  }

  Generator<Year> get year => this.int.map(Year.new);
  Generator<YearMonth> get yearMonth => combine2(year, month, YearMonth.new);
  Generator<IsoYearWeek> get isoYearWeek {
    return simple(
      generate: (random, size) {
        final weekBasedYear = year(random, size);
        final week = intInRange(1, weekBasedYear.value.numberOfIsoWeeks + 1)(
          random,
          size,
        );
        return (weekBasedYear, week);
      },
      shrink: (input) sync* {
        final (weekBasedYear, week) = input;
        yield* weekBasedYear.shrink().map((weekBasedYear) {
          final actualWeek = week.value <= weekBasedYear.value.numberOfIsoWeeks
              ? week
              : week.shrink().firstWhere(
                  (it) => it.value <= weekBasedYear.value.numberOfIsoWeeks,
                );
          return (weekBasedYear, actualWeek);
        });
        yield* week.shrink().map((it) => (weekBasedYear, it));
      },
    ).map((it) => IsoYearWeek.from(it.$1.value, it.$2.value));
  }

  Generator<WeekConfig> get weekConfig {
    return combine2(
      weekday,
      intInRange(1, Days.perWeek),
      (firstDay, minDaysInFirstWeek) => WeekConfig.from(
        firstDay: firstDay,
        minDaysInFirstWeek: minDaysInFirstWeek,
      ),
    );
  }

  Generator<YearWeek> get yearWeek {
    return simple(
      generate: (random, size) {
        final config = weekConfig(random, size);
        final weekBasedYear = year(random, size);
        final week = intInRange(
          1,
          weekBasedYear.value.numberOfWeeks(config.value) + 1,
        )(random, size);
        return (config, weekBasedYear, week);
      },
      shrink: (input) sync* {
        final (config, weekBasedYear, week) = input;
        yield* config.shrink().map((config) {
          final numberOfWeeks = weekBasedYear.value.numberOfWeeks(config.value);
          final actualWeek = week.value <= numberOfWeeks
              ? week
              : week.shrink().firstWhere((it) => it.value <= numberOfWeeks);
          return (config, weekBasedYear, actualWeek);
        });
        yield* weekBasedYear.shrink().map((weekBasedYear) {
          final numberOfWeeks = weekBasedYear.value.numberOfWeeks(config.value);
          final actualWeek = week.value <= numberOfWeeks
              ? week
              : week.shrink().firstWhere((it) => it.value <= numberOfWeeks);
          return (config, weekBasedYear, actualWeek);
        });
        yield* week.shrink().map((it) => (config, weekBasedYear, it));
      },
    ).map((it) => YearWeek.from(it.$2.value, it.$3.value, it.$1.value));
  }

  Generator<MonthDay> get monthDay {
    return simple(
      generate: (random, size) {
        final month = this.month(random, size);
        final day = intInRange(1, month.value.maxLength.inDays + 1)(
          random,
          size,
        );
        return (month, day);
      },
      shrink: (input) sync* {
        final (month, day) = input;
        yield* month.shrink().map((month) {
          final actualWeek = day.value <= month.value.maxLength.inDays
              ? day
              : day.shrink().firstWhere(
                  (it) => it.value <= month.value.maxLength.inDays,
                );
          return (month, actualWeek);
        });
        yield* day.shrink().map((it) => (month, it));
      },
    ).map((it) => MonthDay.from(it.$1.value, it.$2.value));
  }

  Generator<Weekday> get weekday => choose(Weekday.values);

  Generator<CDuration> get durationChrono =>
      either(calendarDuration, timeDelta);
  Generator<CompoundDuration> get compoundDuration {
    return combine2(
      compoundCalendarDuration,
      timeDelta,
      (monthsAndDays, time) =>
          CompoundDuration(monthsAndDays: monthsAndDays, time: time),
    );
  }

  Generator<CalendarDuration> get calendarDuration =>
      either(compoundCalendarDuration, monthsDuration, daysDuration);
  Generator<CompoundCalendarDuration> get compoundCalendarDuration {
    return combine2(
      months,
      days,
      (months, days) => CompoundCalendarDuration(months: months, days: days),
    );
  }

  Generator<MonthsDuration> get monthsDuration => either(months, years);
  Generator<Months> get months => this.int.map(Months.new);
  Generator<Years> get years => this.int.map(Years.new);

  Generator<DaysDuration> get daysDuration => either(days, weeks);
  Generator<Days> get days => this.int.map(Days.new);
  Generator<Weeks> get weeks => this.int.map(Weeks.new);

  Generator<TimeDelta> get timeDelta {
    return combine10(
      this.int,
      this.int,
      this.int,
      this.int,
      this.int,
      this.int,
      this.int,
      this.int,
      this.int,
      this.int,
      (
        normalLeapYears,
        normalYears,
        normalWeeks,
        normalDays,
        hours,
        minutes,
        seconds,
        millis,
        micros,
        nanos,
      ) => TimeDelta(
        normalLeapYears: normalLeapYears,
        normalYears: normalYears,
        normalWeeks: normalWeeks,
        normalDays: normalDays,
        hours: hours,
        minutes: minutes,
        seconds: seconds,
        millis: millis,
        micros: micros,
        nanos: nanos,
      ),
    );
  }
}
