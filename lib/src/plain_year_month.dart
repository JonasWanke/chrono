import 'package:clock/clock.dart';
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
  const PlainYearMonth.from(this.year, [this.month = PlainMonth.january]);

  PlainYearMonth.fromDateTime(DateTime dateTime)
      : year = PlainYear.fromDateTime(dateTime),
        month = PlainMonth.fromDateTime(dateTime);
  PlainYearMonth.currentInLocalZone({Clock? clockOverride})
      : this.fromDateTime((clockOverride ?? clock).now().toLocal());
  PlainYearMonth.currentInUtc({Clock? clockOverride})
      : this.fromDateTime((clockOverride ?? clock).now().toUtc());

  factory PlainYearMonth.fromJson(String json) =>
      unwrapParserResult(parse(json));
  static Result<PlainYearMonth, FormatException> parse(String value) =>
      Parser.parseYearMonth(value);

  final PlainYear year;
  final PlainMonth month;

  bool isCurrentInLocalZone({Clock? clockOverride}) =>
      this == PlainYearMonth.currentInLocalZone(clockOverride: clockOverride);
  bool isCurrentInUtc({Clock? clockOverride}) =>
      this == PlainYearMonth.currentInUtc(clockOverride: clockOverride);

  /// The number of days in this year and month.
  ///
  /// The result is always in the range [28, 31].
  int get numberOfDays {
    // https://howardhinnant.github.io/date_algorithms.html#last_day_of_month
    return month != PlainMonth.february || year.isCommonYear
        ? month.numberOfDaysInCommonYear
        : 29;
  }

  PlainYearMonth copyWith({PlainYear? year, PlainMonth? month}) =>
      PlainYearMonth.from(year ?? this.year, month ?? this.month);

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
