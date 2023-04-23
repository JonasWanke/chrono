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

  static Weekday? fromNumber(int number) {
    if (number < Weekday.monday.number || number > Weekday.sunday.number) {
      return null;
    }

    return values[number - Weekday.monday.number];
  }

  static final minNumber = Weekday.monday.number;
  static final maxNumber = Weekday.sunday.number;

  int get number => index + 1;

  Weekday get next => values[(index + 1) % values.length];
  Weekday get previous => values[(index - 1) % values.length];

  @override
  int compareTo(Weekday other) => index.compareTo(other.index);
}
