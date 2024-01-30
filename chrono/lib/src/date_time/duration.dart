import 'package:meta/meta.dart';

import '../date/duration.dart';
import '../time/duration.dart';

@immutable
abstract class Duration {
  const Duration();

  CompoundDuration get asCompoundDuration;

  bool get isZero {
    final compoundDuration = asCompoundDuration;
    return compoundDuration.months.inMonths == 0 &&
        compoundDuration.days.inDays == 0 &&
        compoundDuration.seconds.inFractionalSeconds.isZero;
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
        thisCompound.seconds.inFractionalSeconds ==
            otherCompound.seconds.inFractionalSeconds;
  }

  @override
  int get hashCode {
    final compound = asCompoundDuration;
    return Object.hash(
      compound.months.inMonths,
      compound.days.inDays,
      compound.seconds.inFractionalSeconds,
    );
  }
}

final class CompoundDuration extends Duration {
  CompoundDuration({
    DaysDuration? monthsAndDays,
    MonthsDuration? months,
    FixedDaysDuration? days,
    TimeDuration? seconds,
  })  : assert(
          monthsAndDays == null || (months == null && days == null),
          'Cannot specify both `monthsAndDays` and `months`/`days`.',
        ),
        monthsAndDays = monthsAndDays?.asCompoundDaysDuration ??
            CompoundDaysDuration(
              months: months?.asMonths ?? const Months(0),
              days: days?.asDays ?? const Days(0),
            ),
        seconds = seconds?.asFractionalSeconds ?? FractionalSeconds.zero;

  final CompoundDaysDuration monthsAndDays;
  Months get months => monthsAndDays.months;
  Days get days => monthsAndDays.days;
  final FractionalSeconds seconds;

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
