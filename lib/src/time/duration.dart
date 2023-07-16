import 'dart:core';
import 'dart:core' as core;

import 'package:fixed/fixed.dart';

import '../date/duration.dart';
import '../date_time/duration.dart';
import '../utils.dart';

// ignore_for_file: binary-expression-operand-order

abstract class TimeDuration extends Duration
    with ComparisonOperatorsFromComparable<TimeDuration>
    implements Comparable<TimeDuration> {
  const TimeDuration();

  FractionalSeconds get asFractionalSeconds;
  (Seconds, FractionalSeconds) get asSecondsAndFraction {
    final (seconds, fraction) =
        asFractionalSeconds.value.integerAndDecimalParts;
    return (Seconds(seconds.toInt()), FractionalSeconds(fraction));
  }

  @override
  CompoundDuration get asCompoundDuration =>
      CompoundDuration(seconds: asFractionalSeconds);

  bool get isPositive => asFractionalSeconds.value.isPositive;
  bool get isNonPositive => !isPositive;
  bool get isNegative => asFractionalSeconds.value.isNegative;
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
    var thisValue = asFractionalSeconds.value;
    var otherValue = other.asFractionalSeconds.value;
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
            asFractionalSeconds.value == other.asFractionalSeconds.value);
  }

  @override
  int get hashCode => asFractionalSeconds.value.hashCode;
}

final class FractionalSeconds extends TimeDuration {
  const FractionalSeconds(this.value);

  // `Fixed.zero` has a scale of 16, which we don't need.
  static final zero = FractionalSeconds(Fixed.fromInt(0, scale: 0));

  static final nanosecond = FractionalSeconds(Fixed.fromInt(1, scale: 9));
  static final microsecond = FractionalSeconds(Fixed.fromInt(1, scale: 6));
  static final millisecond = FractionalSeconds(Fixed.fromInt(1, scale: 3));
  static final second = FractionalSeconds(Fixed.fromInt(1, scale: 0));
  static final perMinute = const Seconds(Seconds.perMinute).asFractionalSeconds;
  static final perHour = const Seconds(Seconds.perHour).asFractionalSeconds;
  static final perNormalDay =
      const Seconds(Seconds.perNormalDay).asFractionalSeconds;
  static final perNormalWeek =
      const Seconds(Seconds.perNormalWeek).asFractionalSeconds;

  final Fixed value;

  int get asNanosecondsRounded =>
      Fixed.copyWith(value, scale: 9).minorUnits.toInt();
  int get asMicrosecondsRounded =>
      Fixed.copyWith(value, scale: 6).minorUnits.toInt();
  int get asMillisecondsRounded =>
      Fixed.copyWith(value, scale: 3).minorUnits.toInt();

  @override
  FractionalSeconds get asFractionalSeconds => this;

  FractionalSeconds operator +(TimeDuration duration) =>
      FractionalSeconds(value + duration.asFractionalSeconds.value);
  FractionalSeconds operator -(TimeDuration duration) =>
      FractionalSeconds(value - duration.asFractionalSeconds.value);
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

  Nanoseconds get asNanoseconds;
  @override
  FractionalSeconds get asFractionalSeconds =>
      FractionalSeconds.millisecond * asNanoseconds.value;

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

  static const perMicrosecond = 1000;
  static const perMillisecond = perMicrosecond * Microseconds.perMillisecond;
  static const perSecond = perMicrosecond * Microseconds.perSecond;
  static const perMinute = perMicrosecond * Microseconds.perMinute;
  static const perHour = perMicrosecond * Microseconds.perHour;
  static const perNormalDay = perMicrosecond * Microseconds.perNormalDay;
  static const perNormalWeek = perMicrosecond * Microseconds.perNormalWeek;

  final int value;

  @override
  Nanoseconds get asNanoseconds => this;
  (Microseconds, Nanoseconds) get asMicrosecondsAndNanoseconds {
    final asNanoseconds = this.asNanoseconds;
    final microseconds =
        Microseconds(asNanoseconds.value ~/ Nanoseconds.perSecond);
    final nanoseconds = asNanoseconds.remainder(Nanoseconds.perSecond);
    return (microseconds, nanoseconds);
  }

  Nanoseconds operator +(NanosecondsDuration duration) =>
      Nanoseconds(value + duration.asNanoseconds.value);
  Nanoseconds operator -(NanosecondsDuration duration) =>
      Nanoseconds(value - duration.asNanoseconds.value);
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

  Microseconds get asMicroseconds;
  @override
  Nanoseconds get asNanoseconds =>
      Nanoseconds(asMicroseconds.value * Nanoseconds.perMicrosecond);
  @override
  FractionalSeconds get asFractionalSeconds =>
      FractionalSeconds.millisecond * asMicroseconds.value;

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

  static const perMillisecond = 1000;
  static const perSecond = perMillisecond * Milliseconds.perSecond;
  static const perMinute = perMillisecond * Milliseconds.perMinute;
  static const perHour = perMillisecond * Milliseconds.perHour;
  static const perNormalDay = perMillisecond * Milliseconds.perNormalDay;
  static const perNormalWeek = perMillisecond * Milliseconds.perNormalWeek;

  final int value;

  @override
  Microseconds get asMicroseconds => this;
  (Milliseconds, Microseconds) get asMillisecondsAndMicroseconds {
    final asMicroseconds = this.asMicroseconds;
    final milliseconds =
        Milliseconds(asMicroseconds.value ~/ Microseconds.perSecond);
    final microseconds = asMicroseconds.remainder(Microseconds.perSecond);
    return (milliseconds, microseconds);
  }

  Microseconds operator +(MicrosecondsDuration duration) =>
      Microseconds(value + duration.asMicroseconds.value);
  Microseconds operator -(MicrosecondsDuration duration) =>
      Microseconds(value - duration.asMicroseconds.value);
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

  Milliseconds get asMilliseconds;
  @override
  Microseconds get asMicroseconds =>
      Microseconds(asMilliseconds.value * Microseconds.perMillisecond);
  @override
  FractionalSeconds get asFractionalSeconds =>
      FractionalSeconds.millisecond * asMilliseconds.value;

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

  static const perSecond = 1000;
  static const perMinute = perSecond * Seconds.perMinute;
  static const perHour = perSecond * Seconds.perHour;
  static const perNormalDay = perSecond * Seconds.perNormalDay;
  static const perNormalWeek = perSecond * Seconds.perNormalDay;

  final int value;

  @override
  Milliseconds get asMilliseconds => this;
  (Seconds, Milliseconds) get asSecondsAndMilliseconds {
    final asMilliseconds = this.asMilliseconds;
    final seconds = Seconds(asMilliseconds.value ~/ Milliseconds.perSecond);
    final milliseconds = asMilliseconds.remainder(Milliseconds.perSecond);
    return (seconds, milliseconds);
  }

  Milliseconds operator +(MillisecondsDuration duration) =>
      Milliseconds(value + duration.asMilliseconds.value);
  Milliseconds operator -(MillisecondsDuration duration) =>
      Milliseconds(value - duration.asMilliseconds.value);
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

  Seconds get asSeconds;
  @override
  Milliseconds get asMilliseconds =>
      Milliseconds(asSeconds.value * Milliseconds.perSecond);

  @override
  FractionalSeconds get asFractionalSeconds =>
      FractionalSeconds.second * asSeconds.value;

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

  static const perMinute = 60;
  static const perHour = perMinute * Minutes.perHour;
  static const perNormalDay = perMinute * Minutes.perNormalDay;
  static const perNormalWeek = perMinute * Minutes.perNormalWeek;

  final int value;

  @override
  Seconds get asSeconds => this;
  (Minutes, Seconds) get asMinutesAndSeconds {
    final asSeconds = this.asSeconds;
    final minutes = Minutes(asSeconds.value ~/ Seconds.perMinute);
    final seconds = asSeconds.remainder(Seconds.perMinute);
    return (minutes, seconds);
  }

  (Hours, Minutes, Seconds) get asHoursAndMinutesAndSeconds {
    final (asMinutes, seconds) = asMinutesAndSeconds;
    final (hours, minutes) = asMinutes.asHoursAndMinutes;
    return (hours, minutes, seconds);
  }

  Seconds operator +(SecondsDuration duration) =>
      Seconds(value + duration.asSeconds.value);
  Seconds operator -(SecondsDuration duration) =>
      Seconds(value - duration.asSeconds.value);
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

  Minutes get asMinutes;
  @override
  Seconds get asSeconds => Seconds(asMinutes.value * Seconds.perMinute);

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

  static const perHour = 60;
  static const perNormalDay = perHour * Hours.perNormalDay;
  static const perNormalWeek = perHour * Hours.perNormalWeek;

  final int value;

  @override
  Minutes get asMinutes => this;
  (Hours, Minutes) get asHoursAndMinutes {
    final asMinutes = this.asMinutes;
    final hours = Hours(asMinutes.value ~/ Minutes.perHour);
    final minutes = asMinutes.remainder(Minutes.perHour);
    return (hours, minutes);
  }

  Minutes operator +(MinutesDuration duration) =>
      Minutes(value + duration.asMinutes.value);
  Minutes operator -(MinutesDuration duration) =>
      Minutes(value - duration.asMinutes.value);
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

  static const perNormalDay = 24;
  static const perNormalWeek = perNormalDay * Days.perWeek;

  final int value;

  @override
  Minutes get asMinutes => Minutes(value * Minutes.perHour);

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
