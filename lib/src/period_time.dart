import 'period.dart';
import 'period_days.dart';
import 'utils.dart';

abstract class TimePeriod extends Period
    with ComparisonOperatorsFromComparable<TimePeriod>
    implements Comparable<TimePeriod> {
  const TimePeriod();

  Seconds get inSeconds;

  @override
  CompoundPeriod get inMonthsAndDaysAndSeconds =>
      CompoundPeriod(const Months(0), const Days(0), inSeconds);

  bool get isPositive => inSeconds.value > 0;
  bool get isNonPositive => inSeconds.value <= 0;
  bool get isNegative => inSeconds.value < 0;
  bool get isNonNegative => inSeconds.value >= 0;

  @override
  TimePeriod operator -();
  @override
  TimePeriod operator *(int factor);

  @override
  int compareTo(TimePeriod other) =>
      inSeconds.value.compareTo(other.inSeconds.value);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Seconds && inSeconds.value == other.inSeconds.value);
  @override
  int get hashCode => inSeconds.value.hashCode;
}

final class Seconds extends TimePeriod {
  const Seconds(this.value);

  static const perMinute = Seconds(Duration.secondsPerMinute);
  static const perHour = Seconds(Duration.secondsPerHour);
  static const perDay = Seconds(Duration.secondsPerDay);

  final int value;

  @override
  Seconds get inSeconds => this;

  Seconds operator +(TimePeriod period) =>
      Seconds(value + period.inSeconds.value);
  Seconds operator -(TimePeriod period) =>
      Seconds(value - period.inSeconds.value);
  @override
  Seconds operator -() => Seconds(-value);
  @override
  Seconds operator *(int factor) => Seconds(value * factor);

  @override
  String toString() => value.abs() == 1 ? '$value second' : '$value seconds';
}

abstract class MinutesPeriod extends TimePeriod {
  const MinutesPeriod();

  Minutes get inMinutes;

  @override
  Seconds get inSeconds => inMinutes.inSeconds;

  @override
  MinutesPeriod operator -();
  @override
  MinutesPeriod operator *(int factor);
}

final class Minutes extends MinutesPeriod {
  const Minutes(this.value);

  static const perHour = Minutes(Duration.minutesPerHour);
  static const perDay = Minutes(Duration.minutesPerDay);

  final int value;

  @override
  Minutes get inMinutes => this;

  Minutes operator +(MinutesPeriod period) =>
      Minutes(value + period.inMinutes.value);
  Minutes operator -(MinutesPeriod period) =>
      Minutes(value - period.inMinutes.value);
  @override
  Minutes operator -() => Minutes(-value);
  @override
  Minutes operator *(int factor) => Minutes(value * factor);

  @override
  String toString() => value.abs() == 1 ? '$value minute' : '$value minutes';
}

final class Hours extends MinutesPeriod {
  const Hours(this.value);

  static const perDay = Hours(Duration.hoursPerDay);

  final int value;

  @override
  Minutes get inMinutes => Minutes.perHour * value;

  Hours operator +(Hours period) => Hours(value + period.value);
  Hours operator -(Hours period) => Hours(value - period.value);
  @override
  Hours operator -() => Hours(-value);
  @override
  Hours operator *(int factor) => Hours(value * factor);

  @override
  String toString() => value.abs() == 1 ? '$value hour' : '$value hours';
}
