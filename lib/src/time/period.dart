import 'package:fixed/fixed.dart';

import '../date/period.dart';
import '../date_time/period.dart';
import '../utils.dart';

// ignore_for_file: binary-expression-operand-order

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
  int compareTo(TimePeriod other) {
    var thisValue = inFractionalSeconds.value;
    var otherValue = other.inFractionalSeconds.value;
    if (thisValue.scale < otherValue.scale) {
      thisValue = Fixed.copyWith(thisValue, scale: otherValue.scale);
    } else if (otherValue.scale < thisValue.scale) {
      otherValue = Fixed.copyWith(otherValue, scale: thisValue.scale);
    }
    return thisValue.minorUnits.compareTo(otherValue.minorUnits);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is TimePeriod &&
            inFractionalSeconds.value == other.inFractionalSeconds.value);
  }

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

  int get inNanosecondsRounded =>
      Fixed.copyWith(value, scale: 9).minorUnits.toInt();
  int get inMicrosecondsRounded =>
      Fixed.copyWith(value, scale: 6).minorUnits.toInt();
  int get inMillisecondsRounded =>
      Fixed.copyWith(value, scale: 3).minorUnits.toInt();

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

abstract class NanosecondsPeriod extends TimePeriod {
  const NanosecondsPeriod();

  Nanoseconds get inNanoseconds;
  @override
  FractionalSeconds get inFractionalSeconds =>
      FractionalSeconds.millisecond * inNanoseconds.value;

  @override
  NanosecondsPeriod operator -();
  @override
  NanosecondsPeriod operator *(int factor);
  @override
  NanosecondsPeriod operator ~/(int divisor);
  @override
  NanosecondsPeriod operator %(int divisor);
  @override
  NanosecondsPeriod remainder(int divisor);
}

final class Nanoseconds extends NanosecondsPeriod {
  const Nanoseconds(this.value);

  static const perMicrosecond =
      Nanoseconds(1000 * Duration.microsecondsPerSecond);
  static const perMillisecond =
      Nanoseconds(1000 * Duration.microsecondsPerSecond);
  static const perSecond = Nanoseconds(1000 * Duration.microsecondsPerSecond);
  static const perMinute = Nanoseconds(1000 * Duration.microsecondsPerMinute);
  static const perHour = Nanoseconds(1000 * Duration.microsecondsPerHour);
  static const perDay = Nanoseconds(1000 * Duration.microsecondsPerDay);
  static const perWeek =
      Nanoseconds(1000 * Duration.microsecondsPerDay * DateTime.daysPerWeek);

  final int value;

  @override
  Nanoseconds get inNanoseconds => this;
  (Microseconds, Nanoseconds) get inMicrosecondsAndNanoseconds {
    final inNanoseconds = this.inNanoseconds;
    final microseconds =
        Microseconds(inNanoseconds.value ~/ Nanoseconds.perSecond.value);
    final nanoseconds = inNanoseconds.remainder(Nanoseconds.perSecond.value);
    return (microseconds, nanoseconds);
  }

  Nanoseconds operator +(NanosecondsPeriod period) =>
      Nanoseconds(value + period.inNanoseconds.value);
  Nanoseconds operator -(NanosecondsPeriod period) =>
      Nanoseconds(value - period.inNanoseconds.value);
  @override
  Nanoseconds operator -() => Nanoseconds(-value);
  @override
  Nanoseconds operator *(int factor) => Nanoseconds(value * factor);
  @override
  Nanoseconds operator ~/(int divisor) => Nanoseconds(value ~/ divisor);
  @override
  Nanoseconds operator %(int divisor) => Nanoseconds(value % divisor);
  @override
  Nanoseconds remainder(int divisor) => Nanoseconds(value.remainder(divisor));

  @override
  String toString() =>
      value.abs() == 1 ? '$value nanosecond' : '$value nanoseconds';
}

abstract class MicrosecondsPeriod extends NanosecondsPeriod {
  const MicrosecondsPeriod();

  Microseconds get inMicroseconds;
  @override
  Nanoseconds get inNanoseconds =>
      Nanoseconds.perMicrosecond * inMicroseconds.value;
  @override
  FractionalSeconds get inFractionalSeconds =>
      FractionalSeconds.millisecond * inMicroseconds.value;

  @override
  MicrosecondsPeriod operator -();
  @override
  MicrosecondsPeriod operator *(int factor);
  @override
  MicrosecondsPeriod operator ~/(int divisor);
  @override
  MicrosecondsPeriod operator %(int divisor);
  @override
  MicrosecondsPeriod remainder(int divisor);
}

final class Microseconds extends MicrosecondsPeriod {
  const Microseconds(this.value);

  static const perMillisecond =
      Microseconds(Duration.microsecondsPerMillisecond);
  static const perSecond = Microseconds(Duration.microsecondsPerSecond);
  static const perMinute = Microseconds(Duration.microsecondsPerMinute);
  static const perHour = Microseconds(Duration.microsecondsPerHour);
  static const perDay = Microseconds(Duration.microsecondsPerDay);
  static const perWeek =
      Microseconds(Duration.microsecondsPerDay * DateTime.daysPerWeek);

  final int value;

  @override
  Microseconds get inMicroseconds => this;
  (Milliseconds, Microseconds) get inMillisecondsAndMicroseconds {
    final inMicroseconds = this.inMicroseconds;
    final milliseconds =
        Milliseconds(inMicroseconds.value ~/ Microseconds.perSecond.value);
    final microseconds = inMicroseconds.remainder(Microseconds.perSecond.value);
    return (milliseconds, microseconds);
  }

  Microseconds operator +(MicrosecondsPeriod period) =>
      Microseconds(value + period.inMicroseconds.value);
  Microseconds operator -(MicrosecondsPeriod period) =>
      Microseconds(value - period.inMicroseconds.value);
  @override
  Microseconds operator -() => Microseconds(-value);
  @override
  Microseconds operator *(int factor) => Microseconds(value * factor);
  @override
  Microseconds operator ~/(int divisor) => Microseconds(value ~/ divisor);
  @override
  Microseconds operator %(int divisor) => Microseconds(value % divisor);
  @override
  Microseconds remainder(int divisor) => Microseconds(value.remainder(divisor));

  @override
  String toString() =>
      value.abs() == 1 ? '$value microsecond' : '$value microseconds';
}

abstract class MillisecondsPeriod extends MicrosecondsPeriod {
  const MillisecondsPeriod();

  Milliseconds get inMilliseconds;
  @override
  Microseconds get inMicroseconds =>
      Microseconds.perMillisecond * inMilliseconds.value;
  @override
  FractionalSeconds get inFractionalSeconds =>
      FractionalSeconds.millisecond * inMilliseconds.value;

  @override
  MillisecondsPeriod operator -();
  @override
  MillisecondsPeriod operator *(int factor);
  @override
  MillisecondsPeriod operator ~/(int divisor);
  @override
  MillisecondsPeriod operator %(int divisor);
  @override
  MillisecondsPeriod remainder(int divisor);
}

final class Milliseconds extends MillisecondsPeriod {
  const Milliseconds(this.value);

  static const perSecond = Milliseconds(Duration.millisecondsPerSecond);
  static const perMinute = Milliseconds(Duration.millisecondsPerMinute);
  static const perHour = Milliseconds(Duration.millisecondsPerHour);
  static const perDay = Milliseconds(Duration.millisecondsPerDay);
  static const perWeek =
      Milliseconds(Duration.millisecondsPerDay * DateTime.daysPerWeek);

  final int value;

  @override
  Milliseconds get inMilliseconds => this;
  (Seconds, Milliseconds) get inSecondsAndMilliseconds {
    final inMilliseconds = this.inMilliseconds;
    final seconds =
        Seconds(inMilliseconds.value ~/ Milliseconds.perSecond.value);
    final milliseconds = inMilliseconds.remainder(Milliseconds.perSecond.value);
    return (seconds, milliseconds);
  }

  Milliseconds operator +(MillisecondsPeriod period) =>
      Milliseconds(value + period.inMilliseconds.value);
  Milliseconds operator -(MillisecondsPeriod period) =>
      Milliseconds(value - period.inMilliseconds.value);
  @override
  Milliseconds operator -() => Milliseconds(-value);
  @override
  Milliseconds operator *(int factor) => Milliseconds(value * factor);
  @override
  Milliseconds operator ~/(int divisor) => Milliseconds(value ~/ divisor);
  @override
  Milliseconds operator %(int divisor) => Milliseconds(value % divisor);
  @override
  Milliseconds remainder(int divisor) => Milliseconds(value.remainder(divisor));

  @override
  String toString() =>
      value.abs() == 1 ? '$value millisecond' : '$value milliseconds';
}

abstract class SecondsPeriod extends MillisecondsPeriod {
  const SecondsPeriod();

  Seconds get inSeconds;
  @override
  Milliseconds get inMilliseconds => Milliseconds.perSecond * inSeconds.value;

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
  (Hours, Minutes) get inHoursAndMinutes {
    final inMinutes = this.inMinutes;
    final hours = Hours(inMinutes.value ~/ Minutes.perHour.value);
    final minutes = inMinutes.remainder(Minutes.perHour.value);
    return (hours, minutes);
  }

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
