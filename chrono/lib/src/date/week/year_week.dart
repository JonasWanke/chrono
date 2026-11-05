import 'package:clock/clock.dart';
import 'package:deranged/deranged.dart';
import 'package:meta/meta.dart';

import '../../date_time/date_time.dart';
import '../../utils.dart';
import '../date.dart';
import '../duration.dart';
import '../year.dart';
import 'week_config.dart';

/// A specific week of a year as defined by a [WeekConfig], e.g., the 16th week
/// of 2023.
// TODO(JonasWanke): more docs and comparison to [IsoYearWeek]
@immutable
final class const YearWeek._unchecked(
  final Year weekBasedYear,
  final int week,
  final WeekConfig config,
) with ComparisonOperatorsFromComparable<YearWeek>, StepUnlimited<YearWeek>
    implements Comparable<YearWeek> {
  new from(Year weekBasedYear, int week, WeekConfig config)
    : this._unchecked(
        weekBasedYear,
        RangeError.checkValueInInterval(
          week,
          1,
          weekBasedYear.numberOfWeeks(config),
          'week',
          'Invalid week for year $weekBasedYear.',
        ),
        config,
      );
  new fromRaw(int weekBasedYear, int week, WeekConfig config)
    : this.from(Year(weekBasedYear), week, config);

  factory currentInLocalZone(WeekConfig config, {Clock? clock}) =>
      Date.todayInLocalZone(clock: clock).yearWeek(config);
  factory currentInUtc(WeekConfig config, {Clock? clock}) =>
      Date.todayInUtc(clock: clock).yearWeek(config);

  bool isCurrentInLocalZone({Clock? clock}) =>
      this == YearWeek.currentInLocalZone(config, clock: clock);
  bool isCurrentInUtc({Clock? clock}) =>
      this == YearWeek.currentInUtc(config, clock: clock);

  /// The [Date]s in this week.
  RangeInclusive<Date> get dates {
    final firstDay =
        weekBasedYear.firstDayOfWeekBasedYear(config) +
        Days.fromWeeks(week - 1);
    return RangeInclusive(firstDay, firstDay + const Days(Days.perWeek - 1));
  }

  /// The [DateTime]s in this week.
  Range<CDateTime> get dateTimes => dates.dateTimes;

  YearWeek operator +(int weeks) {
    final newDate = dates.start + Days.fromWeeks(weeks);
    assert(newDate.weekday == config.firstDay);
    return newDate.yearWeek(config);
  }

  YearWeek operator -(int weeks) => this + (-weeks);

  @override
  YearWeek get next {
    return week == weekBasedYear.numberOfWeeks(config)
        ? (weekBasedYear + 1).weeks(config).start
        : YearWeek._unchecked(weekBasedYear, week + 1, config);
  }

  @override
  YearWeek get previous {
    return week == 1
        ? (weekBasedYear - 1).weeks(config).end
        : YearWeek._unchecked(weekBasedYear, week - 1, config);
  }

  /// Returns `this - other` as a number of weeks.
  ///
  /// Both [YearWeek]s must have the same [config], otherwise an
  /// [ArgumentError] is thrown.
  // ignore: lines_longer_than_80_chars
  // TODO(JonasWanke): rename to `differenceInWeeks`, add `differenceInYearAndWeeks`
  int difference(YearWeek other) {
    _checkSameConfig(other);

    final difference = dates.start.daysSince(other.dates.start);
    assert(difference.isMultipleOf(.weeks));
    return difference.roundTo(.weeks);
  }

  YearWeek copyWith({Year? weekBasedYear, int? week, WeekConfig? config}) {
    return YearWeek.from(
      weekBasedYear ?? this.weekBasedYear,
      week ?? this.week,
      config ?? this.config,
    );
  }

  @override
  int compareTo(YearWeek other) {
    _checkSameConfig(other);

    final result = weekBasedYear.compareTo(other.weekBasedYear);
    if (result != 0) return result;

    return week.compareTo(other.week);
  }

  @override
  YearWeek stepBy(int count) => this + count;
  @override
  int stepsUntil(YearWeek other) => other.difference(this);

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

  void _checkSameConfig(YearWeek other) {
    if (config != other.config) {
      throw ArgumentError.value(
        other,
        'other',
        'Must have the same config as $this.',
      );
    }
  }
}

extension RangeOfYearWeekChrono on Range<YearWeek> {
  /// The [Date]s in these weeks.
  RangeInclusive<Date> get dates => inclusive.dates;

  /// The [DateTime]s in these weeks.
  Range<CDateTime> get dateTimes => dates.dateTimes;
}

extension RangeInclusiveOfYearWeekChrono on RangeInclusive<YearWeek> {
  /// The [Date]s in these weeks.
  RangeInclusive<Date> get dates => start.dates.start.rangeTo(end.dates.end);

  /// The [DateTime]s in these weeks.
  Range<CDateTime> get dateTimes => exclusive.dateTimes;
}
