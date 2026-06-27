import 'package:clock/clock.dart';
import 'package:deranged/deranged.dart';

import '../../chrono.dart';
import '../codec.dart';
import '../utils.dart';

/// A quarter of a year in the ISO 8601 calendar, e.g., the first quarter
/// (January, February, March).
enum Quarter
    with ComparisonOperatorsFromComparable<Quarter>
    implements Comparable<Quarter> {
  q1,
  q2,
  q3,
  q4;

  /// Returns the quarter with the given [index].
  ///
  /// The index must be in the range 0 for the first quarter, …, 3 for the
  /// fourth quarter. For any other number, a [RangeError] is thrown.
  factory Quarter.fromIndex(int index) {
    RangeError.checkValueInInterval(index, minIndex, maxIndex, 'index');
    return values[index - minIndex];
  }

  /// Returns the quarter with the given [index].
  ///
  /// The index must be in the range 0 for the first quarter, …, 3 for the
  /// fourth quarter. For any other number, `null` is returned.
  static Quarter? fromIndexOrNull(int index) =>
      minIndex <= index && index <= maxIndex ? values[index - minIndex] : null;

  /// Returns the quarter with the given [number].
  ///
  /// The number must be in the range 1 for the first quarter, …, 4 for the
  /// fourth quarter. For any other number, a [RangeError] is thrown.
  factory Quarter.fromNumber(int number) {
    RangeError.checkValueInInterval(number, minNumber, maxNumber, 'number');
    return values[number - minNumber];
  }

  /// Returns the quarter with the given [number].
  ///
  /// The number must be in the range 1 for the first quarter, …, 4 for the
  /// fourth quarter. For any other number, `null` is returned.
  static Quarter? fromNumberOrNull(int number) {
    return minNumber <= number && number <= maxNumber
        ? values[number - minNumber]
        : null;
  }

  static Quarter currentInLocalZone({Clock? clock}) =>
      Date.todayInLocalZone(clock: clock).quarter;
  static Quarter currentInUtc({Clock? clock}) =>
      Date.todayInUtc(clock: clock).quarter;

  static const minIndex = 0; // Quarter.q1.index
  static const maxIndex = 3; // Quarter.q4.index
  static const minNumber = 1; // Quarter.q1.number
  static const maxNumber = 4; // Quarter.q4.number

  /// The number of this quarter (1 for the first quarter, …, 4 for the fourth
  /// quarter).
  int get number => index + 1;

  bool isCurrentInLocalZone({Clock? clock}) =>
      this == Quarter.currentInLocalZone(clock: clock);
  bool isCurrentInUtc({Clock? clock}) =>
      this == Quarter.currentInUtc(clock: clock);

  Month get firstMonth => Month.fromIndex(index * 3);
  Month get lastMonth => Month.fromIndex((index + 1) * 3 - 1);

  /// The number of days in this quarter of a common (non-leap) year.
  ///
  /// The result is always in the range [90, 92].
  Days get lengthInCommonYear =>
      const [Days(90), Days(91), Days(92), Days(92)][index];

  /// The number of days in this quarter of a leap year.
  ///
  /// The result is always in the range [91, 92].
  Days get lengthInLeapYear =>
      const [Days(91), Days(91), Days(92), Days(92)][index];

  /// The minimum number of days in this quarter.
  Days get minLength => lengthInCommonYear;

  /// The maximum number of days in this quarter.
  Days get maxLength => lengthInLeapYear;

  /// The [MonthDay]s in this month in a common (non-leap) year.
  RangeInclusive<MonthDay> get daysInCommonYear =>
      RangeInclusive(firstDay, minLastDay);

  /// The [MonthDay]s in this month in a leap year.
  RangeInclusive<MonthDay> get daysInLeapYear =>
      RangeInclusive(firstDay, maxLastDay);

  MonthDay get firstDay => firstMonth.firstDay;
  MonthDay get minLastDay => lastMonth.minLastDay;
  MonthDay get maxLastDay => lastMonth.maxLastDay;

  // TODO(JonasWanke): arithmetic, Step

  @override
  int compareTo(Quarter other) => index.compareTo(other.index);

  @override
  String toString() => 'Q$number';
}

/// Encodes a [Quarter] as an int: 1 for the first quarter, …, 4 for the fourth
/// quarter.
class QuarterAsIntJsonConverter extends CodecAndJsonConverter<Quarter, int> {
  const QuarterAsIntJsonConverter();

  @override
  int encode(Quarter input) => input.number;
  @override
  Quarter decode(int encoded) => Quarter.fromNumber(encoded);
}
