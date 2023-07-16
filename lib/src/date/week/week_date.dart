import 'dart:core';
import 'dart:core' as core;

import 'package:clock/clock.dart';
import 'package:meta/meta.dart';
import 'package:oxidized/oxidized.dart';

import '../../parser.dart';
import '../../utils.dart';
import '../date.dart';
import '../duration.dart';
import '../month/month.dart';
import '../ordinal_date.dart';
import '../weekday.dart';
import '../year.dart';
import 'year_week.dart';

@immutable
final class WeekDate
    with ComparisonOperatorsFromComparable<WeekDate>
    implements Comparable<WeekDate> {
  const WeekDate(this.yearWeek, this.weekday);

  WeekDate.fromDate(Date date) : this(date.yearWeek, date.weekday);

  WeekDate.fromCore(core.DateTime dateTime)
      : this.fromDate(Date.fromCore(dateTime));
  WeekDate.todayInLocalZone({Clock? clockOverride})
      : this.fromCore((clockOverride ?? clock).now().toLocal());
  WeekDate.todayInUtc({Clock? clockOverride})
      : this.fromCore((clockOverride ?? clock).now().toUtc());

  factory WeekDate.fromJson(String json) => unwrapParserResult(parse(json));
  static Result<WeekDate, FormatException> parse(String value) =>
      Parser.parseWeekDate(value);

  final YearWeek yearWeek;
  final Weekday weekday;

  OrdinalDate get asOrdinalDate {
    // https://en.wikipedia.org/wiki/ISO_week_date#Calculating_an_ordinal_or_month_date_from_a_week_date
    final january4 =
        Date.fromUnchecked(yearWeek.weekBasedYear, Month.january, 4);

    final rawDayOfYear = Days.perWeek * yearWeek.week +
        weekday.number -
        (january4.weekday.number + 3);
    final Year year;
    final int dayOfYear;
    if (rawDayOfYear < 1) {
      year = yearWeek.weekBasedYear - const Years(1);
      dayOfYear = rawDayOfYear + year.lengthInDays.value;
    } else {
      final daysInCurrentYear = yearWeek.weekBasedYear.lengthInDays.value;
      if (rawDayOfYear > daysInCurrentYear) {
        year = yearWeek.weekBasedYear + const Years(1);
        dayOfYear = rawDayOfYear - daysInCurrentYear;
      } else {
        year = yearWeek.weekBasedYear;
        dayOfYear = rawDayOfYear;
      }
    }
    return OrdinalDate.fromUnchecked(year, dayOfYear);
  }

  Date get asDate => asOrdinalDate.asDate;

  bool isTodayInLocalZone({Clock? clockOverride}) =>
      this == WeekDate.todayInLocalZone(clockOverride: clockOverride);
  bool isTodayInUtc({Clock? clockOverride}) =>
      this == WeekDate.todayInUtc(clockOverride: clockOverride);

  WeekDate operator +(FixedDaysDuration duration) =>
      (asDate + duration).asWeekDate;
  WeekDate operator -(FixedDaysDuration duration) => this + (-duration);

  WeekDate get nextDate {
    return weekday == Weekday.values.last
        ? WeekDate(yearWeek + const Weeks(1), Weekday.values.first)
        : WeekDate(yearWeek, weekday.next);
  }

  WeekDate get previousDate {
    return weekday == Weekday.values.first
        ? WeekDate(yearWeek - const Weeks(1), Weekday.values.last)
        : WeekDate(yearWeek, weekday.previous);
  }

  WeekDate nextOrSame(Weekday weekday) {
    // ignore: avoid_returning_this
    if (weekday == this.weekday) return this;

    return WeekDate(
      weekday < this.weekday ? yearWeek.nextWeek : yearWeek,
      weekday,
    );
  }

  WeekDate previousOrSame(Weekday weekday) {
    // ignore: avoid_returning_this
    if (weekday == this.weekday) return this;

    return WeekDate(
      weekday > this.weekday ? yearWeek.previousWeek : yearWeek,
      weekday,
    );
  }

  WeekDate copyWith({YearWeek? yearWeek, Weekday? weekday}) =>
      WeekDate(yearWeek ?? this.yearWeek, weekday ?? this.weekday);

  @override
  int compareTo(WeekDate other) {
    final result = yearWeek.compareTo(other.yearWeek);
    if (result != 0) return result;

    return weekday.compareTo(other.weekday);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is WeekDate &&
            yearWeek == other.yearWeek &&
            weekday == other.weekday);
  }

  @override
  int get hashCode => Object.hash(yearWeek, weekday);

  @override
  String toString() => '$yearWeek-${weekday.number}';

  String toJson() => toString();
}
