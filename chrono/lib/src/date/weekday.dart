import 'package:clock/clock.dart';

import '../codec.dart';
import '../utils.dart';
import 'date.dart';
import 'duration.dart';

/// A weekday in the ISO 8601 calendar, e.g., Sunday.
///
/// In this calendar, the week starts on Monday and ends on Sunday.
enum Weekday
    with ComparisonOperatorsFromComparable<Weekday>
    implements Comparable<Weekday> {
  monday,
  tuesday,
  wednesday,
  thursday,
  friday,
  saturday,
  sunday;

  /// Returns the weekday with the given [index].
  ///
  /// The index must be in the range 0 for Monday, …, 6 for Sunday. For any
  /// other number, a [RangeError] is thrown.
  factory Weekday.fromIndex(int index) {
    RangeError.checkValueInInterval(index, minIndex, maxIndex, 'index');
    return values[index - minIndex];
  }

  /// Returns the weekday with the given [index].
  ///
  /// The index must be in the range 0 for Monday, …, 6 for Sunday. For any
  /// other number, `null` is returned.
  static Weekday? fromIndexOrNull(int index) =>
      minIndex <= index && index <= maxIndex ? values[index - minIndex] : null;

  /// Returns the weekday with the given [number].
  ///
  /// The number must be in the range 1 for Monday, …, 7 for Sunday. For any
  /// other number, a [RangeError] is thrown.
  factory Weekday.fromNumber(int number) {
    RangeError.checkValueInInterval(number, minNumber, maxNumber, 'number');
    return values[number - minNumber];
  }

  /// Returns the weekday with the given [number].
  ///
  /// The number must be in the range 1 for Monday, …, 7 for Sunday. For any
  /// other number, `null` is returned.
  static Weekday? fromNumberOrNull(int number) {
    return minNumber <= number && number <= maxNumber
        ? values[number - minNumber]
        : null;
  }

  factory Weekday.currentInLocalZone({Clock? clock}) =>
      Date.todayInLocalZone(clock: clock).weekday;
  factory Weekday.currentInUtc({Clock? clock}) =>
      Date.todayInUtc(clock: clock).weekday;

  static const minIndex = 0; // Weekday.monday.index
  static const maxIndex = 6; // Weekday.sunday.index
  static const minNumber = 1; // Weekday.monday.number
  static const maxNumber = 7; // Weekday.sunday.number

  /// The number of this weekday (1 for Monday, …, 7 for Sunday).
  int get isoNumber => index + 1;

  /// The number of this weekday (from 1 to 7) with [firstDayOfWeek] equal to 1.
  int number({required Weekday firstDayOfWeek}) =>
      (Days.perWeek + index - firstDayOfWeek.index) % Days.perWeek + 1;

  // TODO: index with `firstDayOfWeek`

  bool isCurrentInLocalZone({Clock? clock}) =>
      this == Weekday.currentInLocalZone(clock: clock);
  bool isCurrentInUtc({Clock? clock}) =>
      this == Weekday.currentInUtc(clock: clock);

  Weekday operator +(DaysDuration duration) =>
      values[(index + duration.asDays.inDays) % values.length];
  Weekday operator -(DaysDuration duration) => this + (-duration);

  /// The weekday after this one, wrapping around after Sunday.
  Weekday get next => this + const Days(1);

  /// The weekday before this one, wrapping around before Monday.
  Weekday get previous => this - const Days(1);

  /// The number of days from this weekday to the next [other] weekday.
  ///
  /// The result is always in the range `Days(0)` to `Days(6)`.
  Days untilNextOrSame(Weekday other) =>
      Days((other.index - index) % values.length);

  /// The number of days from this weekday to the previous [other] weekday.
  ///
  /// The result is always in the range `Days(0)` to `Days(-6)`.
  Days untilPreviousOrSame(Weekday other) =>
      Days(-((index - other.index) % values.length));

  @override
  int compareTo(Weekday other) => index.compareTo(other.index);

  @override
  String toString() {
    return switch (this) {
      Weekday.monday => 'Monday',
      Weekday.tuesday => 'Tuesday',
      Weekday.wednesday => 'Wednesday',
      Weekday.thursday => 'Thursday',
      Weekday.friday => 'Friday',
      Weekday.saturday => 'Saturday',
      Weekday.sunday => 'Sunday',
    };
  }
}

// TODO: String JSON converters, maybe lowercase and uppercase?

/// Encodes a [Weekday] as an ISO 8601 weekday number: 1 for Monday, …, 7 for
/// Sunday.
class WeekdayAsIntCodec extends CodecAndJsonConverter<Weekday, int> {
  const WeekdayAsIntCodec();

  @override
  int encode(Weekday input) => input.isoNumber;
  @override
  Weekday decode(int encoded) => Weekday.fromNumber(encoded);
}
