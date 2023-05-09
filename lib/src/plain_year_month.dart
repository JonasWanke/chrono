import 'package:clock/clock.dart';
import 'package:meta/meta.dart';
import 'package:oxidized/oxidized.dart';

import 'parser.dart';
import 'period_days.dart';
import 'plain_date.dart';
import 'plain_month.dart';
import 'plain_year.dart';
import 'utils.dart';

@immutable
final class PlainYearMonth
    with ComparisonOperatorsFromComparable<PlainYearMonth>
    implements Comparable<PlainYearMonth> {
  const PlainYearMonth.from(this.year, [this.month = PlainMonth.january]);

  PlainYearMonth.fromDateTime(DateTime dateTime)
      : year = PlainYear.fromDateTime(dateTime),
        month = PlainMonth.fromDateTime(dateTime);
  PlainYearMonth.currentInLocalZone({Clock? clockOverride})
      : this.fromDateTime((clockOverride ?? clock).now().toLocal());
  PlainYearMonth.currentInUtc({Clock? clockOverride})
      : this.fromDateTime((clockOverride ?? clock).now().toUtc());

  factory PlainYearMonth.fromJson(String json) =>
      unwrapParserResult(parse(json));
  static Result<PlainYearMonth, FormatException> parse(String value) =>
      Parser.parseYearMonth(value);

  final PlainYear year;
  final PlainMonth month;

  bool isCurrentInLocalZone({Clock? clockOverride}) =>
      this == PlainYearMonth.currentInLocalZone(clockOverride: clockOverride);
  bool isCurrentInUtc({Clock? clockOverride}) =>
      this == PlainYearMonth.currentInUtc(clockOverride: clockOverride);

  /// The number of days in this year and month.
  ///
  /// The result is always in the range [28, 31].
  Days get lengthInDays {
    // https://howardhinnant.github.io/date_algorithms.html#last_day_of_month
    return month != PlainMonth.february || year.isCommonYear
        ? month.lengthInDaysInCommonYear
        : const Days(29);
  }

  PlainDate get firstDay => PlainDate.fromYearMonthAndDayUnchecked(this, 1);
  PlainDate get lastDay =>
      PlainDate.fromYearMonthAndDayUnchecked(this, lengthInDays.value);

  PlainYearMonth operator +(MonthsPeriod period) {
    final (years, months) = period.inYearsAndMonths;

    final rawNewMonth = this.month.number + months.value % Months.perYear.value;
    final (yearAdjustment, month) = switch (rawNewMonth) {
      < PlainMonth.minNumber => (
          -const Years(1),
          rawNewMonth + Months.perYear.value
        ),
      > PlainMonth.maxNumber => (
          const Years(1),
          rawNewMonth - Months.perYear.value
        ),
      _ => (const Years(0), rawNewMonth),
    };

    return PlainYearMonth.from(
      year + years + yearAdjustment,
      PlainMonth.fromNumberUnchecked(month),
    );
  }

  PlainYearMonth operator -(MonthsPeriod period) => this + (-period);

  PlainYearMonth get nextMonth => this + const Months(1);
  PlainYearMonth get previousMonth => this - const Months(1);

  PlainYearMonth copyWith({PlainYear? year, PlainMonth? month}) =>
      PlainYearMonth.from(year ?? this.year, month ?? this.month);

  @override
  int compareTo(PlainYearMonth other) {
    final result = year.compareTo(other.year);
    if (result != 0) return result;

    return month.compareTo(other.month);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is PlainYearMonth && year == other.year && month == other.month);
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
