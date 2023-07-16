import 'dart:core';
import 'dart:core' as core;

import 'package:clock/clock.dart';
import 'package:meta/meta.dart';

import '../utils.dart';
import 'date.dart';
import 'duration.dart';
import 'month/month.dart';
import 'month/year_month.dart';
import 'week/year_week.dart';
import 'weekday.dart';

/// | Value |   Meaning   |
/// |-------|-------------|
/// |  2023 | 2023  CE/AD |
/// |     … |      …      |
/// |     1 |    1  CE/AD |
/// |     0 |    1 BCE/BC |
/// |    -1 |    2 BCE/BC |
/// |     … |      …      |
@immutable
final class Year
    with ComparisonOperatorsFromComparable<Year>
    implements Comparable<Year> {
  const Year(this.number);

  Year.fromCore(core.DateTime dateTime) : number = dateTime.year;
  Year.currentInLocalZone({Clock? clockOverride})
      : this.fromCore((clockOverride ?? clock).now().toLocal());
  Year.currentInUtc({Clock? clockOverride})
      : this.fromCore((clockOverride ?? clock).now().toUtc());

  const Year.fromJson(int json) : this(json);

  final int number;

  bool isCurrentInLocalZone({Clock? clockOverride}) =>
      this == Year.currentInLocalZone(clockOverride: clockOverride);
  bool isCurrentInUtc({Clock? clockOverride}) =>
      this == Year.currentInUtc(clockOverride: clockOverride);

  /// Whether this year is a common (non-leap) year.
  bool get isCommonYear => !isLeapYear;

  /// Whether this year is a leap year.
  bool get isLeapYear {
    // https://howardhinnant.github.io/date_algorithms.html#is_leap
    return number % 4 == 0 && (number % 100 != 0 || number % 400 == 0);
  }

  Days get lengthInDays => isLeapYear ? const Days(366) : const Days(365);
  int get numberOfWeeks {
    // https://en.wikipedia.org/wiki/ISO_week_date#Weeks_per_year
    Weekday weekdayOfDecember31(Year year) =>
        Date.fromUnchecked(year, Month.december, 31).weekday;

    final isLongWeek = weekdayOfDecember31(this) == Weekday.thursday ||
        weekdayOfDecember31(previous) == Weekday.wednesday;
    return isLongWeek ? 53 : 52;
  }

  YearMonth get firstMonth => YearMonth(this, Month.january);
  YearMonth get lastMonth => YearMonth(this, Month.december);
  Iterable<YearMonth> get months =>
      Month.values.map((month) => YearMonth(this, month));

  YearWeek get firstWeek => YearWeek.fromUnchecked(this, 1);
  YearWeek get lastWeek => YearWeek.fromUnchecked(this, numberOfWeeks);
  Iterable<YearWeek> get weeks {
    return Iterable.generate(
      numberOfWeeks,
      (it) => YearWeek.fromUnchecked(this, it + 1),
    );
  }

  Date get firstDay => firstMonth.firstDay;
  Date get lastDay => lastMonth.lastDay;
  Iterable<Date> get days => months.expand((it) => it.days);

  Year operator +(Years duration) => Year(number + duration.value);
  Year operator -(Years duration) => Year(number - duration.value);

  Year get next => this + const Years(1);

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
