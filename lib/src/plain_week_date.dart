import 'package:clock/clock.dart';
import 'package:meta/meta.dart';
import 'package:oxidized/oxidized.dart';

import 'parser.dart';
import 'plain_date.dart';
import 'plain_year_week.dart';
import 'utils.dart';
import 'weekday.dart';

@immutable
final class PlainWeekDate
    with ComparisonOperatorsFromComparable<PlainWeekDate>
    implements Comparable<PlainWeekDate> {
  const PlainWeekDate(this.yearWeek, this.weekday);

  PlainWeekDate.fromDate(PlainDate date) : this(date.yearWeek, date.weekday);

  PlainWeekDate.fromDateTime(DateTime dateTime)
      : this.fromDate(PlainDate.fromDateTime(dateTime));
  PlainWeekDate.todayInLocalZone({Clock? clockOverride})
      : this.fromDateTime((clockOverride ?? clock).now().toLocal());
  PlainWeekDate.todayInUtc({Clock? clockOverride})
      : this.fromDateTime((clockOverride ?? clock).now().toUtc());

  factory PlainWeekDate.fromJson(String json) =>
      unwrapParserResult(parse(json));
  static Result<PlainWeekDate, FormatException> parse(String value) =>
      Parser.parseWeekDate(value);

  final PlainYearWeek yearWeek;
  final Weekday weekday;

  // TODO: asDate

  bool isTodayInLocalZone({Clock? clockOverride}) =>
      this == PlainWeekDate.todayInLocalZone(clockOverride: clockOverride);
  bool isTodayInUtc({Clock? clockOverride}) =>
      this == PlainWeekDate.todayInUtc(clockOverride: clockOverride);

  PlainWeekDate copyWith({PlainYearWeek? yearWeek, Weekday? weekday}) =>
      PlainWeekDate(yearWeek ?? this.yearWeek, weekday ?? this.weekday);

  @override
  int compareTo(PlainWeekDate other) {
    final result = yearWeek.compareTo(other.yearWeek);
    if (result != 0) return result;

    return weekday.compareTo(other.weekday);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is PlainWeekDate &&
            yearWeek == other.yearWeek &&
            weekday == other.weekday);
  }

  @override
  int get hashCode => Object.hash(yearWeek, weekday);

  @override
  String toString() => '$yearWeek-${weekday.number}';

  String toJson() => toString();
}
