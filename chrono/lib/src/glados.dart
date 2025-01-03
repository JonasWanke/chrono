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
import 'time/duration.dart';
import 'time/time.dart';
import 'unix_epoch_timestamp.dart';

/// Sets all Glados generators for Chrono classes as defaults.
///
/// See also:
///
/// - [ChronoAny], which defines all these generators.
void setChronoGladosDefaults() {
  Any.setDefault(any.unixEpochTimestamp);
  Any.setDefault(any.instant);
  Any.setDefault(any.unixEpochMicroseconds);
  Any.setDefault(any.unixEpochMilliseconds);
  Any.setDefault(any.unixEpochSeconds);

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
  Any.setDefault(any.timeDuration);
  Any.setDefault(any.nanosecondsDuration);
  Any.setDefault(any.nanoseconds);
  Any.setDefault(any.microsecondsDuration);
  Any.setDefault(any.microseconds);
  Any.setDefault(any.millisecondsDuration);
  Any.setDefault(any.milliseconds);
  Any.setDefault(any.secondsDuration);
  Any.setDefault(any.seconds);
  Any.setDefault(any.minutesDuration);
  Any.setDefault(any.minutes);
  Any.setDefault(any.hours);
}

/// Glados generators for Chrono classes.
///
/// See also:
///
/// - [setChronoGladosDefaults], which registers all these generators as
///   default.
extension ChronoAny on Any {
  Generator<UnixEpochTimestamp> get unixEpochTimestamp {
    return either(
      timeDuration.map(UnixEpochTimestamp.new),
      instant,
      unixEpochMicroseconds,
      unixEpochMilliseconds,
      unixEpochSeconds,
    );
  }

  Generator<Instant> get instant =>
      nanoseconds.map(Instant.fromDurationSinceUnixEpoch);
  Generator<UnixEpochMicroseconds> get unixEpochMicroseconds =>
      microseconds.map(UnixEpochMicroseconds.new);
  Generator<UnixEpochMilliseconds> get unixEpochMilliseconds =>
      milliseconds.map(UnixEpochMilliseconds.new);
  Generator<UnixEpochSeconds> get unixEpochSeconds =>
      seconds.map(UnixEpochSeconds.new);
  Generator<Date> get date {
    return simple(
      generate: (random, size) {
        final yearMonth = this.yearMonth(random, size);
        final day =
            intInRange(1, yearMonth.value.length.inDays + 1)(random, size);
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
    ).map(
      (it) => Date.fromYearMonthAndDay(it.$1.value, it.$2.value).unwrap(),
    );
  }

  Generator<CDateTime> get dateTimeChrono =>
      combine2(date, time, CDateTime.new);
  Generator<Month> get month => choose(Month.values);
  Generator<Time> get time {
    return combine4(
      intInRange(0, 24),
      intInRange(0, 60),
      intInRange(0, 60),
      intInRange(0, Nanoseconds.perSecond),
      (hour, minute, second, nanoseconds) =>
          Time.from(hour, minute, second, Nanoseconds(nanoseconds)).unwrap(),
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
    ).map((it) => IsoYearWeek.from(it.$1.value, it.$2.value).unwrap());
  }

  Generator<WeekConfig> get weekConfig {
    return combine2(
      weekday,
      intInRange(1, Days.perWeek),
      (firstDay, minDaysInFirstWeek) => WeekConfig.from(
        firstDay: firstDay,
        minDaysInFirstWeek: minDaysInFirstWeek,
      ).unwrap(),
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
    ).map(
      (it) => YearWeek.from(it.$2.value, it.$3.value, it.$1.value).unwrap(),
    );
  }

  Generator<MonthDay> get monthDay {
    return simple(
      generate: (random, size) {
        final month = this.month(random, size);
        final day =
            intInRange(1, month.value.maxLength.inDays + 1)(random, size);
        return (month, day);
      },
      shrink: (input) sync* {
        final (month, day) = input;
        yield* month.shrink().map((month) {
          final actualWeek = day.value <= month.value.maxLength.inDays
              ? day
              : day
                  .shrink()
                  .firstWhere((it) => it.value <= month.value.maxLength.inDays);
          return (month, actualWeek);
        });
        yield* day.shrink().map((it) => (month, it));
      },
    ).map((it) => MonthDay.from(it.$1.value, it.$2.value).unwrap());
  }

  Generator<Weekday> get weekday => choose(Weekday.values);

  Generator<CDuration> get durationChrono =>
      either(calendarDuration, timeDuration);
  Generator<CompoundDuration> get compoundDuration {
    return combine2(
      compoundCalendarDuration,
      nanoseconds,
      (monthsAndDays, nanoseconds) => CompoundDuration(
        monthsAndDays: monthsAndDays,
        seconds: nanoseconds,
      ),
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

  Generator<TimeDuration> get timeDuration => nanosecondsDuration;
  Generator<NanosecondsDuration> get nanosecondsDuration =>
      either(nanoseconds, microseconds, milliseconds, seconds, minutes, hours);
  Generator<Nanoseconds> get nanoseconds => bigInt.map(Nanoseconds.fromBigInt);
  Generator<MicrosecondsDuration> get microsecondsDuration =>
      either(microseconds, milliseconds, seconds, minutes, hours);
  Generator<Microseconds> get microseconds => this.int.map(Microseconds.new);
  Generator<MillisecondsDuration> get millisecondsDuration =>
      either(milliseconds, seconds, minutes, hours);
  Generator<Milliseconds> get milliseconds => this.int.map(Milliseconds.new);
  Generator<SecondsDuration> get secondsDuration =>
      either(seconds, minutes, hours);
  Generator<Seconds> get seconds => this.int.map(Seconds.new);
  Generator<MinutesDuration> get minutesDuration => either(minutes, hours);
  Generator<Minutes> get minutes => this.int.map(Minutes.new);
  Generator<Hours> get hours => this.int.map(Hours.new);
}
