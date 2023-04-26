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
  PlainDate(
    PlainYear year, [
    PlainMonth month = PlainMonth.january,
    int day = 1,
  ]) : this.fromYearMonthAndDay(PlainYearMonth(year, month), day);
  const PlainDate.fromYearMonthAndDay(this.yearMonth, this.day);
  // TODO: validation

  PlainDate.fromDateTime(DateTime dateTime)
      : this.fromYearMonthAndDay(
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

  final PlainYearMonth yearMonth;
  PlainYear get year => yearMonth.year;
  PlainMonth get month => yearMonth.month;
  final int day;

  // TODO: week and day of week

  PlainDate copyWith({
    PlainYearMonth? yearMonth,
    PlainYear? year,
    PlainMonth? month,
    int? day,
  }) {
    // TODO: throwing/clamping/wrapping variants?
    assert(yearMonth == null || (year == null && month == null));

    return PlainDate(
      yearMonth?.year ?? year ?? this.year,
      yearMonth?.month ?? month ?? this.month,
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
