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
import 'week_config.dart';

/// A specific week of a year as defined by a [WeekConfig], e.g., the 16th week
/// of 2023.
///
/// Use [WeekConfig.iso] (e.g., `date.yearWeek(.iso)`) for ISO 8601 weeks.
/// Weeks with different configs can't be compared or subtracted.
///
/// Every week has exactly 7 days and belongs to a week-based year that can
/// differ from the calendar year at its edges. For strftime-style numbering
/// (`%U` and `%W`), where leading days of a year form a partial week 0, see
/// [Date.weekNumberStartingOn] instead.
///
/// https://en.wikipedia.org/wiki/ISO_week_date
@immutable
final class const YearWeek._unchecked(
  final Year weekBasedYear,
  final int week,
  final WeekConfig config,
) with ComparisonOperatorsFromComparable<YearWeek>, StepUnlimited<YearWeek>
    implements Comparable<YearWeek> {
  /// Creates a year week from raw numbers, e.g.,
  /// `YearWeek(2023, 16, WeekConfig.iso)`.
  ///
  /// Throws a [RangeError] if [week] is not valid for the week-based year.
  new(int weekBasedYear, int week, WeekConfig config)
    : this.from(Year(weekBasedYear), week, config);

  /// Creates a year week from typed components, e.g.,
  /// `YearWeek.from(Year(2023), 16, WeekConfig.iso)`.
  ///
  /// Throws a [RangeError] if [week] is not valid for [weekBasedYear].
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

  /// The [Date] of the given [weekday] in this week.
  Date at(Weekday weekday) =>
      dates.start + Days(weekday.indexFrom(config.firstDay));

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
  int differenceInWeeks(YearWeek other) {
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
  int stepsUntil(YearWeek other) => other.differenceInWeeks(this);

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

  /// ISO weeks are formatted as “2023-W16”, others as, e.g.,
  /// “Week 16 of 2023 with WeekConfig(…)”.
  @override
  String toString() {
    if (config == WeekConfig.iso) {
      return '$weekBasedYear-W${week.toString().padLeft(2, '0')}';
    }
    return 'Week $week of $weekBasedYear with $config';
  }

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

/// Encodes an ISO [YearWeek] (see [WeekConfig.iso]) as an ISO 8601 string,
/// e.g., “2023-W16”.
///
/// [encode] throws an [ArgumentError] for weeks with another config.
class const YearWeekAsIsoStringCodec()
    extends CodecAndJsonConverter<YearWeek, String> {
  @override
  String encode(YearWeek input) {
    if (input.config != WeekConfig.iso) {
      throw ArgumentError.value(input, 'input', 'Must be an ISO week.');
    }
    return input.toString();
  }

  @override
  YearWeek decode(String encoded) => Parser.parseIsoYearWeek(encoded);
}
