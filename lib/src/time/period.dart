import 'package:fixed/fixed.dart';

import '../date/period.dart';
import '../date_time/period.dart';
import '../utils.dart';

abstract class TimePeriod extends Period
    with ComparisonOperatorsFromComparable<TimePeriod>
    implements Comparable<TimePeriod> {
  const TimePeriod();

  FractionalSeconds get inFractionalSeconds;
  (Seconds, FractionalSeconds) get inSecondsAndFraction {
    final (seconds, fraction) =
        inFractionalSeconds.value.integerAndDecimalParts;
    return (Seconds(seconds.toInt()), FractionalSeconds(fraction));
  }

  @override
  CompoundPeriod get inMonthsAndDaysAndSeconds =>
      CompoundPeriod(const Months(0), const Days(0), inFractionalSeconds);

  bool get isPositive => inFractionalSeconds.value.isPositive;
  bool get isNonPositive => !isPositive;
  bool get isNegative => inFractionalSeconds.value.isNegative;
  bool get isNonNegative => !isNegative;

  @override
  TimePeriod operator -();
  @override
  TimePeriod operator *(int factor);
  @override
  TimePeriod operator ~/(int divisor);
  @override
  TimePeriod operator %(int divisor);
  @override
  TimePeriod remainder(int divisor);

  @override
  int compareTo(TimePeriod other) =>
      inFractionalSeconds.value.compareTo(other.inFractionalSeconds.value);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Seconds &&
          inFractionalSeconds.value == other.inFractionalSeconds.value);
  @override
  int get hashCode => inFractionalSeconds.value.hashCode;
}

final class FractionalSeconds extends TimePeriod {
  const FractionalSeconds(this.value);

  // `Fixed.zero` has a scale of 16, which we don't need.
  static final zero = FractionalSeconds(Fixed.fromInt(0, scale: 0));

  static final nanosecond = FractionalSeconds(Fixed.fromInt(1, scale: 9));
  static final microsecond = FractionalSeconds(Fixed.fromInt(1, scale: 6));
  static final millisecond = FractionalSeconds(Fixed.fromInt(1, scale: 3));
  static final second = FractionalSeconds(Fixed.fromInt(1, scale: 0));
  static final perMinute = Seconds.perMinute.inFractionalSeconds;
  static final perHour = Seconds.perHour.inFractionalSeconds;
  static final perDay = Seconds.perDay.inFractionalSeconds;
  static final perWeek = Seconds.perWeek.inFractionalSeconds;

  final Fixed value;

  int get inNanosecondsRounded => Fixed.copyWith(value, scale: 9).toInt();
  int get inMicrosecondsRounded => Fixed.copyWith(value, scale: 6).toInt();
  int get inMillisecondsRounded => Fixed.copyWith(value, scale: 3).toInt();

  @override
  FractionalSeconds get inFractionalSeconds => this;

  FractionalSeconds operator +(TimePeriod period) =>
      FractionalSeconds(value + period.inFractionalSeconds.value);
  FractionalSeconds operator -(TimePeriod period) =>
      FractionalSeconds(value - period.inFractionalSeconds.value);
  @override
  FractionalSeconds operator -() => FractionalSeconds(-value);
  @override
  FractionalSeconds operator *(int factor) =>
      FractionalSeconds(value * Fixed.fromInt(factor, scale: 0));
  @override
  FractionalSeconds operator ~/(int divisor) =>
      FractionalSeconds(value ~/ Fixed.fromInt(divisor, scale: 0));
  @override
  FractionalSeconds operator %(int divisor) =>
      FractionalSeconds(value % Fixed.fromInt(divisor, scale: 0));
  @override
  FractionalSeconds remainder(int divisor) =>
      FractionalSeconds(value.remainder(Fixed.fromInt(divisor, scale: 0)));

  @override
  String toString() =>
      value.abs == Fixed.one ? '$value second' : '$value seconds';
}

abstract class SecondsPeriod extends TimePeriod {
  const SecondsPeriod();

  Seconds get inSeconds;
  (Minutes, Seconds) get inMinutesAndSeconds {
    final inSeconds = this.inSeconds;
    final minutes = Minutes(inSeconds.value ~/ Seconds.perMinute.value);
    final seconds = inSeconds.remainder(Seconds.perMinute.value);
    return (minutes, seconds);
  }

  (Hours, Minutes, Seconds) get inHoursAndMinutesAndSeconds {
    final (inMinutes, seconds) = inMinutesAndSeconds;
    final (hours, minutes) = inMinutes.inHoursAndMinutes;
    return (hours, minutes, seconds);
  }

  @override
  FractionalSeconds get inFractionalSeconds =>
      FractionalSeconds.second * inSeconds.value;

  @override
  SecondsPeriod operator -();
  @override
  SecondsPeriod operator *(int factor);
  @override
  SecondsPeriod operator ~/(int divisor);
  @override
  SecondsPeriod operator %(int divisor);
  @override
  SecondsPeriod remainder(int divisor);
}

final class Seconds extends SecondsPeriod {
  const Seconds(this.value);

  static const perMinute = Seconds(Duration.secondsPerMinute);
  static const perHour = Seconds(Duration.secondsPerHour);
  static const perDay = Seconds(Duration.secondsPerDay);
  static const perWeek = Seconds(Duration.secondsPerDay * DateTime.daysPerWeek);

  final int value;

  @override
  Seconds get inSeconds => this;

  Seconds operator +(SecondsPeriod period) =>
      Seconds(value + period.inSeconds.value);
  Seconds operator -(SecondsPeriod period) =>
      Seconds(value - period.inSeconds.value);
  @override
  Seconds operator -() => Seconds(-value);
  @override
  Seconds operator *(int factor) => Seconds(value * factor);
  @override
  Seconds operator ~/(int divisor) => Seconds(value ~/ divisor);
  @override
  Seconds operator %(int divisor) => Seconds(value % divisor);
  @override
  Seconds remainder(int divisor) => Seconds(value.remainder(divisor));

  @override
  String toString() => value.abs() == 1 ? '$value second' : '$value seconds';
}

abstract class MinutesPeriod extends SecondsPeriod {
  const MinutesPeriod();

  Minutes get inMinutes;
  (Hours, Minutes) get inHoursAndMinutes {
    final inMinutes = this.inMinutes;
    final hours = Hours(inMinutes.value ~/ Minutes.perHour.value);
    final minutes = inMinutes.remainder(Minutes.perHour.value);
    return (hours, minutes);
  }

  @override
  Seconds get inSeconds => Seconds.perMinute * inMinutes.value;

  @override
  MinutesPeriod operator -();
  @override
  MinutesPeriod operator *(int factor);
  @override
  MinutesPeriod operator ~/(int divisor);
  @override
  MinutesPeriod operator %(int divisor);
}

final class Minutes extends MinutesPeriod {
  const Minutes(this.value);

  static const perHour = Minutes(Duration.minutesPerHour);
  static const perDay = Minutes(Duration.minutesPerDay);
  static const perWeek = Minutes(Duration.minutesPerDay * DateTime.daysPerWeek);

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
  Minutes operator ~/(int divisor) => Minutes(value ~/ divisor);
  @override
  Minutes operator %(int divisor) => Minutes(value % divisor);
  @override
  Minutes remainder(int divisor) => Minutes(value.remainder(divisor));

  @override
  String toString() => value.abs() == 1 ? '$value minute' : '$value minutes';
}

final class Hours extends MinutesPeriod {
  const Hours(this.value);

  static const perDay = Hours(Duration.hoursPerDay);
  static const perWeek = Hours(Duration.hoursPerDay * DateTime.daysPerWeek);

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
  Hours operator ~/(int divisor) => Hours(value ~/ divisor);
  @override
  Hours operator %(int divisor) => Hours(value % divisor);
  @override
  Hours remainder(int divisor) => Hours(value.remainder(divisor));

  @override
  String toString() => value.abs() == 1 ? '$value hour' : '$value hours';
}
