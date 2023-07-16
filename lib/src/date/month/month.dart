import 'dart:core';
import 'dart:core' as core;

import 'package:clock/clock.dart';
import 'package:oxidized/oxidized.dart';

import '../../date_time/date_time.dart';
import '../../utils.dart';
import '../duration.dart';

/// A month in the ISO 8601 calendar.
enum Month
    with ComparisonOperatorsFromComparable<Month>
    implements Comparable<Month> {
  january,
  february,
  march,
  april,
  may,
  june,
  july,
  august,
  september,
  october,
  november,
  december;

  /// Returns the month with the given [number].
  ///
  /// The number must be in the range 1 for January, …, 12 for December. For any
  /// other number, an error is returned.
  static Result<Month, String> fromNumber(int number) {
    if (number < minNumber || number > maxNumber) {
      return Err('Invalid month number: $number');
    }
    return Ok(fromNumberUnchecked(number));
  }

  static Month fromNumberThrowing(int number) =>
      Month.fromNumber(number).unwrap();
  static Month fromNumberUnchecked(int number) => values[number - minNumber];

  static Month currentInLocalZone({Clock? clock}) =>
      DateTime.nowInLocalZone(clock: clock).date.month;
  static Month currentInUtc({Clock? clock}) =>
      DateTime.nowInUtc(clock: clock).date.month;

  static Month fromJson(int json) =>
      fromNumber(json).unwrapOrThrowAsFormatException();

  static const minNumber = 1; // Month.january.number
  static const maxNumber = 12; // Month.december.number

  /// The number of this month (1 for January, …, 12 for December).
  int get number => index + 1;

  bool isCurrentInLocalZone({Clock? clock}) =>
      this == Month.currentInLocalZone(clock: clock);
  bool isCurrentInUtc({Clock? clock}) =>
      this == Month.currentInUtc(clock: clock);

  /// The number of days in this month of a common (non-leap) year.
  ///
  /// The result is always in the range [28, 31].
  Days get lengthInDaysInCommonYear {
    // https://howardhinnant.github.io/date_algorithms.html#last_day_of_month_common_year
    const days = [
      //
      Days(31), Days(28), Days(31), Days(30), Days(31), Days(30),
      Days(31), Days(31), Days(30), Days(31), Days(30), Days(31),
    ];
    return days[index];
  }

  /// The number of days in this month of a leap year.
  ///
  /// The result is always in the range [29, 31].
  Days get lengthInDaysInLeapYear {
    // https://howardhinnant.github.io/date_algorithms.html#last_day_of_month_leap_year
    const days = [
      //
      Days(31), Days(29), Days(31), Days(30), Days(31), Days(30),
      Days(31), Days(31), Days(30), Days(31), Days(30), Days(31),
    ];
    return days[index];
  }

  Month operator +(MonthsDuration duration) =>
      values[(index + duration.asMonths.inMonths) % values.length];
  Month operator -(MonthsDuration duration) => this + (-duration);

  /// The month after this one, wrapping around after January.
  Month get next => this + const Months(1);

  /// The month before this one, wrapping around before January.
  Month get previous => this - const Months(1);

  /// The number of months from this month to the next [other] month.
  ///
  /// The result is always in the range `Months(0)` to `Months(11)`.
  Months untilNextOrSame(Month other) =>
      Months((other.index - index) % values.length);

  /// The number of months from this month to the previous [other] month.
  ///
  /// The result is always in the range `Months(0)` to `Months(-11)`.
  Months untilPreviousOrSame(Month other) =>
      Months(-((index - other.index) % values.length));

  @override
  int compareTo(Month other) => index.compareTo(other.index);

  @override
  String toString() {
    return switch (this) {
      Month.january => 'January',
      Month.february => 'February',
      Month.march => 'March',
      Month.april => 'April',
      Month.may => 'May',
      Month.june => 'June',
      Month.july => 'July',
      Month.august => 'August',
      Month.september => 'September',
      Month.october => 'October',
      Month.november => 'November',
      Month.december => 'December',
    };
  }

  int toJson() => number;
}
