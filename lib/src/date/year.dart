import 'dart:core';
import 'dart:core' as core;

import 'package:clock/clock.dart';
import 'package:meta/meta.dart';

import '../date_time/date_time.dart';
import '../utils.dart';
import 'date.dart';
import 'duration.dart';
import 'month/month.dart';
import 'month/year_month.dart';
import 'ordinal_date.dart';
import 'week/year_week.dart';
import 'weekday.dart';

/// A year in the ISO 8601 calendar.
///
/// The [number] corresponds to these years, according to ISO 8601:
///
/// | Value |   Meaning   |
/// |-------|-------------|
/// |  2023 | 2023  CE/AD |
/// |     … |      …      |
/// |     1 |    1  CE/AD |
/// |     0 |    1 BCE/BC |
/// |    -1 |    2 BCE/BC |
/// |     … |      …      |
///
/// There is no limitation on the range of years.
@immutable
final class Year
    with ComparisonOperatorsFromComparable<Year>
    implements Comparable<Year> {
  const Year(this.number);

  factory Year.currentInLocalZone({Clock? clock}) =>
      DateTime.nowInLocalZone(clock: clock).date.year;
  factory Year.currentInUtc({Clock? clock}) =>
      DateTime.nowInUtc(clock: clock).date.year;

  const Year.fromJson(int json) : this(json);

  final int number;

  bool isCurrentInLocalZone({Clock? clock}) =>
      this == Year.currentInLocalZone(clock: clock);
  bool isCurrentInUtc({Clock? clock}) =>
      this == Year.currentInUtc(clock: clock);

  /// Whether this year is a common (non-leap) year.
  bool get isCommonYear => !isLeapYear;

  /// Whether this year is a leap year.
  bool get isLeapYear {
    // https://howardhinnant.github.io/date_algorithms.html#is_leap
    return number % 4 == 0 && (number % 100 != 0 || number % 400 == 0);
  }

  Days get length => isLeapYear ? const Days(366) : const Days(365);
  int get numberOfWeeks {
    // https://en.wikipedia.org/wiki/ISO_week_date#Weeks_per_year
    Weekday weekdayOfDecember31(Year year) =>
        Date.fromUnchecked(year, Month.december, 31).weekday;

    final isLongWeek = weekdayOfDecember31(this) == Weekday.thursday ||
        weekdayOfDecember31(previous) == Weekday.wednesday;
    return isLongWeek ? 53 : 52;
  }

  /// The first month of this year.
  YearMonth get firstMonth => YearMonth(this, Month.january);

  /// The last month of this year.
  YearMonth get lastMonth => YearMonth(this, Month.december);

  /// An iterable of all months in this year.
  Iterable<YearMonth> get months =>
      Month.values.map((month) => YearMonth(this, month));

  /// The first week of this year.
  YearWeek get firstWeek => YearWeek.fromUnchecked(this, 1);

  /// The last week of this year.
  YearWeek get lastWeek => YearWeek.fromUnchecked(this, numberOfWeeks);

  /// An iterable of all weeks in this year.
  Iterable<YearWeek> get weeks {
    return Iterable.generate(
      numberOfWeeks,
      (it) => YearWeek.fromUnchecked(this, it + 1),
    );
  }

  /// The first day of this year.
  Date get firstDay => firstMonth.firstDay;

  /// The last day of this year.
  Date get lastDay => lastMonth.lastDay;

  /// The first day of this year as an [OrdinalDate].
  OrdinalDate get firstOrdinalDate => OrdinalDate.fromUnchecked(this, 1);

  /// The last day of this year as an [OrdinalDate].
  OrdinalDate get lastOrdinalDate =>
      OrdinalDate.fromUnchecked(this, length.inDays);

  /// An iterable of all days in this year.
  Iterable<Date> get days => months.expand((it) => it.days);

  Year operator +(Years duration) => Year(number + duration.inYears);
  Year operator -(Years duration) => Year(number - duration.inYears);

  /// The year after this one.
  Year get next => this + const Years(1);

  /// The year before this one.
  Year get previous => this - const Years(1);

  @override
  int compareTo(Year other) => number.compareTo(other.number);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Year && number == other.number);
  @override
  int get hashCode => number.hashCode;

  @override
  String toString() {
    return switch (number) {
      < 0 => '-${number.abs().toString().padLeft(4, '0')}',
      >= 10000 => '+$number',
      _ => number.toString().padLeft(4, '0'),
    };
  }

  int toJson() => number;
}
