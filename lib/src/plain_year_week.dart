import 'package:meta/meta.dart';
import 'package:oxidized/oxidized.dart';

import 'parser.dart';
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

  factory PlainYearWeek.fromJson(String json) =>
      unwrapParserResult(parse(json));
  static Result<PlainYearWeek, FormatException> parse(String value) =>
      Parser.parseYearWeek(value);

  final PlainYear weekBasedYear;
  final int week;

  PlainWeekDate get firstDay => PlainWeekDate(this, Weekday.values.first);
  PlainWeekDate get lastDay => PlainWeekDate(this, Weekday.values.last);
  Iterable<PlainWeekDate> get days =>
      Weekday.values.map((weekday) => PlainWeekDate(this, weekday));

  // TODO: arithmetic

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
