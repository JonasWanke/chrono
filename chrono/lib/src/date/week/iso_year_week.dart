import 'dart:core' as core;
import 'dart:core';

import 'package:clock/clock.dart';
import 'package:meta/meta.dart';
import 'package:oxidized/oxidized.dart';

import '../../codec.dart';
import '../../parser.dart';
import '../../utils.dart';
import '../date.dart';
import '../duration.dart';
import '../weekday.dart';
import '../year.dart';

/// A specific week of a year, e.g., the 16th week of 2023.
///
/// https://en.wikipedia.org/wiki/ISO_week_date
@immutable
final class IsoYearWeek
    with ComparisonOperatorsFromComparable<IsoYearWeek>
    implements Comparable<IsoYearWeek> {
  static Result<IsoYearWeek, String> from(Year weekBasedYear, int week) {
    if (week < 1 || week > weekBasedYear.numberOfIsoWeeks) {
      return Err('Invalid week for year $weekBasedYear: $week');
    }
    return Ok(IsoYearWeek._(weekBasedYear, week));
  }

  const IsoYearWeek._(this.weekBasedYear, this.week);

  factory IsoYearWeek.currentInLocalZone({Clock? clock}) =>
      Date.todayInLocalZone(clock: clock).isoYearWeek;
  factory IsoYearWeek.currentInUtc({Clock? clock}) =>
      Date.todayInUtc(clock: clock).isoYearWeek;

  final Year weekBasedYear;
  final int week;

  bool isCurrentInLocalZone({Clock? clock}) =>
      this == IsoYearWeek.currentInLocalZone(clock: clock);
  bool isCurrentInUtc({Clock? clock}) =>
      this == IsoYearWeek.currentInUtc(clock: clock);

  Date get firstDay =>
      Date.fromIsoYearWeekAndWeekday(this, Weekday.values.first);
  Date get lastDay => Date.fromIsoYearWeekAndWeekday(this, Weekday.values.last);
  Iterable<Date> get days {
    final firstDay = this.firstDay;
    return Weekday.values.map((weekday) => firstDay + Days(weekday.index));
  }

  IsoYearWeek operator +(Weeks duration) {
    final newDate = firstDay + duration;
    assert(newDate.weekday == Weekday.monday);
    return newDate.isoYearWeek;
  }

  IsoYearWeek operator -(Weeks duration) => this + (-duration);

  IsoYearWeek get next {
    return week == weekBasedYear.numberOfIsoWeeks
        ? (weekBasedYear + const Years(1)).firstIsoWeek
        : IsoYearWeek._(weekBasedYear, week + 1);
  }

  IsoYearWeek get previous {
    return week == 1
        ? (weekBasedYear - const Years(1)).lastIsoWeek
        : IsoYearWeek._(weekBasedYear, week - 1);
  }

  Result<IsoYearWeek, String> copyWith({Year? weekBasedYear, int? week}) {
    return IsoYearWeek.from(
      weekBasedYear ?? this.weekBasedYear,
      week ?? this.week,
    );
  }

  @override
  int compareTo(IsoYearWeek other) {
    final result = weekBasedYear.compareTo(other.weekBasedYear);
    if (result != 0) return result;

    return week.compareTo(other.week);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is IsoYearWeek &&
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
}

/// Encodes a [IsoYearWeek] as an ISO 8601 string, e.g., “2023-W16”.
class IsoYearWeekAsIsoStringCodec
    extends CodecWithParserResult<IsoYearWeek, String> {
  const IsoYearWeekAsIsoStringCodec();

  @override
  String encode(IsoYearWeek input) => input.toString();
  @override
  Result<IsoYearWeek, FormatException> decodeAsResult(String encoded) =>
      Parser.parseIsoYearWeek(encoded);
}
