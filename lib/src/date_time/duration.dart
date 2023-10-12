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
}

final class CompoundDuration extends Duration {
  CompoundDuration({
    CompoundDaysDuration? monthsAndDays,
    Months? months,
    Days? days,
    FractionalSeconds? seconds,
  })  : assert(
          monthsAndDays == null || (months == null && days == null),
          'Cannot specify both `monthsAndDays` and `months`/`days`.',
        ),
        monthsAndDays = monthsAndDays ??
            CompoundDaysDuration(
              months: months ?? const Months(0),
              days: days ?? const Days(0),
            ),
        seconds = seconds ?? FractionalSeconds.zero;

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
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is CompoundDuration &&
            months == other.months &&
            days == other.days &&
            seconds == other.seconds);
  }

  @override
  int get hashCode => Object.hash(months, days, seconds);

  @override
  String toString() => '$months, $days, $seconds';
}
