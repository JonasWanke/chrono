import 'package:clock/clock.dart';
import 'package:deranged/deranged.dart';
import 'package:meta/meta.dart';

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
final class const IsoYearWeek._unchecked(
  final Year weekBasedYear,
  final int week,
) with
        ComparisonOperatorsFromComparable<IsoYearWeek>,
        StepUnlimited<IsoYearWeek>
    implements Comparable<IsoYearWeek> {
  new from(Year weekBasedYear, int week)
    : this._unchecked(
        weekBasedYear,
        RangeError.checkValueInInterval(
          week,
          1,
          weekBasedYear.numberOfIsoWeeks,
          'week',
          'Invalid week for year $weekBasedYear.',
        ),
      );
  new fromRaw(int weekBasedYear, int week)
    : this.from(Year(weekBasedYear), week);

  factory currentInLocalZone({Clock? clock}) =>
      Date.todayInLocalZone(clock: clock).isoYearWeek;
  factory currentInUtc({Clock? clock}) =>
      Date.todayInUtc(clock: clock).isoYearWeek;

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

  IsoYearWeek operator +(int weeks) {
    final newDate = dates.start + Days.fromWeeks(weeks);
    assert(newDate.weekday == Weekday.monday);
    return newDate.isoYearWeek;
  }

  IsoYearWeek operator -(int weeks) => this + (-weeks);

  @override
  IsoYearWeek get next {
    return week == weekBasedYear.numberOfIsoWeeks
        ? (weekBasedYear + 1).isoWeeks.start
        : IsoYearWeek._unchecked(weekBasedYear, week + 1);
  }

  @override
  IsoYearWeek get previous {
    return week == 1
        ? (weekBasedYear - 1).isoWeeks.end
        : IsoYearWeek._unchecked(weekBasedYear, week - 1);
  }

  /// Returns `this - other` as a number of weeks.
  // ignore: lines_longer_than_80_chars
  // TODO(JonasWanke): rename to `differenceInWeeks`, add `differenceInYearAndWeeks`
  int difference(IsoYearWeek other) {
    final difference = dates.start.daysSince(other.dates.start);
    assert(difference.isMultipleOf(.weeks));
    return difference.roundTo(.weeks);
  }

  IsoYearWeek copyWith({Year? weekBasedYear, int? week}) {
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
  IsoYearWeek stepBy(int count) => this + count;
  @override
  int stepsUntil(IsoYearWeek other) => other.difference(this);

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
  RangeInclusive<Date> get dates => start.dates.start.rangeTo(end.dates.end);

  /// The [DateTime]s in these weeks.
  Range<CDateTime> get dateTimes => exclusive.dateTimes;
}

/// Encodes a [IsoYearWeek] as an ISO 8601 string, e.g., “2023-W16”.
class const IsoYearWeekAsIsoStringCodec()
    extends CodecAndJsonConverter<IsoYearWeek, String> {
  @override
  String encode(IsoYearWeek input) => input.toString();
  @override
  IsoYearWeek decode(String encoded) => Parser.parseIsoYearWeek(encoded);
}
