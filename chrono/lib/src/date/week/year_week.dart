import 'dart:core' as core;
import 'dart:core';

import 'package:clock/clock.dart';
import 'package:meta/meta.dart';
import 'package:oxidized/oxidized.dart';

import '../../utils.dart';
import '../date.dart';
import '../duration.dart';
import '../weekday.dart';
import '../year.dart';
import 'week_config.dart';

/// A specific week of a year as defined by a [WeekConfig], e.g., the 16th week
/// of 2023.
// TODO(JonasWanke): more docs and comparison to [IsoYearWeek]
@immutable
final class YearWeek
    with ComparisonOperatorsFromComparable<YearWeek>
    implements Comparable<YearWeek> {
  static Result<YearWeek, String> from(
    Year weekBasedYear,
    int week,
    WeekConfig config,
  ) {
    if (week < 1 || week > weekBasedYear.numberOfWeeks(config)) {
      return Err('Invalid week for year $weekBasedYear: $week');
    }
    return Ok(YearWeek._(weekBasedYear, week, config));
  }

  const YearWeek._(this.weekBasedYear, this.week, this.config);

  factory YearWeek.currentInLocalZone(WeekConfig config, {Clock? clock}) =>
      Date.todayInLocalZone(clock: clock).yearWeek(config);
  factory YearWeek.currentInUtc(WeekConfig config, {Clock? clock}) =>
      Date.todayInUtc(clock: clock).yearWeek(config);

  final Year weekBasedYear;
  final int week;
  final WeekConfig config;

  bool isCurrentInLocalZone({Clock? clock}) =>
      this == YearWeek.currentInLocalZone(config, clock: clock);
  bool isCurrentInUtc({Clock? clock}) =>
      this == YearWeek.currentInUtc(config, clock: clock);

  Date get firstDay =>
      weekBasedYear.firstDayOfWeekBasedYear(config) + Weeks(week - 1);
  Date get lastDay => firstDay + const Days(Days.perWeek - 1);
  Iterable<Date> get days {
    final firstDay = this.firstDay;
    return Weekday.values.map((weekday) => firstDay + Days(weekday.index));
  }

  YearWeek operator +(Weeks duration) {
    final newDate = firstDay + duration;
    assert(newDate.weekday == config.firstDay);
    return newDate.yearWeek(config);
  }

  YearWeek operator -(Weeks duration) => this + (-duration);

  YearWeek get next {
    return week == weekBasedYear.numberOfWeeks(config)
        ? (weekBasedYear + const Years(1)).firstWeek(config)
        : YearWeek._(weekBasedYear, week + 1, config);
  }

  YearWeek get previous {
    return week == 1
        ? (weekBasedYear - const Years(1)).lastWeek(config)
        : YearWeek._(weekBasedYear, week - 1, config);
  }

  Result<YearWeek, String> copyWith({
    Year? weekBasedYear,
    int? week,
    WeekConfig? config,
  }) {
    return YearWeek.from(
      weekBasedYear ?? this.weekBasedYear,
      week ?? this.week,
      config ?? this.config,
    );
  }

  @override
  int compareTo(YearWeek other) {
    assert(config == other.config);

    final result = weekBasedYear.compareTo(other.weekBasedYear);
    if (result != 0) return result;

    return week.compareTo(other.week);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is YearWeek &&
            weekBasedYear == other.weekBasedYear &&
            week == other.week &&
            config == other.config);
  }

  @override
  int get hashCode => Object.hash(weekBasedYear, week, config);

  @override
  String toString() => 'Week $week of $weekBasedYear with $config';
}
