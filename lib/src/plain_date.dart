import 'package:clock/clock.dart';
import 'package:meta/meta.dart';
import 'package:oxidized/oxidized.dart';

import 'parser.dart';
import 'plain_month.dart';
import 'plain_year.dart';
import 'plain_year_month.dart';
import 'utils.dart';

@immutable
final class PlainDate
    with ComparisonOperatorsFromComparable<PlainDate>
    implements Comparable<PlainDate> {
  const PlainDate._fromYearMonthAndDayUnchecked(this.yearMonth, this.day);
  factory PlainDate.fromThrowing(
    PlainYear year, [
    PlainMonth month = PlainMonth.january,
    int day = 1,
  ]) =>
      from(year, month, day).unwrap();
  factory PlainDate.fromYearMonthAndDayThrowing(
    PlainYearMonth yearMonth,
    int day,
  ) =>
      fromYearMonthAndDay(yearMonth, day).unwrap();

  PlainDate.fromDateTime(DateTime dateTime)
      : this._fromYearMonthAndDayUnchecked(
          PlainYearMonth.fromDateTime(dateTime),
          dateTime.day,
        );
  PlainDate.todayInLocalZone({Clock? clockOverride})
      : this.fromDateTime((clockOverride ?? clock).now().toLocal());
  PlainDate.todayInUtc({Clock? clockOverride})
      : this.fromDateTime((clockOverride ?? clock).now().toUtc());

  factory PlainDate.fromJson(String json) => unwrapParserResult(parse(json));
  static Result<PlainDate, FormatException> parse(String value) =>
      Parser.parseDate(value);

  static Result<PlainDate, String> from(
    PlainYear year, [
    PlainMonth month = PlainMonth.january,
    int day = 1,
  ]) =>
      fromYearMonthAndDay(PlainYearMonth.from(year, month), day);
  static Result<PlainDate, String> fromYearMonthAndDay(
    PlainYearMonth yearMonth,
    int day,
  ) {
    if (day < 0 || day > yearMonth.numberOfDays) {
      return Err('Invalid day for $yearMonth: $day');
    }
    return Ok(PlainDate._fromYearMonthAndDayUnchecked(yearMonth, day));
  }

  final PlainYearMonth yearMonth;
  PlainYear get year => yearMonth.year;
  PlainMonth get month => yearMonth.month;
  final int day;

  // TODO: week and day of week

  bool isTodayInLocalZone({Clock? clockOverride}) =>
      this == PlainDate.todayInLocalZone(clockOverride: clockOverride);
  bool isTodayInUtc({Clock? clockOverride}) =>
      this == PlainDate.todayInUtc(clockOverride: clockOverride);

  Result<PlainDate, String> copyWith({
    PlainYearMonth? yearMonth,
    PlainYear? year,
    PlainMonth? month,
    int? day,
  }) {
    assert(yearMonth == null || (year == null && month == null));

    return PlainDate.fromYearMonthAndDay(
      yearMonth ?? PlainYearMonth.from(year ?? this.year, month ?? this.month),
      day ?? this.day,
    );
  }

  @override
  int compareTo(PlainDate other) {
    final result = yearMonth.compareTo(other.yearMonth);
    if (result != 0) return result;

    return day.compareTo(other.day);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is PlainDate &&
            yearMonth == other.yearMonth &&
            day == other.day);
  }

  @override
  int get hashCode => Object.hash(yearMonth, day);

  @override
  String toString() {
    final day = this.day.toString().padLeft(2, '0');
    return '$yearMonth-$day';
  }

  String toJson() => toString();
}
