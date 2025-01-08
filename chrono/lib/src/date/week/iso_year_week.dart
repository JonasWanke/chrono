import 'package:clock/clock.dart';
import 'package:deranged/deranged.dart';
import 'package:meta/meta.dart';
import 'package:oxidized/oxidized.dart';

import '../../codec.dart';
import '../../date_time/date_time.dart';
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
    implements Comparable<IsoYearWeek>, Step<IsoYearWeek> {
  static Result<IsoYearWeek, String> from(Year weekBasedYear, int week) {
    if (week < 1 || week > weekBasedYear.numberOfIsoWeeks) {
      return Err('Invalid week for year $weekBasedYear: $week');
    }
    return Ok(IsoYearWeek._(weekBasedYear, week));
  }

  static Result<IsoYearWeek, String> fromRaw(int weekBasedYear, int week) =>
      from(Year(weekBasedYear), week);

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

  /// The [Date]s in this month.
  RangeInclusive<Date> get dates {
    return RangeInclusive(
      Date.fromIsoYearWeekAndWeekday(this, Weekday.values.first),
      Date.fromIsoYearWeekAndWeekday(this, Weekday.values.last),
    );
  }

  /// The [DateTime]s in this week.
  Range<CDateTime> get dateTimes => dates.dateTimes;

  IsoYearWeek operator +(Weeks duration) {
    final newDate = dates.start + duration;
    assert(newDate.weekday == Weekday.monday);
    return newDate.isoYearWeek;
  }

  IsoYearWeek operator -(Weeks duration) => this + (-duration);

  IsoYearWeek get next {
    return week == weekBasedYear.numberOfIsoWeeks
        ? (weekBasedYear + const Years(1)).isoWeeks.start
        : IsoYearWeek._(weekBasedYear, week + 1);
  }

  IsoYearWeek get previous {
    return week == 1
        ? (weekBasedYear - const Years(1)).isoWeeks.endInclusive
        : IsoYearWeek._(weekBasedYear, week - 1);
  }

  /// Returns `this - other` as a number of [Weeks].
  Weeks difference(IsoYearWeek other) {
    final (weeks, days) =
        dates.start.differenceInDays(other.dates.start).splitWeeksDays;
    assert(days.isZero);
    return weeks;
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
  IsoYearWeek stepBy(int count) => this + Weeks(count);
  @override
  int stepsUntil(IsoYearWeek other) => other.difference(this).inWeeks;

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

extension RangeOfIsoYearWeekChrono on Range<IsoYearWeek> {
  /// The [Date]s in these weeks.
  RangeInclusive<Date> get dates => inclusive.dates;

  /// The [DateTime]s in these weeks.
  Range<CDateTime> get dateTimes =>
      start.dateTimes.start.rangeUntil(end.dates.start.dateTimes.start);
}

extension RangeInclusiveOfIsoYearWeekChrono on RangeInclusive<IsoYearWeek> {
  /// The [Date]s in these weeks.
  RangeInclusive<Date> get dates =>
      start.dates.start.rangeTo(endInclusive.dates.endInclusive);

  /// The [DateTime]s in these weeks.
  Range<CDateTime> get dateTimes => exclusive.dateTimes;
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
