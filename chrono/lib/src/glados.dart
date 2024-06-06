import 'dart:math' as math;

import 'package:fixed/fixed.dart';
import 'package:glados/glados.dart';

import 'date/date.dart';
import 'date/duration.dart';
import 'date/month/month.dart';
import 'date/month/month_day.dart';
import 'date/month/year_month.dart';
import 'date/ordinal_date.dart';
import 'date/week/week_date.dart';
import 'date/week/year_week.dart';
import 'date/weekday.dart';
import 'date/year.dart';
import 'date_time/date_time.dart';
import 'date_time/duration.dart';
import 'time/duration.dart';
import 'time/time.dart';
import 'unix_epoch_timestamp.dart';

void setChronoGladosDefaults() {
  Any.setDefault(any.unixEpochTimestamp);
  Any.setDefault(any.instant);
  Any.setDefault(any.unixEpochNanoseconds);
  Any.setDefault(any.unixEpochMicroseconds);
  Any.setDefault(any.unixEpochMilliseconds);
  Any.setDefault(any.unixEpochSeconds);

  Any.setDefault(any.date);
  Any.setDefault(any.dateTimeChrono);
  Any.setDefault(any.month);
  Any.setDefault(any.time);
  Any.setDefault(any.ordinalDate);
  Any.setDefault(any.weekDate);
  Any.setDefault(any.year);
  Any.setDefault(any.yearMonth);
  Any.setDefault(any.yearWeek);
  Any.setDefault(any.monthDay);
  Any.setDefault(any.weekday);

  Any.setDefault(any.durationChrono);
  Any.setDefault(any.compoundDuration);
  Any.setDefault(any.daysDuration);
  Any.setDefault(any.compoundDaysDuration);
  Any.setDefault(any.monthsDuration);
  Any.setDefault(any.months);
  Any.setDefault(any.years);
  Any.setDefault(any.fixedDaysDuration);
  Any.setDefault(any.days);
  Any.setDefault(any.weeks);
  Any.setDefault(any.timeDuration);
  Any.setDefault(any.fractionalSeconds);
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

extension ChronoAny on Any {
  Generator<UnixEpochTimestamp> get unixEpochTimestamp {
    return either(
      timeDuration.map(UnixEpochTimestamp.new),
      instant,
      unixEpochNanoseconds,
      unixEpochMicroseconds,
      unixEpochMilliseconds,
      unixEpochSeconds,
    );
  }

  Generator<Instant> get instant =>
      fractionalSeconds.map(Instant.fromDurationSinceUnixEpoch);
  Generator<UnixEpochNanoseconds> get unixEpochNanoseconds =>
      nanoseconds.map(UnixEpochNanoseconds.new);
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

  Generator<DateTime> get dateTimeChrono => combine2(date, time, DateTime.new);
  Generator<Month> get month => choose(Month.values);
  Generator<Time> get time {
    return combine4(
      intInRange(0, 24),
      intInRange(0, 60),
      intInRange(0, 60),
      fractionalSeconds,
      (hour, minute, second, fractionalSeconds) =>
          Time.from(hour, minute, second, fractionalSeconds).unwrap(),
    );
  }

  Generator<OrdinalDate> get ordinalDate {
    return simple(
      generate: (random, size) {
        final year = this.year(random, size);
        final day = intInRange(1, year.value.length.inDays + 1)(random, size);
        return (year, day);
      },
      shrink: (input) sync* {
        final (year, day) = input;
        yield* year.shrink().map((year) {
          final actualDay = day.value <= year.value.length.inDays
              ? day
              : day.shrink().firstWhere(
                    (it) => it.value <= year.value.length.inDays,
                  );
          return (year, actualDay);
        });
        yield* day.shrink().map((it) => (year, it));
      },
    ).map(
      (it) => OrdinalDate.from(it.$1.value, it.$2.value).unwrap(),
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
    ).map((it) => YearWeek.from(it.$1.value, it.$2.value).unwrap());
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

  Generator<Duration> get durationChrono => either(daysDuration, timeDuration);
  Generator<CompoundDuration> get compoundDuration {
    return combine2(
      compoundDaysDuration,
      fractionalSeconds,
      (monthsAndDays, fractionalSeconds) => CompoundDuration(
        monthsAndDays: monthsAndDays,
        seconds: fractionalSeconds,
      ),
    );
  }

  Generator<DaysDuration> get daysDuration =>
      either(compoundDaysDuration, monthsDuration, fixedDaysDuration);
  Generator<CompoundDaysDuration> get compoundDaysDuration {
    return combine2(
      months,
      days,
      (months, days) => CompoundDaysDuration(months: months, days: days),
    );
  }

  Generator<MonthsDuration> get monthsDuration => either(months, years);
  Generator<Months> get months => this.int.map(Months.new);
  Generator<Years> get years => this.int.map(Years.new);

  Generator<FixedDaysDuration> get fixedDaysDuration => either(days, weeks);
  Generator<Days> get days => this.int.map(Days.new);
  Generator<Weeks> get weeks => this.int.map(Weeks.new);

  Generator<TimeDuration> get timeDuration =>
      either(fractionalSeconds, nanosecondsDuration);
  Generator<FractionalSeconds> get fractionalSeconds {
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
          yield FractionalSeconds(
            Fixed.fromBigInt(
              input.inFractionalSeconds.minorUnits - BigInt.one,
              scale: input.inFractionalSeconds.scale,
            ),
          );
        }
        if (input.inFractionalSeconds.scale > 1) {
          yield FractionalSeconds(
            Fixed.fromBigInt(
              input.inFractionalSeconds.minorUnits ~/ BigInt.from(10),
              scale: input.inFractionalSeconds.scale - 1,
            ),
          );
        }
      },
    );
  }

  Generator<NanosecondsDuration> get nanosecondsDuration =>
      either(nanoseconds, microseconds, milliseconds, seconds, minutes, hours);
  Generator<Nanoseconds> get nanoseconds => this.int.map(Nanoseconds.new);
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
