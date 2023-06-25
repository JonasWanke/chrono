import 'dart:core';
import 'dart:core' as core;

import 'package:clock/clock.dart';
import 'package:meta/meta.dart';
import 'package:oxidized/oxidized.dart';

import '../parser.dart';
import '../utils.dart';
import 'date.dart';
import 'month/month.dart';
import 'month/year_month.dart';
import 'period.dart';
import 'week/week_date.dart';
import 'year.dart';

@immutable
final class OrdinalDate
    with ComparisonOperatorsFromComparable<OrdinalDate>
    implements Comparable<OrdinalDate> {
  static Result<OrdinalDate, String> from(Year year, int dayOfYear) {
    if (dayOfYear < 1 || dayOfYear > year.lengthInDays.value) {
      return Err('Invalid day of year for year $year: $dayOfYear');
    }
    return Ok(OrdinalDate.fromUnchecked(year, dayOfYear));
  }

  factory OrdinalDate.fromThrowing(Year year, int dayOfYear) =>
      from(year, dayOfYear).unwrap();
  OrdinalDate.fromUnchecked(this.year, this.dayOfYear);

  OrdinalDate.fromDate(Date date)
      : this.fromUnchecked(date.year, date.dayOfYear);

  OrdinalDate.fromDart(core.DateTime dateTime)
      : this.fromDate(Date.fromDart(dateTime));
  OrdinalDate.todayInLocalZone({Clock? clockOverride})
      : this.fromDart((clockOverride ?? clock).now().toLocal());
  OrdinalDate.todayInUtc({Clock? clockOverride})
      : this.fromDart((clockOverride ?? clock).now().toUtc());

  factory OrdinalDate.fromJson(String json) => unwrapParserResult(parse(json));
  static Result<OrdinalDate, FormatException> parse(String value) =>
      Parser.parseOrdinalDate(value);

  final Year year;
  final int dayOfYear;

  Date get asDate {
    int firstDayOfYear(Month month) {
      final firstDayOfYearList = year.isCommonYear
          ? const [1, 32, 60, 91, 121, 152, 182, 213, 244, 274, 305, 335]
          : const [1, 32, 61, 92, 122, 153, 183, 214, 245, 275, 306, 336];
      return firstDayOfYearList[month.index];
    }

    final rawMonth = YearMonth(
      year,
      Month.fromNumberUnchecked((dayOfYear - 1) ~/ 31 + 1),
    );
    final monthEnd =
        firstDayOfYear(rawMonth.month) + rawMonth.lengthInDays.value - 1;
    final month = dayOfYear > monthEnd ? rawMonth.nextMonth : rawMonth;

    final dayOfMonth = dayOfYear - firstDayOfYear(month.month) + 1;
    return Date.fromYearMonthAndDayUnchecked(month, dayOfMonth);
  }

  WeekDate get asWeekDate => asDate.asWeekDate;

  bool isTodayInLocalZone({Clock? clockOverride}) =>
      this == OrdinalDate.todayInLocalZone(clockOverride: clockOverride);
  bool isTodayInUtc({Clock? clockOverride}) =>
      this == OrdinalDate.todayInUtc(clockOverride: clockOverride);

  OrdinalDate operator +(FixedDaysPeriod period) =>
      (asDate + period).asOrdinalDate;
  OrdinalDate operator -(FixedDaysPeriod period) => this + (-period);

  OrdinalDate get nextDay {
    return dayOfYear == year.lengthInDays.value
        ? OrdinalDate.fromUnchecked(year + const Years(1), 1)
        : OrdinalDate.fromUnchecked(year, dayOfYear + 1);
  }

  OrdinalDate get previousDay {
    return dayOfYear == 1
        ? OrdinalDate.fromUnchecked(year - const Years(1), 1)
        : OrdinalDate.fromUnchecked(year, dayOfYear - 1);
  }

  Result<OrdinalDate, String> copyWith({Year? year, int? dayOfYear}) =>
      OrdinalDate.from(year ?? this.year, dayOfYear ?? this.dayOfYear);
  OrdinalDate copyWithThrowing({Year? year, int? dayOfYear}) {
    return OrdinalDate.fromThrowing(
      year ?? this.year,
      dayOfYear ?? this.dayOfYear,
    );
  }

  OrdinalDate copyWithUnchecked({Year? year, int? dayOfYear}) {
    return OrdinalDate.fromUnchecked(
      year ?? this.year,
      dayOfYear ?? this.dayOfYear,
    );
  }

  @override
  int compareTo(OrdinalDate other) {
    final result = year.compareTo(other.year);
    if (result != 0) return result;

    return dayOfYear.compareTo(other.dayOfYear);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is OrdinalDate &&
            year == other.year &&
            dayOfYear == other.dayOfYear);
  }

  @override
  int get hashCode => Object.hash(year, dayOfYear);

  @override
  String toString() {
    final dayOfYear = this.dayOfYear.toString().padLeft(3, '0');
    return '$year-$dayOfYear';
  }

  String toJson() => toString();
}
