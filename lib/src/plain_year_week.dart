import 'package:clock/clock.dart';
import 'package:meta/meta.dart';
import 'package:oxidized/oxidized.dart';

import 'parser.dart';
import 'period_days.dart';
import 'plain_date.dart';
import 'plain_week_date.dart';
import 'plain_year.dart';
import 'utils.dart';
import 'weekday.dart';

@immutable
final class PlainYearWeek
    with ComparisonOperatorsFromComparable<PlainYearWeek>
    implements Comparable<PlainYearWeek> {
  static Result<PlainYearWeek, String> from(PlainYear weekBasedYear, int week) {
    if (week < 0 || week > weekBasedYear.numberOfWeeks) {
      return Err('Invalid week for year $weekBasedYear: $week');
    }
    return Ok(PlainYearWeek.fromUnchecked(weekBasedYear, week));
  }

  const PlainYearWeek.fromUnchecked(this.weekBasedYear, this.week);
  factory PlainYearWeek.fromThrowing(PlainYear weekBasedYear, int week) =>
      from(weekBasedYear, week).unwrap();

  factory PlainYearWeek.fromDateTime(DateTime dateTime) =>
      PlainDate.fromDateTime(dateTime).yearWeek;
  factory PlainYearWeek.currentInLocalZone({Clock? clockOverride}) =>
      PlainYearWeek.fromDateTime((clockOverride ?? clock).now().toLocal());
  factory PlainYearWeek.currentInUtc({Clock? clockOverride}) =>
      PlainYearWeek.fromDateTime((clockOverride ?? clock).now().toUtc());

  factory PlainYearWeek.fromJson(String json) =>
      unwrapParserResult(parse(json));
  static Result<PlainYearWeek, FormatException> parse(String value) =>
      Parser.parseYearWeek(value);

  final PlainYear weekBasedYear;
  final int week;

  bool isCurrentInLocalZone({Clock? clockOverride}) =>
      this == PlainYearWeek.currentInLocalZone(clockOverride: clockOverride);
  bool isCurrentInUtc({Clock? clockOverride}) =>
      this == PlainYearWeek.currentInUtc(clockOverride: clockOverride);

  PlainWeekDate get firstDay => PlainWeekDate(this, Weekday.values.first);
  PlainWeekDate get lastDay => PlainWeekDate(this, Weekday.values.last);
  Iterable<PlainWeekDate> get days =>
      Weekday.values.map((weekday) => PlainWeekDate(this, weekday));

  PlainYearWeek operator +(Weeks period) {
    final newDate = PlainWeekDate(this, Weekday.monday) + period;
    assert(newDate.weekday == Weekday.monday);
    return newDate.yearWeek;
  }

  PlainYearWeek operator -(Weeks period) => this + (-period);

  PlainYearWeek get nextWeek {
    return week == weekBasedYear.numberOfWeeks
        ? PlainYearWeek.fromUnchecked(weekBasedYear + const Years(1), 1)
        : PlainYearWeek.fromUnchecked(weekBasedYear, week + 1);
  }

  PlainYearWeek get previousWeek {
    return week == 1
        ? PlainYearWeek.fromUnchecked(weekBasedYear - const Years(1), 1)
        : PlainYearWeek.fromUnchecked(weekBasedYear, week - 1);
  }

  Result<PlainYearWeek, String> copyWith({
    PlainYear? weekBasedYear,
    int? week,
  }) {
    return PlainYearWeek.from(
      weekBasedYear ?? this.weekBasedYear,
      week ?? this.week,
    );
  }

  @override
  int compareTo(PlainYearWeek other) {
    final result = weekBasedYear.compareTo(other.weekBasedYear);
    if (result != 0) return result;

    return week.compareTo(other.week);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is PlainYearWeek &&
            weekBasedYear == other.weekBasedYear &&
            week == other.week);
  }

  @override
  int get hashCode => Object.hash(weekBasedYear, week);

  @override
  String toString() {
    final week = this.week.toString().padLeft(2, '0');
    return '$weekBasedYear-W$week';
  }

  String toJson() => toString();
}
