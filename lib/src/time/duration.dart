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
  Fixed get inFractionalSeconds => asFractionalSeconds.inFractionalSeconds;
  (Seconds, FractionalSeconds) get asSecondsAndFraction {
    final (seconds, fraction) = inFractionalSeconds.integerAndDecimalParts;
    return (Seconds(seconds.toInt()), FractionalSeconds(fraction));
  }

  @override
  CompoundDuration get asCompoundDuration =>
      CompoundDuration(seconds: asFractionalSeconds);

  bool get isPositive => inFractionalSeconds.isPositive;
  bool get isNonPositive => !isPositive;
  bool get isNegative => inFractionalSeconds.isNegative;
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

  TimeDuration get absolute => isNegative ? -this : this;

  Nanoseconds roundToNanoseconds() =>
      Nanoseconds(inFractionalSeconds.toFixedScale(9).round());
  Microseconds roundToMicroseconds() =>
      Microseconds(inFractionalSeconds.toFixedScale(6).round());
  Milliseconds roundToMilliseconds() =>
      Milliseconds(inFractionalSeconds.toFixedScale(3).round());
  Seconds roundToSeconds() =>
      Seconds(inFractionalSeconds.toFixedScale(0).round());
  Minutes roundToMinutes() =>
      Minutes((roundToSeconds().inSeconds / Seconds.perMinute).round());
  Hours roundToHours() =>
      Hours((roundToSeconds().inSeconds / Seconds.perHour).round());
  Days roundToNormalDays() =>
      Days((roundToSeconds().inSeconds / Seconds.perNormalDay).round());
  Weeks roundToNormalWeeks() =>
      Weeks((roundToSeconds().inSeconds / Seconds.perNormalWeek).round());

  @override
  int compareTo(TimeDuration other) {
    var thisValue = inFractionalSeconds;
    var otherValue = other.inFractionalSeconds;
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
            inFractionalSeconds == other.inFractionalSeconds);
  }

  @override
  int get hashCode => inFractionalSeconds.hashCode;
}

final class FractionalSeconds extends TimeDuration {
  const FractionalSeconds(this.inFractionalSeconds);

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
  static final perNormalYear =
      const Seconds(Seconds.perNormalYear).asFractionalSeconds;
  static final perNormalLeapYear =
      const Seconds(Seconds.perNormalLeapYear).asFractionalSeconds;

  @override
  final Fixed inFractionalSeconds;

  @override
  FractionalSeconds get asFractionalSeconds => this;

  FractionalSeconds operator +(TimeDuration duration) =>
      FractionalSeconds(inFractionalSeconds + duration.inFractionalSeconds);
  FractionalSeconds operator -(TimeDuration duration) =>
      FractionalSeconds(inFractionalSeconds - duration.inFractionalSeconds);
  @override
  FractionalSeconds operator -() => FractionalSeconds(-inFractionalSeconds);
  @override
  FractionalSeconds operator *(int factor) =>
      FractionalSeconds(inFractionalSeconds * Fixed.fromInt(factor, scale: 0));
  @override
  FractionalSeconds operator ~/(int divisor) {
    return FractionalSeconds(Fixed.fromBigInt(
      inFractionalSeconds.minorUnits ~/ BigInt.from(divisor),
      scale: inFractionalSeconds.scale,
    ));
  }

  @override
  FractionalSeconds operator %(int divisor) {
    return FractionalSeconds(Fixed.fromBigInt(
      inFractionalSeconds.minorUnits % BigInt.from(divisor),
      scale: inFractionalSeconds.scale,
    ));
  }

  @override
  FractionalSeconds remainder(int divisor) {
    return FractionalSeconds(Fixed.fromBigInt(
      inFractionalSeconds.minorUnits.remainder(BigInt.from(divisor)),
      scale: inFractionalSeconds.scale,
    ));
  }

  @override
  FractionalSeconds get absolute => isNegative ? -this : this;

  @override
  String toString() {
    return inFractionalSeconds.abs == Fixed.one
        ? '$inFractionalSeconds second'
        : '$inFractionalSeconds seconds';
  }
}

abstract class NanosecondsDuration extends TimeDuration {
  const NanosecondsDuration();

  Nanoseconds get asNanoseconds;
  int get inNanoseconds => asNanoseconds.inNanoseconds;
  @override
  FractionalSeconds get asFractionalSeconds =>
      FractionalSeconds.nanosecond * inNanoseconds;

  (Microseconds, Nanoseconds) get asMicrosecondsAndNanoseconds {
    final asNanoseconds = this.asNanoseconds;
    final microseconds =
        Microseconds(asNanoseconds.inNanoseconds ~/ Nanoseconds.perSecond);
    final nanoseconds = asNanoseconds.remainder(Nanoseconds.perSecond);
    return (microseconds, nanoseconds);
  }

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

  @override
  NanosecondsDuration get absolute => isNegative ? -this : this;
}

final class Nanoseconds extends NanosecondsDuration {
  const Nanoseconds(this.inNanoseconds);

  static const perMicrosecond = 1000;
  static const perMillisecond = perMicrosecond * Microseconds.perMillisecond;
  static const perSecond = perMicrosecond * Microseconds.perSecond;
  static const perMinute = perMicrosecond * Microseconds.perMinute;
  static const perHour = perMicrosecond * Microseconds.perHour;
  static const perNormalDay = perMicrosecond * Microseconds.perNormalDay;
  static const perNormalWeek = perMicrosecond * Microseconds.perNormalWeek;
  static const perNormalYear = perMicrosecond * Microseconds.perNormalYear;
  static const perNormalLeapYear =
      perMicrosecond * Microseconds.perNormalLeapYear;

  @override
  final int inNanoseconds;

  @override
  Nanoseconds get asNanoseconds => this;

  Nanoseconds operator +(NanosecondsDuration duration) =>
      Nanoseconds(inNanoseconds + duration.inNanoseconds);
  Nanoseconds operator -(NanosecondsDuration duration) =>
      Nanoseconds(inNanoseconds - duration.inNanoseconds);
  @override
  Nanoseconds operator -() => Nanoseconds(-inNanoseconds);
  @override
  Nanoseconds operator *(int factor) => Nanoseconds(inNanoseconds * factor);
  @override
  Nanoseconds operator ~/(int divisor) => Nanoseconds(inNanoseconds ~/ divisor);
  @override
  Nanoseconds operator %(int divisor) => Nanoseconds(inNanoseconds % divisor);
  @override
  Nanoseconds remainder(int divisor) =>
      Nanoseconds(inNanoseconds.remainder(divisor));

  @override
  Nanoseconds get absolute => isNegative ? -this : this;

  @override
  String toString() {
    return inNanoseconds.abs() == 1
        ? '$inNanoseconds nanosecond'
        : '$inNanoseconds nanoseconds';
  }
}

abstract class MicrosecondsDuration extends NanosecondsDuration {
  const MicrosecondsDuration();

  Microseconds get asMicroseconds;
  int get inMicroseconds => asMicroseconds.inMicroseconds;
  @override
  Nanoseconds get asNanoseconds =>
      Nanoseconds(inMicroseconds * Nanoseconds.perMicrosecond);
  @override
  FractionalSeconds get asFractionalSeconds =>
      FractionalSeconds.microsecond * inMicroseconds;

  (Milliseconds, Microseconds) get asMillisecondsAndMicroseconds {
    final asMicroseconds = this.asMicroseconds;
    final milliseconds =
        Milliseconds(asMicroseconds.inMicroseconds ~/ Microseconds.perSecond);
    final microseconds = asMicroseconds.remainder(Microseconds.perSecond);
    return (milliseconds, microseconds);
  }

  core.Duration get asCoreDuration =>
      core.Duration(microseconds: inMicroseconds);

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

  @override
  MicrosecondsDuration get absolute => isNegative ? -this : this;
}

final class Microseconds extends MicrosecondsDuration {
  const Microseconds(this.inMicroseconds);

  Microseconds.fromCore(core.Duration duration)
      : inMicroseconds = duration.inMicroseconds;

  static const perMillisecond = 1000;
  static const perSecond = perMillisecond * Milliseconds.perSecond;
  static const perMinute = perMillisecond * Milliseconds.perMinute;
  static const perHour = perMillisecond * Milliseconds.perHour;
  static const perNormalDay = perMillisecond * Milliseconds.perNormalDay;
  static const perNormalWeek = perMillisecond * Milliseconds.perNormalWeek;
  static const perNormalYear = perMillisecond * Milliseconds.perNormalYear;
  static const perNormalLeapYear =
      perMillisecond * Milliseconds.perNormalLeapYear;

  @override
  final int inMicroseconds;

  @override
  Microseconds get asMicroseconds => this;

  Microseconds operator +(MicrosecondsDuration duration) =>
      Microseconds(inMicroseconds + duration.inMicroseconds);
  Microseconds operator -(MicrosecondsDuration duration) =>
      Microseconds(inMicroseconds - duration.inMicroseconds);
  @override
  Microseconds operator -() => Microseconds(-inMicroseconds);
  @override
  Microseconds operator *(int factor) => Microseconds(inMicroseconds * factor);
  @override
  Microseconds operator ~/(int divisor) =>
      Microseconds(inMicroseconds ~/ divisor);
  @override
  Microseconds operator %(int divisor) =>
      Microseconds(inMicroseconds % divisor);
  @override
  Microseconds remainder(int divisor) =>
      Microseconds(inMicroseconds.remainder(divisor));

  @override
  Microseconds get absolute => isNegative ? -this : this;

  @override
  String toString() {
    return inMicroseconds.abs() == 1
        ? '$inMicroseconds microsecond'
        : '$inMicroseconds microseconds';
  }
}

abstract class MillisecondsDuration extends MicrosecondsDuration {
  const MillisecondsDuration();

  Milliseconds get asMilliseconds;
  int get inMilliseconds => asMilliseconds.inMilliseconds;
  @override
  Microseconds get asMicroseconds =>
      Microseconds(inMilliseconds * Microseconds.perMillisecond);
  @override
  FractionalSeconds get asFractionalSeconds =>
      FractionalSeconds.millisecond * inMilliseconds;

  (Seconds, Milliseconds) get asSecondsAndMilliseconds {
    final asMilliseconds = this.asMilliseconds;
    final seconds =
        Seconds(asMilliseconds.inMilliseconds ~/ Milliseconds.perSecond);
    final milliseconds = asMilliseconds.remainder(Milliseconds.perSecond);
    return (seconds, milliseconds);
  }

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

  @override
  MillisecondsDuration get absolute => isNegative ? -this : this;
}

final class Milliseconds extends MillisecondsDuration {
  const Milliseconds(this.inMilliseconds);

  static const perSecond = 1000;
  static const perMinute = perSecond * Seconds.perMinute;
  static const perHour = perSecond * Seconds.perHour;
  static const perNormalDay = perSecond * Seconds.perNormalDay;
  static const perNormalWeek = perSecond * Seconds.perNormalDay;
  static const perNormalYear = perSecond * Seconds.perNormalYear;
  static const perNormalLeapYear = perSecond * Seconds.perNormalLeapYear;

  @override
  final int inMilliseconds;

  @override
  Milliseconds get asMilliseconds => this;

  Milliseconds operator +(MillisecondsDuration duration) =>
      Milliseconds(inMilliseconds + duration.inMilliseconds);
  Milliseconds operator -(MillisecondsDuration duration) =>
      Milliseconds(inMilliseconds - duration.inMilliseconds);
  @override
  Milliseconds operator -() => Milliseconds(-inMilliseconds);
  @override
  Milliseconds operator *(int factor) => Milliseconds(inMilliseconds * factor);
  @override
  Milliseconds operator ~/(int divisor) =>
      Milliseconds(inMilliseconds ~/ divisor);
  @override
  Milliseconds operator %(int divisor) =>
      Milliseconds(inMilliseconds % divisor);
  @override
  Milliseconds remainder(int divisor) =>
      Milliseconds(inMilliseconds.remainder(divisor));

  @override
  Milliseconds get absolute => isNegative ? -this : this;

  @override
  String toString() {
    return inMilliseconds.abs() == 1
        ? '$inMilliseconds millisecond'
        : '$inMilliseconds milliseconds';
  }
}

abstract class SecondsDuration extends MillisecondsDuration {
  const SecondsDuration();

  Seconds get asSeconds;
  int get inSeconds => asSeconds.inSeconds;
  @override
  Milliseconds get asMilliseconds =>
      Milliseconds(inSeconds * Milliseconds.perSecond);
  @override
  FractionalSeconds get asFractionalSeconds =>
      FractionalSeconds.second * inSeconds;

  (Minutes, Seconds) get asMinutesAndSeconds {
    final asSeconds = this.asSeconds;
    final minutes = Minutes(asSeconds.inSeconds ~/ Seconds.perMinute);
    final seconds = asSeconds.remainder(Seconds.perMinute);
    return (minutes, seconds);
  }

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

  @override
  SecondsDuration get absolute => isNegative ? -this : this;
}

final class Seconds extends SecondsDuration {
  const Seconds(this.inSeconds);

  static const perMinute = 60;
  static const minute = Seconds(perMinute);
  static const perHour = perMinute * Minutes.perHour;
  static const hour = Seconds(perHour);
  static const perNormalDay = perMinute * Minutes.perNormalDay;
  static const normalDay = Seconds(perNormalDay);
  static const perNormalWeek = perMinute * Minutes.perNormalWeek;
  static const normalWeek = Seconds(perNormalWeek);
  static const perNormalYear = perMinute * Minutes.perNormalYear;
  static const normalYear = Seconds(perNormalYear);
  static const perNormalLeapYear = perMinute * Minutes.perNormalLeapYear;
  static const normalLeapYear = Seconds(perNormalLeapYear);

  @override
  final int inSeconds;

  @override
  Seconds get asSeconds => this;
  (Hours, Minutes, Seconds) get asHoursAndMinutesAndSeconds {
    final (asMinutes, seconds) = asMinutesAndSeconds;
    final (hours, minutes) = asMinutes.asHoursAndMinutes;
    return (hours, minutes, seconds);
  }

  Seconds operator +(SecondsDuration duration) =>
      Seconds(inSeconds + duration.inSeconds);
  Seconds operator -(SecondsDuration duration) =>
      Seconds(inSeconds - duration.inSeconds);
  @override
  Seconds operator -() => Seconds(-inSeconds);
  @override
  Seconds operator *(int factor) => Seconds(inSeconds * factor);
  @override
  Seconds operator ~/(int divisor) => Seconds(inSeconds ~/ divisor);
  @override
  Seconds operator %(int divisor) => Seconds(inSeconds % divisor);
  @override
  Seconds remainder(int divisor) => Seconds(inSeconds.remainder(divisor));

  @override
  Seconds get absolute => isNegative ? -this : this;

  @override
  String toString() =>
      inSeconds.abs() == 1 ? '$inSeconds second' : '$inSeconds seconds';
}

abstract class MinutesDuration extends SecondsDuration {
  const MinutesDuration();

  Minutes get asMinutes;
  int get inMinutes => asMinutes.inMinutes;
  @override
  Seconds get asSeconds => Seconds(inMinutes * Seconds.perMinute);

  (Hours, Minutes) get asHoursAndMinutes {
    final asMinutes = this.asMinutes;
    final hours = Hours(asMinutes.inMinutes ~/ Minutes.perHour);
    final minutes = asMinutes.remainder(Minutes.perHour);
    return (hours, minutes);
  }

  @override
  MinutesDuration operator -();
  @override
  MinutesDuration operator *(int factor);
  @override
  MinutesDuration operator ~/(int divisor);
  @override
  MinutesDuration operator %(int divisor);

  @override
  MinutesDuration get absolute => isNegative ? -this : this;
}

final class Minutes extends MinutesDuration {
  const Minutes(this.inMinutes);

  static const perHour = 60;
  static const perNormalDay = perHour * Hours.perNormalDay;
  static const perNormalWeek = perHour * Hours.perNormalWeek;
  static const perNormalYear = perHour * Hours.perNormalYear;
  static const perNormalLeapYear = perHour * Hours.perNormalLeapYear;

  @override
  final int inMinutes;

  @override
  Minutes get asMinutes => this;

  Minutes operator +(MinutesDuration duration) =>
      Minutes(inMinutes + duration.inMinutes);
  Minutes operator -(MinutesDuration duration) =>
      Minutes(inMinutes - duration.inMinutes);
  @override
  Minutes operator -() => Minutes(-inMinutes);
  @override
  Minutes operator *(int factor) => Minutes(inMinutes * factor);
  @override
  Minutes operator ~/(int divisor) => Minutes(inMinutes ~/ divisor);
  @override
  Minutes operator %(int divisor) => Minutes(inMinutes % divisor);
  @override
  Minutes remainder(int divisor) => Minutes(inMinutes.remainder(divisor));

  @override
  Minutes get absolute => isNegative ? -this : this;

  @override
  String toString() =>
      inMinutes.abs() == 1 ? '$inMinutes minute' : '$inMinutes minutes';
}

final class Hours extends MinutesDuration {
  const Hours(this.inHours);

  static const perNormalDay = 24;
  static const normalDay = Hours(perNormalDay);
  static const perNormalWeek = perNormalDay * Days.perWeek;
  static const normalWeek = Hours(perNormalWeek);
  static const perNormalYear = perNormalDay * Days.perNormalYear;
  static const normalYear = Hours(perNormalYear);
  static const perNormalLeapYear = perNormalDay * Days.perLeapYear;
  static const normalLeapYear = Hours(perNormalLeapYear);

  final int inHours;

  @override
  Minutes get asMinutes => Minutes(inHours * Minutes.perHour);

  Hours operator +(Hours duration) => Hours(inHours + duration.inHours);
  Hours operator -(Hours duration) => Hours(inHours - duration.inHours);
  @override
  Hours operator -() => Hours(-inHours);
  @override
  Hours operator *(int factor) => Hours(inHours * factor);
  @override
  Hours operator ~/(int divisor) => Hours(inHours ~/ divisor);
  @override
  Hours operator %(int divisor) => Hours(inHours % divisor);
  @override
  Hours remainder(int divisor) => Hours(inHours.remainder(divisor));

  @override
  Hours get absolute => isNegative ? -this : this;

  @override
  String toString() => inHours.abs() == 1 ? '$inHours hour' : '$inHours hours';
}
