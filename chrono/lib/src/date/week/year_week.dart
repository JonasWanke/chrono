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
final class YearWeek
    with ComparisonOperatorsFromComparable<YearWeek>
    implements Comparable<YearWeek>, Step<YearWeek> {
  YearWeek.from(Year weekBasedYear, int week, WeekConfig config)
    : this._unchecked(
        weekBasedYear,
        RangeError.checkValueInInterval(
          week,
          1,
          weekBasedYear.numberOfWeeks(config),
          'Invalid week for year $weekBasedYear.',
        ),
        config,
      );
  YearWeek.fromRaw(int weekBasedYear, int week, WeekConfig config)
    : this.from(Year(weekBasedYear), week, config);
  const YearWeek._unchecked(this.weekBasedYear, this.week, this.config);

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

  /// The [Date]s in this week.
  RangeInclusive<Date> get dates {
    final firstDay =
        weekBasedYear.firstDayOfWeekBasedYear(config) + Weeks(week - 1);
    return RangeInclusive(firstDay, firstDay + const Days(Days.perWeek - 1));
  }

  /// The [DateTime]s in this week.
  Range<CDateTime> get dateTimes => dates.dateTimes;

  YearWeek operator +(Weeks duration) {
    final newDate = dates.start + duration;
    assert(newDate.weekday == config.firstDay);
    return newDate.yearWeek(config);
  }

  YearWeek operator -(Weeks duration) => this + (-duration);

  YearWeek get next {
    return week == weekBasedYear.numberOfWeeks(config)
        ? (weekBasedYear + const Years(1)).weeks(config).start
        : YearWeek._unchecked(weekBasedYear, week + 1, config);
  }

  YearWeek get previous {
    return week == 1
        ? (weekBasedYear - const Years(1)).weeks(config).endInclusive
        : YearWeek._unchecked(weekBasedYear, week - 1, config);
  }

  /// Returns `this - other` as a number of [Weeks].
  ///
  /// Both [YearWeek]s must have the same [config].
  Weeks difference(YearWeek other) {
    assert(config == other.config);

    final (weeks, days) = dates.start
        .differenceInDays(other.dates.start)
        .splitWeeksDays;
    assert(days.isZero);
    return weeks;
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
    assert(config == other.config);

    final result = weekBasedYear.compareTo(other.weekBasedYear);
    if (result != 0) return result;

    return week.compareTo(other.week);
  }

  @override
  YearWeek stepBy(int count) => this + Weeks(count);
  @override
  int stepsUntil(YearWeek other) => other.difference(this).inWeeks;

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

extension RangeOfYearWeekChrono on Range<YearWeek> {
  /// The [Date]s in these weeks.
  RangeInclusive<Date> get dates => inclusive.dates;

  /// The [DateTime]s in these weeks.
  Range<CDateTime> get dateTimes => dates.dateTimes;
}

extension RangeInclusiveOfYearWeekChrono on RangeInclusive<YearWeek> {
  /// The [Date]s in these weeks.
  RangeInclusive<Date> get dates =>
      start.dates.start.rangeTo(endInclusive.dates.endInclusive);

  /// The [DateTime]s in these weeks.
  Range<CDateTime> get dateTimes => exclusive.dateTimes;
}
