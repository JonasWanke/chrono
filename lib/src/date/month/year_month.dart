import 'dart:core';
import 'dart:core' as core;

import 'package:clock/clock.dart';
import 'package:meta/meta.dart';
import 'package:oxidized/oxidized.dart';

import '../../parser.dart';
import '../../utils.dart';
import '../date.dart';
import '../period.dart';
import '../year.dart';
import 'month.dart';

@immutable
final class YearMonth
    with ComparisonOperatorsFromComparable<YearMonth>
    implements Comparable<YearMonth> {
  const YearMonth(this.year, [this.month = Month.january]);

  YearMonth.fromDart(core.DateTime dateTime)
      : year = Year.fromDart(dateTime),
        month = Month.fromDart(dateTime);
  YearMonth.currentInLocalZone({Clock? clockOverride})
      : this.fromDart((clockOverride ?? clock).now().toLocal());
  YearMonth.currentInUtc({Clock? clockOverride})
      : this.fromDart((clockOverride ?? clock).now().toUtc());

  factory YearMonth.fromJson(String json) => unwrapParserResult(parse(json));
  static Result<YearMonth, FormatException> parse(String value) =>
      Parser.parseYearMonth(value);

  final Year year;
  final Month month;

  bool isCurrentInLocalZone({Clock? clockOverride}) =>
      this == YearMonth.currentInLocalZone(clockOverride: clockOverride);
  bool isCurrentInUtc({Clock? clockOverride}) =>
      this == YearMonth.currentInUtc(clockOverride: clockOverride);

  /// The number of days in this year and month.
  ///
  /// The result is always in the range [28, 31].
  Days get lengthInDays {
    // https://howardhinnant.github.io/date_algorithms.html#last_day_of_month
    return month != Month.february || year.isCommonYear
        ? month.lengthInDaysInCommonYear
        : const Days(29);
  }

  Date get firstDay => Date.fromYearMonthAndDayUnchecked(this, 1);
  Date get lastDay =>
      Date.fromYearMonthAndDayUnchecked(this, lengthInDays.value);
  Iterable<Date> get days {
    return Iterable.generate(
      lengthInDays.value,
      (it) => Date.fromYearMonthAndDayUnchecked(this, it + 1),
    );
  }

  YearMonth operator +(MonthsPeriod period) {
    final (years, months) = period.inYearsAndMonths;

    final rawNewMonth = this.month.number + months.value % Months.perYear.value;
    final (yearAdjustment, month) = switch (rawNewMonth) {
      < Month.minNumber => (
          -const Years(1),
          rawNewMonth + Months.perYear.value
        ),
      > Month.maxNumber => (const Years(1), rawNewMonth - Months.perYear.value),
      _ => (const Years(0), rawNewMonth),
    };

    return YearMonth(
      year + years + yearAdjustment,
      Month.fromNumberUnchecked(month),
    );
  }

  YearMonth operator -(MonthsPeriod period) => this + (-period);

  YearMonth get nextMonth => this + const Months(1);
  YearMonth get previousMonth => this - const Months(1);

  YearMonth copyWith({Year? year, Month? month}) =>
      YearMonth(year ?? this.year, month ?? this.month);

  @override
  int compareTo(YearMonth other) {
    final result = year.compareTo(other.year);
    if (result != 0) return result;

    return month.compareTo(other.month);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is YearMonth && year == other.year && month == other.month);
  }

  @override
  int get hashCode => Object.hash(year, month);

  @override
  String toString() {
    final month = this.month.number.toString().padLeft(2, '0');
    return '$year-$month';
  }

  String toJson() => toString();
}
