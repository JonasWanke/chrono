import 'package:meta/meta.dart';

import 'period_days.dart';
import 'period_time.dart';

@immutable
abstract class Period {
  const Period();

  CompoundPeriod get inMonthsAndDaysAndSeconds;

  Period operator -();
  Period operator *(int factor);
}

final class CompoundPeriod extends Period {
  const CompoundPeriod(this.months, this.days, this.seconds);

  final Months months;
  final Days days;
  final Seconds seconds;

  @override
  CompoundPeriod get inMonthsAndDaysAndSeconds => this;

  @override
  CompoundPeriod operator -() => CompoundPeriod(-months, -days, -seconds);

  @override
  CompoundPeriod operator *(int factor) =>
      CompoundPeriod(months * factor, days * factor, seconds * factor);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CompoundPeriod &&
          months == other.months &&
          days == other.days &&
          seconds == other.seconds);
  @override
  int get hashCode => Object.hash(months, days, seconds);

  @override
  String toString() => '$months, $days, $seconds';
}
