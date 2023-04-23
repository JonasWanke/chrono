import 'package:meta/meta.dart';
import 'package:oxidized/oxidized.dart';

import 'parser.dart';
import 'plain_month.dart';
import 'plain_year.dart';
import 'utils.dart';

@immutable
final class PlainYearMonth
    with ComparisonOperatorsFromComparable<PlainYearMonth>
    implements Comparable<PlainYearMonth> {
  const PlainYearMonth(this.year, [this.month = PlainMonth.january]);
  PlainYearMonth.fromDateTime(DateTime dateTime)
      : year = PlainYear.fromDateTime(dateTime),
        month = PlainMonth.fromDateTime(dateTime);

  factory PlainYearMonth.fromJson(String json) =>
      unwrapParserResult(parse(json));
  static Result<PlainYearMonth, FormatException> parse(String value) =>
      Parser.parseYearMonth(value);

  // TODO
  // static PlainYearMonth thisMonthInLocalZone() =>
  //     PlainDate.todayInLocalZone().yearMonth;
  // static PlainYearMonth thisMonthInUtc() => PlainDate.todayInUtc().yearMonth;

  final PlainYear year;
  final PlainMonth month;

  /// The number of days in this year and month.
  ///
  /// The result is always in the range [28, 31].
  int get numberOfDays {
    // https://howardhinnant.github.io/date_algorithms.html#last_day_of_month
    return month != PlainMonth.february || !year.isLeapYear
        ? month.numberOfDaysInCommonYear
        : 29;
  }

  // TODO: isCurrentMonthInLocalZone, isCurrentMonthInUtc?

  PlainYearMonth copyWith({PlainYear? year, PlainMonth? month}) =>
      PlainYearMonth(year ?? this.year, month ?? this.month);

  @override
  int compareTo(PlainYearMonth other) {
    if (year != other.year) return year.compareTo(other.year);
    return month.compareTo(other.month);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is PlainYearMonth && year == other.year && month == other.month);
  }

  @override
  int get hashCode => Object.hash(year, month);

  @override
  String toString() {
    final month = this.month.number.toString().padLeft(2, '0');
    return '$year-$month';
  }

  String toJson() => toString();
}
