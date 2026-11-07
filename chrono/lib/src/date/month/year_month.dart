import 'package:clock/clock.dart';
import 'package:deranged/deranged.dart';
import 'package:meta/meta.dart';

import '../../../chrono.dart';
import '../../codec.dart';
import '../../parser.dart';
import '../../utils.dart';

/// The combination of a [Year] and a [Month], e.g., April 2023.
@immutable
final class const YearMonth.from(final Year year, final Month month)
    with ComparisonOperatorsFromComparable<YearMonth>, StepUnlimited<YearMonth>
    implements Comparable<YearMonth> {
  new(int year, int month) : this.from(Year(year), Month.fromNumber(month));

  factory currentInLocalZone({Clock? clock}) =>
      Date.todayInLocalZone(clock: clock).yearMonth;
  factory currentInUtc({Clock? clock}) =>
      Date.todayInUtc(clock: clock).yearMonth;

  Quarter get quarter => month.quarter;
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

  /// The [Date] with the given one-based [day] in this month.
  ///
  /// Throws a [RangeError] if [day] is not in `1..length.inDays`.
  Date atDay(int day) => Date.fromYearMonthAndDay(this, day);

  /// Like [atDay], but returns `null` if [day] is out of range.
  Date? atDayOrNull(int day) =>
      day < 1 || day > length.inDays ? null : atDay(day);

  /// The [Date]s in this month.
  RangeInclusive<Date> get dates {
    return RangeInclusive(
      Date.fromYearMonthAndDay(this, 1),
      Date.fromYearMonthAndDay(this, length.inDays),
    );
  }

  /// The [DateTime]s in this month.
  Range<CDateTime> get dateTimes => dates.dateTimes;

  /// How many times the given [weekday] occurs in this month.
  int weekdayCount(Weekday weekday) =>
      (dates.end.day - dates.start.nextOrSame(weekday).day) ~/ Days.perWeek + 1;

  YearMonth operator +(Months duration) {
    final parts = duration.split({.years, .months});

    final rawNewMonth = this.month.number + parts.months;
    final (yearAdjustment, month) = switch (rawNewMonth) {
      < Month.minNumber => (-1, rawNewMonth + Months.perYear),
      > Month.maxNumber => (1, rawNewMonth - Months.perYear),
      _ => (0, rawNewMonth),
    };

    return YearMonth.from(
      year + parts.years + yearAdjustment,
      Month.fromNumber(month),
    );
  }

  YearMonth operator -(Months duration) => this + (-duration);

  /// Returns `this - other` as a number of [Months].
  Months difference(YearMonth other) {
    final thisNumber = year.number * Months.perYear + month.number;
    final otherNumber = other.year.number * Months.perYear + other.month.number;
    return Months(thisNumber - otherNumber);
  }

  YearMonth copyWith({Year? year, Month? month}) =>
      YearMonth.from(year ?? this.year, month ?? this.month);

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
  RangeInclusive<Date> get dates => start.dates.start.rangeTo(end.dates.end);

  /// The [DateTime]s in these months.
  Range<CDateTime> get dateTimes => exclusive.dateTimes;
}

/// Encodes a [YearMonth] as an ISO 8601 string, e.g., “2023-04”.
class const YearMonthAsIsoStringCodec()
    extends CodecAndJsonConverter<YearMonth, String> {
  @override
  String encode(YearMonth input) => input.toString();
  @override
  YearMonth decode(String encoded) => Parser.parseYearMonth(encoded);
}
