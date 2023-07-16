import 'package:oxidized/oxidized.dart';

import '../utils.dart';
import 'duration.dart';

/// A weekday in the ISO 8601 calendar.
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

  /// Returns the weekday with the given [number].
  ///
  /// The number must be in the range 1 for Monday, …, 7 for Sunday. For any
  /// other number, an error is returned.
  static Result<Weekday, String> fromNumber(int number) {
    if (number < minNumber || number > maxNumber) {
      return Err('Invalid weekday number: $number');
    }
    return Ok(fromNumberUnchecked(number));
  }

  static Weekday fromNumberUnchecked(int number) => values[number - minNumber];
  static Weekday fromNumberThrowing(int number) =>
      Weekday.fromNumber(number).unwrap();

  static Weekday fromJson(int json) =>
      fromNumber(json).unwrapOrThrowAsFormatException();

  static const minNumber = 1; // Weekday.monday.number
  static const maxNumber = 7; // Weekday.sunday.number

  /// The number of this weekday (1 for Monday, …, 7 for Sunday).
  int get number => index + 1;

  Weekday operator +(FixedDaysDuration duration) =>
      values[(index + duration.inDays.value) % values.length];
  Weekday operator -(FixedDaysDuration duration) => this + (-duration);

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

  int toJson() => number;
}
