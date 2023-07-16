import 'dart:core';
import 'dart:core' as core;

import 'package:clock/clock.dart';
import 'package:meta/meta.dart';
import 'package:oxidized/oxidized.dart';

import '../../parser.dart';
import '../../utils.dart';
import '../date.dart';
import '../duration.dart';
import '../year.dart';
import 'month.dart';

/// The combination of a [Year] and a [Month].
@immutable
final class YearMonth
    with ComparisonOperatorsFromComparable<YearMonth>
    implements Comparable<YearMonth> {
  const YearMonth(this.year, [this.month = Month.january]);

  YearMonth.fromCore(core.DateTime dateTime)
      : year = Year.fromCore(dateTime),
        month = Month.fromCore(dateTime);
  YearMonth.currentInLocalZone({Clock? clockOverride})
      : this.fromCore((clockOverride ?? clock).now().toLocal());
  YearMonth.currentInUtc({Clock? clockOverride})
      : this.fromCore((clockOverride ?? clock).now().toUtc());

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

  /// The first day of this month.
  Date get firstDay => Date.fromYearMonthAndDayUnchecked(this, 1);

  /// The last day of this month.
  Date get lastDay =>
      Date.fromYearMonthAndDayUnchecked(this, lengthInDays.value);

  /// An iterable of all days in this month.
  Iterable<Date> get days {
    return Iterable.generate(
      lengthInDays.value,
      (it) => Date.fromYearMonthAndDayUnchecked(this, it + 1),
    );
  }

  YearMonth operator +(MonthsDuration duration) {
    final (years, months) = duration.inYearsAndMonths;

    final rawNewMonth = this.month.number + months.value % Months.perYear;
    final (yearAdjustment, month) = switch (rawNewMonth) {
      < Month.minNumber => (-const Years(1), rawNewMonth + Months.perYear),
      > Month.maxNumber => (const Years(1), rawNewMonth - Months.perYear),
      _ => (const Years(0), rawNewMonth),
    };

    return YearMonth(
      year + years + yearAdjustment,
      Month.fromNumberUnchecked(month),
    );
  }

  YearMonth operator -(MonthsDuration duration) => this + (-duration);

  /// The month after this one.
  YearMonth get next => this + const Months(1);

  /// The month before this one.
  YearMonth get previous => this - const Months(1);

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
