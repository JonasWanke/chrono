import 'dart:core';
import 'dart:core' as core;

import 'package:clock/clock.dart';
import 'package:oxidized/oxidized.dart';

import '../../utils.dart';
import '../period.dart';

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

  static Result<Month, String> fromNumber(int number) {
    if (number < minNumber || number > maxNumber) {
      return Err('Invalid month number: $number');
    }
    return Ok(fromNumberUnchecked(number));
  }

  static Month fromNumberThrowing(int number) =>
      Month.fromNumber(number).unwrap();
  static Month fromNumberUnchecked(int number) => values[number - minNumber];

  static Month fromDart(core.DateTime dateTime) =>
      fromNumberThrowing(dateTime.month);
  static Month currentInLocalZone({Clock? clockOverride}) =>
      fromDart((clockOverride ?? clock).now().toLocal());
  static Month currentInUtc({Clock? clockOverride}) =>
      fromDart((clockOverride ?? clock).now().toUtc());

  static Month fromJson(int json) =>
      fromNumber(json).unwrapOrThrowAsFormatException();

  static const minNumber = 1; // Month.january.number
  static const maxNumber = 12; // Month.december.number

  int get number => index + 1;

  bool isCurrentInLocalZone({Clock? clockOverride}) =>
      this == Month.currentInLocalZone(clockOverride: clockOverride);
  bool isCurrentInUtc({Clock? clockOverride}) =>
      this == Month.currentInUtc(clockOverride: clockOverride);

  Month get next => values[(index + 1) % values.length];
  Month get previous => values[(index - 1) % values.length];

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

  @override
  int compareTo(Month other) => index.compareTo(other.index);

  int toJson() => number;
}
