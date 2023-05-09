import 'package:clock/clock.dart';
import 'package:meta/meta.dart';
import 'package:oxidized/oxidized.dart';

import 'parser.dart';
import 'plain_date.dart';
import 'plain_month.dart';
import 'plain_week_date.dart';
import 'plain_year.dart';
import 'plain_year_month.dart';
import 'utils.dart';

@immutable
final class PlainOrdinalDate
    with ComparisonOperatorsFromComparable<PlainOrdinalDate>
    implements Comparable<PlainOrdinalDate> {
  static Result<PlainOrdinalDate, String> from(PlainYear year, int dayOfYear) {
    if (dayOfYear < 1 || dayOfYear > year.lengthInDays.value) {
      return Err('Invalid day of year for year $year: $dayOfYear');
    }
    return Ok(PlainOrdinalDate.fromUnchecked(year, dayOfYear));
  }

  factory PlainOrdinalDate.fromThrowing(PlainYear year, int dayOfYear) =>
      from(year, dayOfYear).unwrap();
  PlainOrdinalDate.fromUnchecked(this.year, this.dayOfYear);

  PlainOrdinalDate.fromDate(PlainDate date)
      : this.fromUnchecked(date.year, date.dayOfYear);

  PlainOrdinalDate.fromDateTime(DateTime dateTime)
      : this.fromDate(PlainDate.fromDateTime(dateTime));
  PlainOrdinalDate.todayInLocalZone({Clock? clockOverride})
      : this.fromDateTime((clockOverride ?? clock).now().toLocal());
  PlainOrdinalDate.todayInUtc({Clock? clockOverride})
      : this.fromDateTime((clockOverride ?? clock).now().toUtc());

  factory PlainOrdinalDate.fromJson(String json) =>
      unwrapParserResult(parse(json));
  static Result<PlainOrdinalDate, FormatException> parse(String value) =>
      Parser.parseOrdinalDate(value);

  final PlainYear year;
  final int dayOfYear;

  PlainDate get asDate {
    int firstDayOfYear(PlainMonth month) {
      final firstDayOfYearList = year.isCommonYear
          ? const [1, 32, 60, 91, 121, 152, 182, 213, 244, 274, 305, 335]
          : const [1, 32, 61, 92, 122, 153, 183, 214, 245, 275, 306, 336];
      return firstDayOfYearList[month.index];
    }

    final rawMonth = PlainYearMonth(
      year,
      PlainMonth.fromNumberUnchecked((dayOfYear - 1) ~/ 31 + 1),
    );
    final monthEnd =
        firstDayOfYear(rawMonth.month) + rawMonth.lengthInDays.value - 1;
    final month = dayOfYear > monthEnd ? rawMonth.nextMonth : rawMonth;

    final dayOfMonth = dayOfYear - firstDayOfYear(month.month) + 1;
    return PlainDate.fromYearMonthAndDayUnchecked(month, dayOfMonth);
  }

  PlainWeekDate get asWeekDate => asDate.asWeekDate;

  Result<PlainOrdinalDate, String> copyWith({PlainYear? year, int? dayOfYear}) {
    return PlainOrdinalDate.from(
      year ?? this.year,
      dayOfYear ?? this.dayOfYear,
    );
  }

  @override
  int compareTo(PlainOrdinalDate other) {
    final result = year.compareTo(other.year);
    if (result != 0) return result;

    return dayOfYear.compareTo(other.dayOfYear);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is PlainOrdinalDate &&
            year == other.year &&
            dayOfYear == other.dayOfYear);
  }

  @override
  int get hashCode => Object.hash(year, dayOfYear);

  @override
  String toString() {
    final dayOfYear = this.dayOfYear.toString().padLeft(3, '0');
    return '$year-$dayOfYear';
  }

  String toJson() => toString();
}
