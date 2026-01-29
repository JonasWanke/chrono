import 'package:meta/meta.dart';

import '../date/duration.dart';
import '../time/duration.dart';

/// Base class for date and time durations.
///
/// This class is called `CDuration` to avoid conflicts with `Duration` from
/// `dart:core`.
///
/// See also:
///
/// - [CalendarDuration], which covers durations based on an integer number of
///   days or months.
/// - [TimeDelta], which covers durations based on a fixed time like seconds.
/// - [CompoundDuration], which combines [CalendarDuration] and [TimeDelta].
@immutable
abstract class CDuration {
  const CDuration();

  CompoundDuration get asCompoundDuration;

  bool get isZero {
    final compoundDuration = asCompoundDuration;
    return compoundDuration.months.inMonths == 0 &&
        compoundDuration.days.inDays == 0 &&
        compoundDuration.time.isZero;
  }

  CDuration operator -();
  CDuration operator *(int factor);
  CDuration operator ~/(int divisor);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! CDuration) return false;

    final thisCompound = asCompoundDuration;
    final otherCompound = other.asCompoundDuration;
    return thisCompound.months.inMonths == otherCompound.months.inMonths &&
        thisCompound.days.inDays == otherCompound.days.inDays &&
        thisCompound.time.totalSeconds == otherCompound.time.totalSeconds &&
        thisCompound.time.subSecondNanos == otherCompound.time.subSecondNanos;
  }

  @override
  int get hashCode {
    final compound = asCompoundDuration;
    return Object.hash(
      compound.months.inMonths,
      compound.days.inDays,
      compound.time.totalSeconds,
      compound.time.subSecondNanos,
    );
  }
}

/// [CDuration] subclass that can represent any duration by combining [Months],
/// [Days], and [TimeDelta].
final class CompoundDuration extends CDuration {
  CompoundDuration({
    CalendarDuration? monthsAndDays,
    MonthsDuration? months,
    DaysDuration? days,
    this.time = const TimeDelta.raw(0, 0),
  }) : assert(
         monthsAndDays == null || (months == null && days == null),
         'Cannot specify both `monthsAndDays` and `months`/`days`.',
       ),
       monthsAndDays =
           monthsAndDays?.asCompoundCalendarDuration ??
           CompoundCalendarDuration(
             months: months?.asMonths ?? const Months(0),
             days: days?.asDays ?? const Days(0),
           );

  final CompoundCalendarDuration monthsAndDays;
  Months get months => monthsAndDays.months;
  Days get days => monthsAndDays.days;
  final TimeDelta time;

  @override
  CompoundDuration get asCompoundDuration => this;

  CompoundDuration operator +(CDuration duration) {
    final CompoundDuration(:monthsAndDays, time: seconds) =
        duration.asCompoundDuration;
    return CompoundDuration(
      monthsAndDays: this.monthsAndDays + monthsAndDays,
      time: time + seconds,
    );
  }

  CompoundDuration operator -(CDuration other) => this + -other;
  @override
  CompoundDuration operator -() =>
      CompoundDuration(monthsAndDays: -monthsAndDays, time: -time);

  @override
  CompoundDuration operator *(int factor) {
    return CompoundDuration(
      monthsAndDays: monthsAndDays * factor,
      time: time * factor,
    );
  }

  @override
  CompoundDuration operator ~/(int divisor) {
    return CompoundDuration(
      monthsAndDays: monthsAndDays ~/ divisor,
      time: time ~/ divisor,
    );
  }

  @override
  String toString() => '$months, $days, $time';
}
