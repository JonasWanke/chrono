import 'package:meta/meta.dart';

import '../date/period.dart';
import '../time/period.dart';

@immutable
abstract class Period {
  const Period();

  CompoundPeriod get inMonthsAndDaysAndSeconds;

  Period operator -();
  Period operator *(int factor);
  Period operator ~/(int divisor);
  Period operator %(int divisor);
  Period remainder(int divisor);
}

final class CompoundPeriod extends Period {
  CompoundPeriod(
    this.months, [
    this.days = const Days(0),
    FractionalSeconds? seconds,
  ]) : seconds = seconds ?? FractionalSeconds.zero;

  final Months months;
  final Days days;
  final FractionalSeconds seconds;

  @override
  CompoundPeriod get inMonthsAndDaysAndSeconds => this;

  @override
  CompoundPeriod operator -() => CompoundPeriod(-months, -days, -seconds);

  @override
  CompoundPeriod operator *(int factor) =>
      CompoundPeriod(months * factor, days * factor, seconds * factor);
  @override
  CompoundPeriod operator ~/(int divisor) =>
      CompoundPeriod(months ~/ divisor, days ~/ divisor, seconds ~/ divisor);
  @override
  CompoundPeriod operator %(int divisor) =>
      CompoundPeriod(months % divisor, days % divisor, seconds % divisor);
  @override
  CompoundPeriod remainder(int divisor) {
    return CompoundPeriod(
      months.remainder(divisor),
      days.remainder(divisor),
      seconds.remainder(divisor),
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is CompoundPeriod &&
            months == other.months &&
            days == other.days &&
            seconds == other.seconds);
  }

  @override
  int get hashCode => Object.hash(months, days, seconds);

  @override
  String toString() => '$months, $days, $seconds';
}
