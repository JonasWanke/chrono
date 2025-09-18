import 'package:clock/clock.dart';
import 'package:deranged/deranged.dart';
import 'package:oxidized/oxidized.dart';

import '../../codec.dart';
import '../../utils.dart';
import '../date.dart';
import '../duration.dart';
import 'month_day.dart';

/// A month in the ISO 8601 calendar, e.g., April.
enum Month
    with ComparisonOperatorsFromComparable<Month>
    implements Comparable<Month>, Step<Month> {
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

  /// Returns the month with the given [index].
  ///
  /// The index must be in the range 0 for January, …, 11 for December. For any
  /// other number, an error is returned.
  static Result<Month, String> fromIndex(int index) {
    if (index < minIndex || index > maxIndex) {
      return Err('Invalid month index: $index');
    }
    return Ok(values[index - minIndex]);
  }

  /// Returns the month with the given [number].
  ///
  /// The number must be in the range 1 for January, …, 12 for December. For any
  /// other number, an error is returned.
  static Result<Month, String> fromNumber(int number) {
    if (number < minNumber || number > maxNumber) {
      return Err('Invalid month number: $number');
    }
    return Ok(values[number - minNumber]);
  }

  static Month currentInLocalZone({Clock? clock}) =>
      Date.todayInLocalZone(clock: clock).month;
  static Month currentInUtc({Clock? clock}) =>
      Date.todayInUtc(clock: clock).month;

  static const minIndex = 0; // Month.january.index
  static const maxIndex = 11; // Month.december.index
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
  Days get lengthInCommonYear {
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
  Days get lengthInLeapYear {
    // https://howardhinnant.github.io/date_algorithms.html#last_day_of_month_leap_year
    const days = [
      //
      Days(31), Days(29), Days(31), Days(30), Days(31), Days(30),
      Days(31), Days(31), Days(30), Days(31), Days(30), Days(31),
    ];
    return days[index];
  }

  /// The minimum number of days in this month.
  Days get minLength => lengthInCommonYear;

  /// The maximum number of days in this month.
  Days get maxLength => lengthInLeapYear;

  /// The [MonthDay]s in this month in a common (non-leap) year.
  RangeInclusive<MonthDay> get daysInCommonYear {
    return RangeInclusive(
      MonthDay.from(this, 1).unwrap(),
      MonthDay.from(this, lengthInCommonYear.inDays).unwrap(),
    );
  }

  /// The [MonthDay]s in this month in a leap year.
  RangeInclusive<MonthDay> get daysInLeapYear {
    return RangeInclusive(
      MonthDay.from(this, 1).unwrap(),
      MonthDay.from(this, lengthInLeapYear.inDays).unwrap(),
    );
  }

  MonthDay get minLastDay => daysInCommonYear.endInclusive;
  MonthDay get maxLastDay => daysInLeapYear.endInclusive;

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
  Month stepBy(int count) => this + Months(count);
  @override
  int stepsUntil(Month other) => (other.index - index) % values.length;

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
}

/// Encodes a [Month] as an int: 1 for January, …, 12 for December.
class MonthAsIntJsonConverter extends CodecWithStringResult<Month, int> {
  const MonthAsIntJsonConverter();

  @override
  int encode(Month input) => input.number;
  @override
  Result<Month, String> decodeAsResult(int encoded) =>
      Month.fromNumber(encoded);
}
