import 'package:meta/meta.dart';

import '../duration.dart';
import '../weekday.dart';

/// Defines how weeks are counted within a year.
///
/// A week starts on [firstDay]. Week 1 of a year is the first week that
/// contains at least [minDaysInFirstWeek] days of that year. Days before week 1
/// belong to the last week of the previous year.
///
/// See [iso], [usSunday], and [middleEast] for common configurations.
@immutable
class const WeekConfig._unchecked({
  /// The first day of each week.
  required final Weekday firstDay,

  /// The minimum number of days (from 1 to 7) of a year that the first week
  /// must contain.
  ///
  /// For example, `1` means that the week containing January 1st is week 1,
  /// and `4` means that week 1 is the first week with at least four days in the
  /// new year.
  required final int minDaysInFirstWeek,
}) {
  /// Creates a week configuration.
  ///
  /// Throws a [RangeError] if [minDaysInFirstWeek] isn't between 1 and 7.
  factory from({required Weekday firstDay, required int minDaysInFirstWeek}) {
    RangeError.checkValueInInterval(
      minDaysInFirstWeek,
      1,
      Days.perWeek,
      'minDaysInFirstWeek',
    );
    return WeekConfig._unchecked(
      firstDay: firstDay,
      minDaysInFirstWeek: minDaysInFirstWeek,
    );
  }

  /// ISO 8601: weeks start on Monday, and week 1 contains at least four days
  /// of the year (equivalently, it contains January 4th).
  ///
  /// https://en.wikipedia.org/wiki/ISO_week_date
  static const iso = WeekConfig._unchecked(
    firstDay: .monday,
    minDaysInFirstWeek: 4,
  );

  /// Used in the United States and Canada, among others: weeks start on
  /// Sunday, and week 1 is the week containing January 1st.
  static const usSunday = WeekConfig._unchecked(
    firstDay: .sunday,
    minDaysInFirstWeek: 1,
  );

  /// Used in much of the Middle East: weeks start on Saturday, and week 1 is
  /// the week containing January 1st.
  static const middleEast = WeekConfig._unchecked(
    firstDay: .saturday,
    minDaysInFirstWeek: 1,
  );

  WeekConfig copyWith({Weekday? firstDay, int? minDaysInFirstWeek}) {
    return WeekConfig.from(
      firstDay: firstDay ?? this.firstDay,
      minDaysInFirstWeek: minDaysInFirstWeek ?? this.minDaysInFirstWeek,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is WeekConfig &&
            firstDay == other.firstDay &&
            minDaysInFirstWeek == other.minDaysInFirstWeek);
  }

  @override
  int get hashCode => Object.hash(firstDay, minDaysInFirstWeek);

  @override
  String toString() {
    return 'WeekConfig(firstDay: $firstDay, '
        'minDaysInFirstWeek: $minDaysInFirstWeek)';
  }
}
