import 'package:clock/clock.dart';
import 'package:oxidized/oxidized.dart';

import 'period_days.dart';
import 'utils.dart';

enum PlainMonth
    with ComparisonOperatorsFromComparable<PlainMonth>
    implements Comparable<PlainMonth> {
  january,
  february,
  march,
  april,
  may,
  june,
  juli,
  august,
  september,
  october,
  november,
  december;

  static Result<PlainMonth, String> fromNumber(int number) {
    if (number < minNumber || number > maxNumber) {
      return Err('Invalid month number: $number');
    }
    return Ok(fromNumberUnchecked(number));
  }

  static PlainMonth fromNumberThrowing(int number) =>
      PlainMonth.fromNumber(number).unwrap();
  static PlainMonth fromNumberUnchecked(int number) =>
      values[number - minNumber];

  static PlainMonth fromDateTime(DateTime dateTime) =>
      fromNumberThrowing(dateTime.month);
  static PlainMonth currentInLocalZone({Clock? clockOverride}) =>
      fromDateTime((clockOverride ?? clock).now().toLocal());
  static PlainMonth currentInUtc({Clock? clockOverride}) =>
      fromDateTime((clockOverride ?? clock).now().toUtc());

  static PlainMonth fromJson(int json) =>
      fromNumber(json).unwrapOrThrowAsFormatException();

  static const minNumber = 1; // PlainMonth.january.number
  static const maxNumber = 12; // PlainMonth.december.number

  int get number => index + 1;

  bool isCurrentInLocalZone({Clock? clockOverride}) =>
      this == PlainMonth.currentInLocalZone(clockOverride: clockOverride);
  bool isCurrentInUtc({Clock? clockOverride}) =>
      this == PlainMonth.currentInUtc(clockOverride: clockOverride);

  PlainMonth get next => values[(index + 1) % values.length];
  PlainMonth get previous => values[(index - 1) % values.length];

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
  int compareTo(PlainMonth other) => index.compareTo(other.index);

  int toJson() => number;
}
