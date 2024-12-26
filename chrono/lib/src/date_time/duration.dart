import 'package:meta/meta.dart';

import '../date/duration.dart';
import '../time/duration.dart';

/// Base class for date and time durations.
///
/// See also:
///
/// - [CalendarDuration], which covers durations based on an integer number of days
///   or months.
/// - [TimeDuration], which covers durations based on a fixed time like seconds.
/// - [CompoundDuration], which combines [CalendarDuration] and [TimeDuration].
@immutable
abstract class Duration {
  const Duration();

  CompoundDuration get asCompoundDuration;

  bool get isZero {
    final compoundDuration = asCompoundDuration;
    return compoundDuration.months.inMonths == 0 &&
        compoundDuration.days.inDays == 0 &&
        compoundDuration.seconds.inNanoseconds == BigInt.zero;
  }

  Duration operator -();
  Duration operator *(int factor);
  Duration operator ~/(int divisor);
  Duration operator %(int divisor);
  Duration remainder(int divisor);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Duration) return false;

    final thisCompound = asCompoundDuration;
    final otherCompound = other.asCompoundDuration;
    return thisCompound.months.inMonths == otherCompound.months.inMonths &&
        thisCompound.days.inDays == otherCompound.days.inDays &&
        thisCompound.seconds.inNanoseconds ==
            otherCompound.seconds.inNanoseconds;
  }

  @override
  int get hashCode {
    final compound = asCompoundDuration;
    return Object.hash(
      compound.months.inMonths,
      compound.days.inDays,
      compound.seconds.inNanoseconds,
    );
  }
}

/// [Duration] subclass that can represent any duration by combining [Months],
/// [Days], and [Nanoseconds].
final class CompoundDuration extends Duration {
  CompoundDuration({
    CalendarDuration? monthsAndDays,
    MonthsDuration? months,
    DaysDuration? days,
    TimeDuration? seconds,
  })  : assert(
          monthsAndDays == null || (months == null && days == null),
          'Cannot specify both `monthsAndDays` and `months`/`days`.',
        ),
        monthsAndDays = monthsAndDays?.asCompoundCalendarDuration ??
            CompoundCalendarDuration(
              months: months?.asMonths ?? const Months(0),
              days: days?.asDays ?? const Days(0),
            ),
        seconds = seconds?.asNanoseconds ?? Nanoseconds(0);

  final CompoundCalendarDuration monthsAndDays;
  Months get months => monthsAndDays.months;
  Days get days => monthsAndDays.days;
  // TODO(JonasWanke): Rename, maybe to `time` or `nanoseconds`
  final Nanoseconds seconds;

  @override
  CompoundDuration get asCompoundDuration => this;

  CompoundDuration operator +(Duration duration) {
    final CompoundDuration(:monthsAndDays, :seconds) =
        duration.asCompoundDuration;
    return CompoundDuration(
      monthsAndDays: this.monthsAndDays + monthsAndDays,
      seconds: this.seconds + seconds,
    );
  }

  CompoundDuration operator -(Duration other) => this + -other;
  @override
  CompoundDuration operator -() =>
      CompoundDuration(monthsAndDays: -monthsAndDays, seconds: -seconds);

  @override
  CompoundDuration operator *(int factor) {
    return CompoundDuration(
      monthsAndDays: monthsAndDays * factor,
      seconds: seconds * factor,
    );
  }

  @override
  CompoundDuration operator ~/(int divisor) {
    return CompoundDuration(
      monthsAndDays: monthsAndDays ~/ divisor,
      seconds: seconds ~/ divisor,
    );
  }

  @override
  CompoundDuration operator %(int divisor) {
    return CompoundDuration(
      monthsAndDays: monthsAndDays % divisor,
      seconds: seconds % divisor,
    );
  }

  @override
  CompoundDuration remainder(int divisor) {
    return CompoundDuration(
      monthsAndDays: monthsAndDays.remainder(divisor),
      seconds: seconds.remainder(divisor),
    );
  }

  @override
  String toString() => '$months, $days, $seconds';
}
