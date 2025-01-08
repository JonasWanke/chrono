import 'package:clock/clock.dart';
import 'package:deranged/deranged.dart';
import 'package:meta/meta.dart';
import 'package:oxidized/oxidized.dart';

import '../../codec.dart';
import '../../date_time/date_time.dart';
import '../../parser.dart';
import '../../utils.dart';
import '../date.dart';
import '../duration.dart';
import '../weekday.dart';
import '../year.dart';
import 'month.dart';

/// The combination of a [Year] and a [Month], e.g., April 2023.
@immutable
final class YearMonth
    with ComparisonOperatorsFromComparable<YearMonth>
    implements Comparable<YearMonth>, Step<YearMonth> {
  const YearMonth(this.year, this.month);
  static Result<YearMonth, String> fromRaw(int year, int month) =>
      Month.fromNumber(month).map((month) => YearMonth(Year(year), month));

  factory YearMonth.currentInLocalZone({Clock? clock}) =>
      Date.todayInLocalZone(clock: clock).yearMonth;
  factory YearMonth.currentInUtc({Clock? clock}) =>
      Date.todayInUtc(clock: clock).yearMonth;

  final Year year;
  final Month month;

  bool isCurrentInLocalZone({Clock? clock}) =>
      this == YearMonth.currentInLocalZone(clock: clock);
  bool isCurrentInUtc({Clock? clock}) =>
      this == YearMonth.currentInUtc(clock: clock);

  /// The number of days in this year and month.
  ///
  /// The result is always in the range [28, 31].
  Days get length {
    // https://howardhinnant.github.io/date_algorithms.html#last_day_of_month
    return month != Month.february || year.isCommonYear
        ? month.lengthInCommonYear
        : const Days(29);
  }

  /// The [Date]s in this month.
  RangeInclusive<Date> get dates {
    return RangeInclusive(
      Date.fromYearMonthAndDay(this, 1).unwrap(),
      Date.fromYearMonthAndDay(this, length.inDays).unwrap(),
    );
  }

  /// The [DateTime]s in this month.
  Range<CDateTime> get dateTimes => dates.dateTimes;

  /// How many times the given [weekday] occurs in this month.
  int weekdayCount(Weekday weekday) =>
      (dates.endInclusive.day - dates.start.nextOrSame(weekday).day) ~/
          Days.perWeek +
      1;

  YearMonth operator +(MonthsDuration duration) {
    final (years, months) = duration.splitYearsMonths;

    final rawNewMonth = this.month.number + months.inMonths;
    final (yearAdjustment, month) = switch (rawNewMonth) {
      < Month.minNumber => (-const Years(1), rawNewMonth + Months.perYear),
      > Month.maxNumber => (const Years(1), rawNewMonth - Months.perYear),
      _ => (const Years(0), rawNewMonth),
    };

    return YearMonth(
      year + years + yearAdjustment,
      Month.fromNumber(month).unwrap(),
    );
  }

  YearMonth operator -(MonthsDuration duration) => this + (-duration);

  /// The month after this one.
  YearMonth get next => this + const Months(1);

  /// The month before this one.
  YearMonth get previous => this - const Months(1);

  /// Returns `this - other` as a number of [Months].
  Months difference(YearMonth other) {
    final thisNumber = year.number * Months.perYear + month.number;
    final otherNumber = other.year.number * Months.perYear + other.month.number;
    return Months(thisNumber - otherNumber);
  }

  YearMonth copyWith({Year? year, Month? month}) =>
      YearMonth(year ?? this.year, month ?? this.month);

  @override
  int compareTo(YearMonth other) {
    final result = year.compareTo(other.year);
    if (result != 0) return result;

    return month.compareTo(other.month);
  }

  @override
  YearMonth stepBy(int count) => this + Months(count);
  @override
  int stepsUntil(YearMonth other) => other.difference(this).inMonths;

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
}

extension RangeOfYearMonthChrono on Range<YearMonth> {
  /// The [Date]s in these months.
  RangeInclusive<Date> get dates => inclusive.dates;

  /// The [DateTime]s in these months.
  Range<CDateTime> get dateTimes => dates.dateTimes;
}

extension RangeInclusiveOfYearMonthChrono on RangeInclusive<YearMonth> {
  /// The [Date]s in these months.
  RangeInclusive<Date> get dates =>
      start.dates.start.rangeTo(endInclusive.dates.endInclusive);

  /// The [DateTime]s in these months.
  Range<CDateTime> get dateTimes => exclusive.dateTimes;
}

/// Encodes a [YearMonth] as an ISO 8601 string, e.g., “2023-04”.
class YearMonthAsIsoStringCodec
    extends CodecWithParserResult<YearMonth, String> {
  const YearMonthAsIsoStringCodec();

  @override
  String encode(YearMonth input) => input.toString();
  @override
  Result<YearMonth, FormatException> decodeAsResult(String encoded) =>
      Parser.parseYearMonth(encoded);
}
