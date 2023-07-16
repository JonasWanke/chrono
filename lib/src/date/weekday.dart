import 'package:oxidized/oxidized.dart';

import '../utils.dart';
import 'duration.dart';

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

  int get number => index + 1;

  Weekday operator +(FixedDaysDuration duration) =>
      values[(index + duration.inDays.value) % values.length];
  Weekday operator -(FixedDaysDuration duration) => this + (-duration);

  Weekday get next => this + const Days(1);
  Weekday get previous => this - const Days(1);

  Days untilNextOrSame(Weekday other) =>
      Days((other.index - index) % values.length);
  Days untilPreviousOrSame(Weekday other) =>
      Days(-((index - other.index) % values.length));

  @override
  int compareTo(Weekday other) => index.compareTo(other.index);

  int toJson() => number;
}
