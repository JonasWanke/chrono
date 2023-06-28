import 'package:meta/meta.dart';

import '../date/duration.dart';
import '../time/duration.dart';

@immutable
abstract class Duration {
  const Duration();

  CompoundDuration get inMonthsAndDaysAndSeconds;

  Duration operator -();
  Duration operator *(int factor);
  Duration operator ~/(int divisor);
  Duration operator %(int divisor);
  Duration remainder(int divisor);
}

final class CompoundDuration extends Duration {
  CompoundDuration(
    this.months, [
    this.days = const Days(0),
    FractionalSeconds? seconds,
  ]) : seconds = seconds ?? FractionalSeconds.zero;

  final Months months;
  final Days days;
  final FractionalSeconds seconds;

  @override
  CompoundDuration get inMonthsAndDaysAndSeconds => this;

  @override
  CompoundDuration operator -() => CompoundDuration(-months, -days, -seconds);

  @override
  CompoundDuration operator *(int factor) =>
      CompoundDuration(months * factor, days * factor, seconds * factor);
  @override
  CompoundDuration operator ~/(int divisor) =>
      CompoundDuration(months ~/ divisor, days ~/ divisor, seconds ~/ divisor);
  @override
  CompoundDuration operator %(int divisor) =>
      CompoundDuration(months % divisor, days % divisor, seconds % divisor);
  @override
  CompoundDuration remainder(int divisor) {
    return CompoundDuration(
      months.remainder(divisor),
      days.remainder(divisor),
      seconds.remainder(divisor),
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
