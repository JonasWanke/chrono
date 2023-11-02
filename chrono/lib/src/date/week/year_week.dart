import 'dart:core';
import 'dart:core' as core;

import 'package:clock/clock.dart';
import 'package:meta/meta.dart';
import 'package:oxidized/oxidized.dart';

import '../../date_time/date_time.dart';
import '../../parser.dart';
import '../../utils.dart';
import '../duration.dart';
import '../weekday.dart';
import '../year.dart';
import 'week_date.dart';

@immutable
final class YearWeek
    with ComparisonOperatorsFromComparable<YearWeek>
    implements Comparable<YearWeek> {
  static Result<YearWeek, String> from(Year weekBasedYear, int week) {
    if (week < 0 || week > weekBasedYear.numberOfWeeks) {
      return Err('Invalid week for year $weekBasedYear: $week');
    }
    return Ok(YearWeek._(weekBasedYear, week));
  }

  const YearWeek._(this.weekBasedYear, this.week);

  factory YearWeek.currentInLocalZone({Clock? clock}) =>
      DateTime.nowInLocalZone(clock: clock).date.yearWeek;
  factory YearWeek.currentInUtc({Clock? clock}) =>
      DateTime.nowInUtc(clock: clock).date.yearWeek;

  factory YearWeek.fromJson(String json) => unwrapParserResult(parse(json));
  static Result<YearWeek, FormatException> parse(String value) =>
      Parser.parseYearWeek(value);

  final Year weekBasedYear;
  final int week;

  bool isCurrentInLocalZone({Clock? clock}) =>
      this == YearWeek.currentInLocalZone(clock: clock);
  bool isCurrentInUtc({Clock? clock}) =>
      this == YearWeek.currentInUtc(clock: clock);

  WeekDate get firstDay => WeekDate(this, Weekday.values.first);
  WeekDate get lastDay => WeekDate(this, Weekday.values.last);
  Iterable<WeekDate> get days =>
      Weekday.values.map((weekday) => WeekDate(this, weekday));

  YearWeek operator +(Weeks duration) {
    final newDate = WeekDate(this, Weekday.monday).asDate + duration;
    assert(newDate.weekday == Weekday.monday);
    return newDate.yearWeek;
  }

  YearWeek operator -(Weeks duration) => this + (-duration);

  YearWeek get next {
    return week == weekBasedYear.numberOfWeeks
        ? (weekBasedYear + const Years(1)).firstWeek
        : YearWeek._(weekBasedYear, week + 1);
  }

  YearWeek get previous {
    return week == 1
        ? (weekBasedYear - const Years(1)).lastWeek
        : YearWeek._(weekBasedYear, week - 1);
  }

  Result<YearWeek, String> copyWith({Year? weekBasedYear, int? week}) {
    return YearWeek.from(
      weekBasedYear ?? this.weekBasedYear,
      week ?? this.week,
    );
  }

  @override
  int compareTo(YearWeek other) {
    final result = weekBasedYear.compareTo(other.weekBasedYear);
    if (result != 0) return result;

    return week.compareTo(other.week);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is YearWeek &&
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
