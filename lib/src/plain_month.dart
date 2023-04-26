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

  static PlainMonth? fromNumber(int number) {
    if (number < PlainMonth.january.number ||
        number > PlainMonth.december.number) return null;
    return values[number - PlainMonth.january.number];
  }

  static PlainMonth fromJson(int json) {
    final result = fromNumber(json);
    if (result == null) throw FormatException('Invalid month number: $json');
    return result;
  }

  static PlainMonth fromDateTime(DateTime dateTime) =>
      fromNumber(dateTime.month)!;

  static final minNumber = PlainMonth.january.number;
  static final maxNumber = PlainMonth.december.number;

  int get number => index + 1;

  PlainMonth get next => values[(index + 1) % values.length];
  PlainMonth get previous => values[(index - 1) % values.length];

  /// The number of days in this month of a common (non-leap) year.
  ///
  /// The result is always in the range [28, 31].
  int get numberOfDaysInCommonYear {
    // https://howardhinnant.github.io/date_algorithms.html#last_day_of_month_common_year
    const days = [31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
    return days[index];
  }

  /// The number of days in this month of a leap year.
  ///
  /// The result is always in the range [29, 31].
  int get numberOfDaysInLeapYear {
    // https://howardhinnant.github.io/date_algorithms.html#last_day_of_month_leap_year
    const days = [31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
    return days[index];
  }

  @override
  int compareTo(PlainMonth other) => index.compareTo(other.index);

  int toJson() => number;
}
