import 'package:oxidized/oxidized.dart';

import 'utils.dart';

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

  Weekday get next => values[(index + 1) % values.length];
  Weekday get previous => values[(index - 1) % values.length];

  @override
  int compareTo(Weekday other) => index.compareTo(other.index);

  int toJson() => number;
}
