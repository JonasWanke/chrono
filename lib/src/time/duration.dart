import 'dart:core';
import 'dart:core' as core;

import 'package:fixed/fixed.dart';

import '../date_time/duration.dart';
import '../utils.dart';

// ignore_for_file: binary-expression-operand-order

abstract class TimeDuration extends Duration
    with ComparisonOperatorsFromComparable<TimeDuration>
    implements Comparable<TimeDuration> {
  const TimeDuration();

  FractionalSeconds get inFractionalSeconds;
  (Seconds, FractionalSeconds) get inSecondsAndFraction {
    final (seconds, fraction) =
        inFractionalSeconds.value.integerAndDecimalParts;
    return (Seconds(seconds.toInt()), FractionalSeconds(fraction));
  }

  @override
  CompoundDuration get asCompoundDuration =>
      CompoundDuration(seconds: inFractionalSeconds);

  bool get isPositive => inFractionalSeconds.value.isPositive;
  bool get isNonPositive => !isPositive;
  bool get isNegative => inFractionalSeconds.value.isNegative;
  bool get isNonNegative => !isNegative;

  @override
  TimeDuration operator -();
  @override
  TimeDuration operator *(int factor);
  @override
  TimeDuration operator ~/(int divisor);
  @override
  TimeDuration operator %(int divisor);
  @override
  TimeDuration remainder(int divisor);

  @override
  int compareTo(TimeDuration other) {
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
        (other is TimeDuration &&
            inFractionalSeconds.value == other.inFractionalSeconds.value);
  }

  @override
  int get hashCode => inFractionalSeconds.value.hashCode;
}

final class FractionalSeconds extends TimeDuration {
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

  FractionalSeconds operator +(TimeDuration duration) =>
      FractionalSeconds(value + duration.inFractionalSeconds.value);
  FractionalSeconds operator -(TimeDuration duration) =>
      FractionalSeconds(value - duration.inFractionalSeconds.value);
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

abstract class NanosecondsDuration extends TimeDuration {
  const NanosecondsDuration();

  Nanoseconds get inNanoseconds;
  @override
  FractionalSeconds get inFractionalSeconds =>
      FractionalSeconds.millisecond * inNanoseconds.value;

  @override
  NanosecondsDuration operator -();
  @override
  NanosecondsDuration operator *(int factor);
  @override
  NanosecondsDuration operator ~/(int divisor);
  @override
  NanosecondsDuration operator %(int divisor);
  @override
  NanosecondsDuration remainder(int divisor);
}

final class Nanoseconds extends NanosecondsDuration {
  const Nanoseconds(this.value);

  static const perMicrosecond =
      Nanoseconds(1000 * core.Duration.microsecondsPerSecond);
  static const perMillisecond =
      Nanoseconds(1000 * core.Duration.microsecondsPerSecond);
  static const perSecond =
      Nanoseconds(1000 * core.Duration.microsecondsPerSecond);
  static const perMinute =
      Nanoseconds(1000 * core.Duration.microsecondsPerMinute);
  static const perHour = Nanoseconds(1000 * core.Duration.microsecondsPerHour);
  static const perDay = Nanoseconds(1000 * core.Duration.microsecondsPerDay);
  static const perWeek = Nanoseconds(
    1000 * core.Duration.microsecondsPerDay * DateTime.daysPerWeek,
  );

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

  Nanoseconds operator +(NanosecondsDuration duration) =>
      Nanoseconds(value + duration.inNanoseconds.value);
  Nanoseconds operator -(NanosecondsDuration duration) =>
      Nanoseconds(value - duration.inNanoseconds.value);
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

abstract class MicrosecondsDuration extends NanosecondsDuration {
  const MicrosecondsDuration();

  Microseconds get inMicroseconds;
  @override
  Nanoseconds get inNanoseconds =>
      Nanoseconds.perMicrosecond * inMicroseconds.value;
  @override
  FractionalSeconds get inFractionalSeconds =>
      FractionalSeconds.millisecond * inMicroseconds.value;

  @override
  MicrosecondsDuration operator -();
  @override
  MicrosecondsDuration operator *(int factor);
  @override
  MicrosecondsDuration operator ~/(int divisor);
  @override
  MicrosecondsDuration operator %(int divisor);
  @override
  MicrosecondsDuration remainder(int divisor);
}

final class Microseconds extends MicrosecondsDuration {
  const Microseconds(this.value);

  static const perMillisecond =
      Microseconds(core.Duration.microsecondsPerMillisecond);
  static const perSecond = Microseconds(core.Duration.microsecondsPerSecond);
  static const perMinute = Microseconds(core.Duration.microsecondsPerMinute);
  static const perHour = Microseconds(core.Duration.microsecondsPerHour);
  static const perDay = Microseconds(core.Duration.microsecondsPerDay);
  static const perWeek =
      Microseconds(core.Duration.microsecondsPerDay * DateTime.daysPerWeek);

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

  Microseconds operator +(MicrosecondsDuration duration) =>
      Microseconds(value + duration.inMicroseconds.value);
  Microseconds operator -(MicrosecondsDuration duration) =>
      Microseconds(value - duration.inMicroseconds.value);
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

abstract class MillisecondsDuration extends MicrosecondsDuration {
  const MillisecondsDuration();

  Milliseconds get inMilliseconds;
  @override
  Microseconds get inMicroseconds =>
      Microseconds.perMillisecond * inMilliseconds.value;
  @override
  FractionalSeconds get inFractionalSeconds =>
      FractionalSeconds.millisecond * inMilliseconds.value;

  @override
  MillisecondsDuration operator -();
  @override
  MillisecondsDuration operator *(int factor);
  @override
  MillisecondsDuration operator ~/(int divisor);
  @override
  MillisecondsDuration operator %(int divisor);
  @override
  MillisecondsDuration remainder(int divisor);
}

final class Milliseconds extends MillisecondsDuration {
  const Milliseconds(this.value);

  static const perSecond = Milliseconds(core.Duration.millisecondsPerSecond);
  static const perMinute = Milliseconds(core.Duration.millisecondsPerMinute);
  static const perHour = Milliseconds(core.Duration.millisecondsPerHour);
  static const perDay = Milliseconds(core.Duration.millisecondsPerDay);
  static const perWeek =
      Milliseconds(core.Duration.millisecondsPerDay * DateTime.daysPerWeek);

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

  Milliseconds operator +(MillisecondsDuration duration) =>
      Milliseconds(value + duration.inMilliseconds.value);
  Milliseconds operator -(MillisecondsDuration duration) =>
      Milliseconds(value - duration.inMilliseconds.value);
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

abstract class SecondsDuration extends MillisecondsDuration {
  const SecondsDuration();

  Seconds get inSeconds;
  @override
  Milliseconds get inMilliseconds => Milliseconds.perSecond * inSeconds.value;

  @override
  FractionalSeconds get inFractionalSeconds =>
      FractionalSeconds.second * inSeconds.value;

  @override
  SecondsDuration operator -();
  @override
  SecondsDuration operator *(int factor);
  @override
  SecondsDuration operator ~/(int divisor);
  @override
  SecondsDuration operator %(int divisor);
  @override
  SecondsDuration remainder(int divisor);
}

final class Seconds extends SecondsDuration {
  const Seconds(this.value);

  static const perMinute = Seconds(core.Duration.secondsPerMinute);
  static const perHour = Seconds(core.Duration.secondsPerHour);
  static const perDay = Seconds(core.Duration.secondsPerDay);
  static const perWeek =
      Seconds(core.Duration.secondsPerDay * DateTime.daysPerWeek);

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

  Seconds operator +(SecondsDuration duration) =>
      Seconds(value + duration.inSeconds.value);
  Seconds operator -(SecondsDuration duration) =>
      Seconds(value - duration.inSeconds.value);
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

abstract class MinutesDuration extends SecondsDuration {
  const MinutesDuration();

  Minutes get inMinutes;
  @override
  Seconds get inSeconds => Seconds.perMinute * inMinutes.value;

  @override
  MinutesDuration operator -();
  @override
  MinutesDuration operator *(int factor);
  @override
  MinutesDuration operator ~/(int divisor);
  @override
  MinutesDuration operator %(int divisor);
}

final class Minutes extends MinutesDuration {
  const Minutes(this.value);

  static const perHour = Minutes(core.Duration.minutesPerHour);
  static const perDay = Minutes(core.Duration.minutesPerDay);
  static const perWeek =
      Minutes(core.Duration.minutesPerDay * DateTime.daysPerWeek);

  final int value;

  @override
  Minutes get inMinutes => this;
  (Hours, Minutes) get inHoursAndMinutes {
    final inMinutes = this.inMinutes;
    final hours = Hours(inMinutes.value ~/ Minutes.perHour.value);
    final minutes = inMinutes.remainder(Minutes.perHour.value);
    return (hours, minutes);
  }

  Minutes operator +(MinutesDuration duration) =>
      Minutes(value + duration.inMinutes.value);
  Minutes operator -(MinutesDuration duration) =>
      Minutes(value - duration.inMinutes.value);
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

final class Hours extends MinutesDuration {
  const Hours(this.value);

  static const perDay = Hours(core.Duration.hoursPerDay);
  static const perWeek =
      Hours(core.Duration.hoursPerDay * DateTime.daysPerWeek);

  final int value;

  @override
  Minutes get inMinutes => Minutes.perHour * value;

  Hours operator +(Hours duration) => Hours(value + duration.value);
  Hours operator -(Hours duration) => Hours(value - duration.value);
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
