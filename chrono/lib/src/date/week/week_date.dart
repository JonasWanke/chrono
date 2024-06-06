import 'dart:core' as core;
import 'dart:core';

import 'package:clock/clock.dart';
import 'package:meta/meta.dart';
import 'package:oxidized/oxidized.dart';

import '../../json.dart';
import '../../parser.dart';
import '../../utils.dart';
import '../date.dart';
import '../duration.dart';
import '../month/month.dart';
import '../month/year_month.dart';
import '../ordinal_date.dart';
import '../weekday.dart';
import '../year.dart';
import 'year_week.dart';

/// A date in the ISO 8601 week-based calendar, e.g., Sunday in the 16th week of
/// 2023.
///
/// https://en.wikipedia.org/wiki/ISO_week_date
///
///
/// See also:
///
/// - [Date], which represents a date by a [YearMonth] (= [Year] + [Month]) and
///   a day of the month.
/// - [OrdinalDate], which represents a date by a [Year] and a day of the year.
@immutable
final class WeekDate
    with ComparisonOperatorsFromComparable<WeekDate>
    implements Comparable<WeekDate> {
  const WeekDate(this.yearWeek, this.weekday);

  factory WeekDate.todayInLocalZone({Clock? clock}) =>
      Date.todayInLocalZone(clock: clock).asWeekDate;
  factory WeekDate.todayInUtc({Clock? clock}) =>
      Date.todayInUtc(clock: clock).asWeekDate;

  final YearWeek yearWeek;
  final Weekday weekday;

  /// This date, represented as a [Date].
  Date get asDate => asOrdinalDate.asDate;

  /// This date, represented as an [OrdinalDate].
  OrdinalDate get asOrdinalDate {
    // https://en.wikipedia.org/wiki/ISO_week_date#Calculating_an_ordinal_or_month_date_from_a_week_date
    final january4 =
        Date.from(yearWeek.weekBasedYear, Month.january, 4).unwrap();

    final rawDayOfYear = Days.perWeek * yearWeek.week +
        weekday.number -
        (january4.weekday.number + 3);
    final Year year;
    final int dayOfYear;
    if (rawDayOfYear < 1) {
      year = yearWeek.weekBasedYear - const Years(1);
      dayOfYear = rawDayOfYear + year.length.inDays;
    } else {
      final daysInCurrentYear = yearWeek.weekBasedYear.length.inDays;
      if (rawDayOfYear > daysInCurrentYear) {
        year = yearWeek.weekBasedYear + const Years(1);
        dayOfYear = rawDayOfYear - daysInCurrentYear;
      } else {
        year = yearWeek.weekBasedYear;
        dayOfYear = rawDayOfYear;
      }
    }
    return OrdinalDate.from(year, dayOfYear).unwrap();
  }

  bool isTodayInLocalZone({Clock? clock}) =>
      this == WeekDate.todayInLocalZone(clock: clock);
  bool isTodayInUtc({Clock? clock}) =>
      this == WeekDate.todayInUtc(clock: clock);

  WeekDate operator +(DaysDuration duration) => (asDate + duration).asWeekDate;
  WeekDate operator -(DaysDuration duration) => this + (-duration);

  /// The date after this one.
  WeekDate get next {
    return weekday == Weekday.values.last
        ? WeekDate(yearWeek + const Weeks(1), Weekday.values.first)
        : WeekDate(yearWeek, weekday.next);
  }

  /// The date before this one.
  WeekDate get previous {
    return weekday == Weekday.values.first
        ? WeekDate(yearWeek - const Weeks(1), Weekday.values.last)
        : WeekDate(yearWeek, weekday.previous);
  }

  /// The next-closest date with the given [weekday].
  ///
  /// If this date already falls on the given [weekday], it is returned.
  WeekDate nextOrSame(Weekday weekday) =>
      this + this.weekday.untilNextOrSame(weekday);

  /// The next-closest previous date with the given [weekday].
  ///
  /// If this date already falls on the given [weekday], it is returned.
  WeekDate previousOrSame(Weekday weekday) =>
      this + this.weekday.untilPreviousOrSame(weekday);

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
}

/// Encodes a [WeekDate] as an ISO 8601 string, e.g., “2023-W16-7”.
class WeekDateAsIsoStringJsonConverter
    extends JsonConverterWithParserResult<WeekDate, String> {
  const WeekDateAsIsoStringJsonConverter();

  @override
  Result<WeekDate, FormatException> resultFromJson(String json) =>
      Parser.parseWeekDate(json);
  @override
  String toJson(WeekDate object) => object.toString();
}
