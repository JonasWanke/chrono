import 'dart:core' as core;
import 'dart:core';

import 'package:fixed/fixed.dart';

import '../date/duration.dart';
import '../date_time/duration.dart';
import '../rounding.dart';
import '../utils.dart';

// ignore_for_file: binary-expression-operand-order

/// A [Duration] that is of a fixed length.
///
/// See also:
///
/// - [DaysDuration], which covers durations based on an integer number of days
///   or months.
/// - [Duration], which is the base class for all durations.
/// - [FractionalSeconds], which is a subclass storing the duration with
///   arbitrary precision.
abstract class TimeDuration extends Duration
    with ComparisonOperatorsFromComparable<TimeDuration>
    implements Comparable<TimeDuration> {
  const TimeDuration();

  // TODO(JonasWanke): add `lerp(…)`, `lerpNullable(…)` in other classes
  // TODO(JonasWanke): comments
  static FractionalSeconds? lerpNullable(
    TimeDuration? a,
    TimeDuration? b,
    double t, {
    int factorPrecisionAfterComma = 8,
  }) {
    return switch ((a?.asFractionalSeconds, b?.asFractionalSeconds)) {
      (null, null) => null,
      (null, final b?) =>
        b.timesNum(t, factorPrecisionAfterComma: factorPrecisionAfterComma),
      (final a?, null) =>
        a.timesNum(1 - t, factorPrecisionAfterComma: factorPrecisionAfterComma),
      (final a?, final b?) =>
        lerp(a, b, t, factorPrecisionAfterComma: factorPrecisionAfterComma),
    };
  }

  static FractionalSeconds lerp(
    TimeDuration a,
    TimeDuration b,
    double t, {
    int factorPrecisionAfterComma = 8,
  }) {
    return a.asFractionalSeconds.timesNum(
          1 - t,
          factorPrecisionAfterComma: factorPrecisionAfterComma,
        ) +
        b.asFractionalSeconds
            .timesNum(t, factorPrecisionAfterComma: factorPrecisionAfterComma);
  }

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
  FractionalSeconds timesNum(
    num factor, {
    int factorPrecisionAfterComma = 8,
  }) =>
      timesFixed(Fixed.fromNum(factor, scale: factorPrecisionAfterComma));
  FractionalSeconds timesFixed(Fixed factor) =>
      FractionalSeconds(inFractionalSeconds * factor);

  @override
  TimeDuration operator ~/(int divisor);
  // TODO(JonasWanke): Is this division precise enough?
  Fixed dividedByTimeDuration(TimeDuration divisor) =>
      inFractionalSeconds / divisor.inFractionalSeconds;
  FractionalSeconds dividedByNum(
    num divisor, {
    int divisorPrecisionAfterComma = 8,
  }) =>
      dividedByFixed(Fixed.fromNum(divisor, scale: divisorPrecisionAfterComma));
  // TODO(JonasWanke): Is this division precise enough?
  FractionalSeconds dividedByFixed(Fixed divisor) =>
      FractionalSeconds(inFractionalSeconds / divisor);

  @override
  TimeDuration operator %(int divisor);
  @override
  TimeDuration remainder(int divisor);

  TimeDuration get absolute => isNegative ? -this : this;

  Nanoseconds roundToNanoseconds({
    Rounding rounding = Rounding.nearestAwayFromZero,
  }) =>
      Nanoseconds(rounding.round(inFractionalSeconds.toFixedScale(9)));
  Microseconds roundToMicroseconds({
    Rounding rounding = Rounding.nearestAwayFromZero,
  }) =>
      Microseconds(rounding.round(inFractionalSeconds.toFixedScale(6)));
  Milliseconds roundToMilliseconds({
    Rounding rounding = Rounding.nearestAwayFromZero,
  }) =>
      Milliseconds(rounding.round(inFractionalSeconds.toFixedScale(3)));
  Seconds roundToSeconds({Rounding rounding = Rounding.nearestAwayFromZero}) =>
      Seconds(rounding.round(inFractionalSeconds.toFixedScale(0)));
  Minutes roundToMinutes({Rounding rounding = Rounding.nearestAwayFromZero}) =>
      Minutes(rounding.round(roundToSeconds().inSeconds / Seconds.perMinute));
  Hours roundToHours({Rounding rounding = Rounding.nearestAwayFromZero}) =>
      Hours(rounding.round(roundToSeconds().inSeconds / Seconds.perHour));
  Days roundToNormalDays({Rounding rounding = Rounding.nearestAwayFromZero}) =>
      Days(rounding.round(roundToSeconds().inSeconds / Seconds.perNormalDay));
  Weeks roundToNormalWeeks({
    Rounding rounding = Rounding.nearestAwayFromZero,
  }) =>
      Weeks(rounding.round(roundToSeconds().inSeconds / Seconds.perNormalWeek));
  Years roundToNormalYears({
    Rounding rounding = Rounding.nearestAwayFromZero,
  }) =>
      Years(rounding.round(roundToSeconds().inSeconds / Seconds.perNormalYear));
  Years roundToNormalLeapYears({
    Rounding rounding = Rounding.nearestAwayFromZero,
  }) {
    return Years(
      rounding.round(roundToSeconds().inSeconds / Seconds.perNormalLeapYear),
    );
  }

  core.Duration roundToCoreDuration({
    Rounding rounding = Rounding.nearestAwayFromZero,
  }) {
    return core.Duration(
      microseconds: roundToMicroseconds(rounding: rounding).inMicroseconds,
    );
  }

  FractionalSeconds roundToMultipleOf(
    TimeDuration duration, {
    Rounding rounding = Rounding.nearestAwayFromZero,
  }) {
    return duration.asFractionalSeconds *
        rounding.round(
          (inFractionalSeconds / duration.inFractionalSeconds).asDouble,
        );
  }

  Nanoseconds roundToMultipleOfNanoseconds(
    NanosecondsDuration duration, {
    Rounding rounding = Rounding.nearestAwayFromZero,
  }) {
    return duration.asNanoseconds *
        rounding.roundFixed(
          roundToNanoseconds(rounding: rounding)
              .dividedByTimeDuration(duration),
        );
  }

  Microseconds roundToMultipleOfMicroseconds(
    MicrosecondsDuration duration, {
    Rounding rounding = Rounding.nearestAwayFromZero,
  }) {
    return duration.asMicroseconds *
        rounding.roundFixed(
          roundToMicroseconds(rounding: rounding)
              .dividedByTimeDuration(duration),
        );
  }

  Milliseconds roundToMultipleOfMilliseconds(
    MillisecondsDuration duration, {
    Rounding rounding = Rounding.nearestAwayFromZero,
  }) {
    return duration.asMilliseconds *
        rounding.roundFixed(
          roundToMilliseconds(rounding: rounding)
              .dividedByTimeDuration(duration),
        );
  }

  Seconds roundToMultipleOfSeconds(
    SecondsDuration duration, {
    Rounding rounding = Rounding.nearestAwayFromZero,
  }) {
    return duration.asSeconds *
        rounding.roundFixed(
          roundToSeconds(rounding: rounding).dividedByTimeDuration(duration),
        );
  }

  Minutes roundToMultipleOfMinutes(
    MinutesDuration duration, {
    Rounding rounding = Rounding.nearestAwayFromZero,
  }) {
    return duration.asMinutes *
        rounding.roundFixed(
          roundToMinutes(rounding: rounding).dividedByTimeDuration(duration),
        );
  }

  Hours roundToMultipleOfHours(
    Hours duration, {
    Rounding rounding = Rounding.nearestAwayFromZero,
  }) {
    return duration *
        rounding.roundFixed(
          roundToHours(rounding: rounding).dividedByTimeDuration(duration),
        );
  }

  Days roundToMultipleOfNormalDays(
    FixedDaysDuration duration, {
    Rounding rounding = Rounding.nearestAwayFromZero,
  }) {
    return duration.asDays *
        rounding.round(
          roundToNormalDays(rounding: rounding)
              .dividedByFixedDaysDuration(duration),
        );
  }

  Weeks roundToMultipleOfNormalWeeks(
    Weeks duration, {
    Rounding rounding = Rounding.nearestAwayFromZero,
  }) {
    return duration *
        rounding.round(
          roundToNormalWeeks(rounding: rounding).dividedByWeeks(duration),
        );
  }

  Years roundToMultipleOfNormalYears(
    Years duration, {
    Rounding rounding = Rounding.nearestAwayFromZero,
  }) {
    return duration *
        rounding.round(
          roundToNormalYears(rounding: rounding).dividedByYears(duration),
        );
  }

  Years roundToMultipleOfNormalLeapYears(
    Years duration, {
    Rounding rounding = Rounding.nearestAwayFromZero,
  }) {
    return duration *
        rounding.round(
          roundToNormalLeapYears(rounding: rounding).dividedByYears(duration),
        );
  }

  Future<void> get wait {
    return Future<void>.delayed(
      asFractionalSeconds.roundToMicroseconds().asCoreDuration,
    );
  }

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
}

/// A [TimeDuration] with arbitrary precision.
final class FractionalSeconds extends TimeDuration {
  const FractionalSeconds(this.inFractionalSeconds);
  FractionalSeconds.fromNum(num seconds, {int scale = 8})
      : inFractionalSeconds = Fixed.fromNum(seconds, scale: scale);

  // `Fixed.zero` has a scale of 16, which we don't need.
  static final zero = FractionalSeconds(Fixed.fromInt(0, scale: 0));

  /// The number of seconds in a nanosecond.
  static final perNanosecond = Fixed.fromInt(1, scale: 9);

  /// The seconds in a nanosecond.
  static final nanosecond = FractionalSeconds(perNanosecond);

  /// The number of seconds in a microsecond.
  static final perMicrosecond = Fixed.fromInt(1, scale: 6);

  /// The seconds in a microsecond.
  static final microsecond = FractionalSeconds(perMicrosecond);

  /// The number of seconds in a millisecond.
  static final perMillisecond = Fixed.fromInt(1, scale: 3);

  /// The seconds in a millisecond.
  static final millisecond = FractionalSeconds(perMillisecond);

  /// The number of seconds in a second.
  static final perSecond = Fixed.fromInt(1, scale: 0);

  /// The seconds in a second.
  static final second = FractionalSeconds(perSecond);

  /// The number of seconds in a minute.
  static final perMinute = Fixed.fromInt(Seconds.perMinute, scale: 0);

  /// The seconds in a minute.
  static final minute = FractionalSeconds(perMinute);

  /// The number of seconds in an hour.
  static final perHour = Fixed.fromInt(Seconds.perHour, scale: 0);

  /// The seconds in an hour.
  static final hour = FractionalSeconds(perHour);

  /// The number of seconds in a normal day, i.e., a day with exactly 24 hours
  /// (no daylight savings time changes and no leap seconds).
  static final perNormalDay = Fixed.fromInt(Seconds.perNormalDay, scale: 0);

  /// The seconds in a normal day, i.e., a day with exactly 24 hours (no
  /// daylight savings time changes and no leap seconds).
  static final normalDay = FractionalSeconds(perNormalDay);

  /// The number of seconds in a normal week, i.e., a week where all days are
  /// exactly 24 hours long (no daylight savings time changes and no leap
  /// seconds).
  static final perNormalWeek = Fixed.fromInt(Seconds.perNormalWeek, scale: 0);

  /// The seconds in a normal week, i.e., a week where all days are exactly
  /// 24 hours long (no daylight savings time changes and no leap seconds).
  static final normalWeek = FractionalSeconds(perNormalWeek);

  /// The number of seconds in a normal (non-leap) year (365 days), i.e., a year
  /// where all days are exactly 24 hours long (no daylight savings time changes
  /// and no leap seconds).
  static final perNormalYear = Fixed.fromInt(Seconds.perNormalYear, scale: 0);

  /// The seconds in a normal (non-leap) year (365 days), i.e., a year where all
  /// days are exactly 24 hours long (no daylight savings time changes and no
  /// leap seconds).
  static final normalYear = FractionalSeconds(perNormalYear);

  /// The number of seconds in a leap year (366 days), i.e., a year where all
  /// days are exactly 24 hours long (no daylight savings time changes and no
  /// leap seconds).
  static final perNormalLeapYear =
      Fixed.fromInt(Seconds.perNormalLeapYear, scale: 0);

  /// The seconds in a leap year (366 days), i.e., a year where all days are
  /// exactly 24 hours long (no daylight savings time changes and no leap
  /// seconds).
  static final normalLeapYear = FractionalSeconds(perNormalLeapYear);

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
      timesFixed(Fixed.fromInt(factor, scale: 0));
  @override
  FractionalSeconds operator ~/(int divisor) {
    return FractionalSeconds(
      Fixed.fromBigInt(
        inFractionalSeconds.minorUnits ~/ BigInt.from(divisor),
        scale: inFractionalSeconds.scale,
      ),
    );
  }

  FractionalSeconds get half => FractionalSeconds(inFractionalSeconds.half);
  @override
  FractionalSeconds operator %(int divisor) {
    return FractionalSeconds(
      Fixed.fromBigInt(
        inFractionalSeconds.minorUnits % BigInt.from(divisor),
        scale: inFractionalSeconds.scale,
      ),
    );
  }

  FractionalSeconds moduloNum(
    num divisor, {
    int divisorPrecisionAfterComma = 8,
  }) {
    return FractionalSeconds(
      // TODO(JonasWanke): Is this modulo precise enough?
      inFractionalSeconds %
          Fixed.fromNum(divisor, scale: divisorPrecisionAfterComma),
    );
  }

  // TODO(JonasWanke): Is this modulo precise enough?
  Fixed moduloTimeDuration(TimeDuration divisor) =>
      inFractionalSeconds % divisor.inFractionalSeconds;

  @override
  FractionalSeconds remainder(int divisor) {
    return FractionalSeconds(
      Fixed.fromBigInt(
        inFractionalSeconds.minorUnits.remainder(BigInt.from(divisor)),
        scale: inFractionalSeconds.scale,
      ),
    );
  }

  FractionalSeconds remainderNum(
    num divisor, {
    int divisorPrecisionAfterComma = 8,
  }) {
    return FractionalSeconds(
      // TODO(JonasWanke): Is this remainder precise enough?
      inFractionalSeconds.remainder(
        Fixed.fromNum(divisor, scale: divisorPrecisionAfterComma),
      ),
    );
  }

  // TODO(JonasWanke): Is this remainder precise enough?
  Fixed remainderTimeDuration(TimeDuration divisor) =>
      inFractionalSeconds.remainder(divisor.inFractionalSeconds);

  @override
  FractionalSeconds get absolute => isNegative ? -this : this;

  @override
  String toString() {
    return inFractionalSeconds.abs == Fixed.one
        ? '$inFractionalSeconds second'
        : '$inFractionalSeconds seconds';
  }
}

/// Base class for [Nanoseconds] and larger durations like [Microseconds].
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

/// An integer number of nanoseconds.
final class Nanoseconds extends NanosecondsDuration {
  const Nanoseconds(this.inNanoseconds);

  /// The number of nanoseconds in a microsecond.
  static const perMicrosecond = 1000;

  /// The nanoseconds in a microsecond.
  static const microsecond = Nanoseconds(perMicrosecond);

  /// The number of nanoseconds in a millisecond.
  static const perMillisecond = perMicrosecond * Microseconds.perMillisecond;

  /// The nanoseconds in a millisecond.
  static const millisecond = Nanoseconds(perMillisecond);

  /// The number of nanoseconds in a second.
  static const perSecond = perMicrosecond * Microseconds.perSecond;

  /// The nanoseconds in a second.
  static const second = Nanoseconds(perSecond);

  /// The number of nanoseconds in a minute.
  static const perMinute = perMicrosecond * Microseconds.perMinute;

  /// The nanoseconds in a minute.
  static const minute = Nanoseconds(perMinute);

  /// The number of nanoseconds in an hour.
  static const perHour = perMicrosecond * Microseconds.perHour;

  /// The nanoseconds in an hour.
  static const hour = Nanoseconds(perHour);

  /// The number of nanoseconds in a normal day, i.e., a day with exactly
  /// 24 hours (no daylight savings time changes and no leap seconds).
  static const perNormalDay = perMicrosecond * Microseconds.perNormalDay;

  /// The nanoseconds in a normal day, i.e., a day with exactly 24 hours (no
  /// daylight savings time changes and no leap seconds).
  static const normalDay = Nanoseconds(perNormalDay);

  /// The number of nanoseconds in a normal week, i.e., a week where all days
  /// are exactly 24 hours long (no daylight savings time changes and no leap
  /// seconds).
  static const perNormalWeek = perMicrosecond * Microseconds.perNormalWeek;

  /// The nanoseconds in a normal week, i.e., a week where all days are exactly
  /// 24 hours long (no daylight savings time changes and no leap seconds).
  static const normalWeek = Nanoseconds(perNormalWeek);

  /// The number of nanoseconds in a normal (non-leap) year (365 days), i.e., a
  /// year where all days are exactly 24 hours long (no daylight savings time
  /// changes and no leap seconds).
  static const perNormalYear = perMicrosecond * Microseconds.perNormalYear;

  /// The nanoseconds in a normal (non-leap) year (365 days), i.e., a year where
  /// all days are exactly 24 hours long (no daylight savings time changes and
  /// no leap seconds).
  static const normalYear = Nanoseconds(perNormalYear);

  /// The number of nanoseconds in a leap year (366 days), i.e., a year where
  /// all days are exactly 24 hours long (no daylight savings time changes and
  /// no leap seconds).
  static const perNormalLeapYear =
      perMicrosecond * Microseconds.perNormalLeapYear;

  /// The nanoseconds in a leap year (366 days), i.e., a year where all days are
  /// exactly 24 hours long (no daylight savings time changes and no leap
  /// seconds).
  static const normalLeapYear = Nanoseconds(perNormalLeapYear);

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

/// Base class for [Microseconds] and larger durations like [Milliseconds].
abstract class MicrosecondsDuration extends NanosecondsDuration {
  const MicrosecondsDuration();

  Microseconds get asMicroseconds;
  int get inMicroseconds => asMicroseconds.inMicroseconds;
  @override
  Nanoseconds get asNanoseconds => Nanoseconds.microsecond * inMicroseconds;
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

/// An integer number of microseconds.
final class Microseconds extends MicrosecondsDuration {
  const Microseconds(this.inMicroseconds);

  Microseconds.fromCore(core.Duration duration)
      : inMicroseconds = duration.inMicroseconds;

  /// The number of microseconds in a millisecond.
  static const perMillisecond = 1000;

  /// The microseconds in a millisecond.
  static const millisecond = Microseconds(perMillisecond);

  /// The number of microseconds in a second.
  static const perSecond = perMillisecond * Milliseconds.perSecond;

  /// The microseconds in a second.
  static const second = Microseconds(perSecond);

  /// The number of microseconds in a minute.
  static const perMinute = perMillisecond * Milliseconds.perMinute;

  /// The microseconds in a minute.
  static const minute = Microseconds(perMinute);

  /// The number of microseconds in an hour.
  static const perHour = perMillisecond * Milliseconds.perHour;

  /// The microseconds in an hour.
  static const hour = Microseconds(perHour);

  /// The number of microseconds in a normal day, i.e., a day with exactly
  /// 24 hours (no daylight savings time changes and no leap seconds).
  static const perNormalDay = perMillisecond * Milliseconds.perNormalDay;

  /// The microseconds in a normal day, i.e., a day with exactly 24 hours (no
  /// daylight savings time changes and no leap seconds).
  static const normalDay = Microseconds(perNormalDay);

  /// The number of microseconds in a normal week, i.e., a week where all days
  /// are exactly 24 hours long (no daylight savings time changes and no leap
  /// seconds).
  static const perNormalWeek = perMillisecond * Milliseconds.perNormalWeek;

  /// The microseconds in a normal week, i.e., a week where all days are exactly
  /// 24 hours long (no daylight savings time changes and no leap seconds).
  static const normalWeek = Microseconds(perNormalWeek);

  /// The number of microseconds in a normal (non-leap) year (365 days), i.e., a
  /// year where all days are exactly 24 hours long (no daylight savings time
  /// changes and no leap seconds).
  static const perNormalYear = perMillisecond * Milliseconds.perNormalYear;

  /// The microseconds in a normal (non-leap) year (365 days), i.e., a year
  /// where all days are exactly 24 hours long (no daylight savings time changes
  /// and no leap seconds).
  static const normalYear = Microseconds(perNormalYear);

  /// The number of microseconds in a leap year (366 days), i.e., a year where
  /// all days are exactly 24 hours long (no daylight savings time changes and
  /// no leap seconds).
  static const perNormalLeapYear =
      perMillisecond * Milliseconds.perNormalLeapYear;

  /// The microseconds in a leap year (366 days), i.e., a year where all days
  /// are exactly 24 hours long (no daylight savings time changes and no leap
  /// seconds).
  static const normalLeapYear = Microseconds(perNormalLeapYear);

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

/// Base class for [Milliseconds] and larger durations like [Seconds].
abstract class MillisecondsDuration extends MicrosecondsDuration {
  const MillisecondsDuration();

  Milliseconds get asMilliseconds;
  int get inMilliseconds => asMilliseconds.inMilliseconds;
  @override
  Microseconds get asMicroseconds => Microseconds.millisecond * inMilliseconds;
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

/// An integer number of milliseconds.
final class Milliseconds extends MillisecondsDuration {
  const Milliseconds(this.inMilliseconds);

  /// The number of milliseconds in a second.
  static const perSecond = 1000;

  /// The milliseconds in a second.
  static const second = Milliseconds(perSecond);

  /// The number of milliseconds in a minute.
  static const perMinute = perSecond * Seconds.perMinute;

  /// The milliseconds in a minute.
  static const minute = Milliseconds(perMinute);

  /// The number of milliseconds in an hour.
  static const perHour = perSecond * Seconds.perHour;

  /// The milliseconds in an hour.
  static const hour = Milliseconds(perHour);

  /// The number of milliseconds in a normal day, i.e., a day with exactly
  /// 24 hours (no daylight savings time changes and no leap seconds).
  static const perNormalDay = perSecond * Seconds.perNormalDay;

  /// The milliseconds in a normal day, i.e., a day with exactly 24 hours (no
  /// daylight savings time changes and no leap seconds).
  static const normalDay = Milliseconds(perNormalDay);

  /// The number of milliseconds in a normal week, i.e., a week where all days
  /// are exactly 24 hours long (no daylight savings time changes and no leap
  /// seconds).
  static const perNormalWeek = perSecond * Seconds.perNormalDay;

  /// The milliseconds in a normal week, i.e., a week where all days are exactly
  /// 24 hours long (no daylight savings time changes and no leap seconds).
  static const normalWeek = Milliseconds(perNormalWeek);

  /// The number of milliseconds in a normal (non-leap) year (365 days), i.e., a
  /// year where all days are exactly 24 hours long (no daylight savings time
  /// changes and no leap seconds).
  static const perNormalYear = perSecond * Seconds.perNormalYear;

  /// The milliseconds in a normal (non-leap) year (365 days), i.e., a year
  /// where all days are exactly 24 hours long (no daylight savings time changes
  /// and no leap seconds).
  static const normalYear = Milliseconds(perNormalYear);

  /// The number of milliseconds in a leap year (366 days), i.e., a year where
  /// all days are exactly 24 hours long (no daylight savings time changes and
  /// no leap seconds).
  static const perNormalLeapYear = perSecond * Seconds.perNormalLeapYear;

  /// The milliseconds in a leap year (366 days), i.e., a year where all days
  /// are exactly 24 hours long (no daylight savings time changes and no leap
  /// seconds).
  static const normalLeapYear = Milliseconds(perNormalLeapYear);

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

/// Base class for [Seconds] and larger durations like [Minutes].
abstract class SecondsDuration extends MillisecondsDuration {
  const SecondsDuration();

  Seconds get asSeconds;
  int get inSeconds => asSeconds.inSeconds;
  @override
  Milliseconds get asMilliseconds => Milliseconds.second * inSeconds;
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

/// An integer number of seconds.
final class Seconds extends SecondsDuration {
  const Seconds(this.inSeconds);

  /// The number of seconds in a minute.
  static const perMinute = 60;

  /// The seconds in a minute.
  static const minute = Seconds(perMinute);

  /// The number of seconds in an hour.
  static const perHour = perMinute * Minutes.perHour;

  /// The seconds in an hour.
  static const hour = Seconds(perHour);

  /// The number of seconds in a normal day, i.e., a day with exactly 24 hours
  /// (no daylight savings time changes and no leap seconds).
  static const perNormalDay = perMinute * Minutes.perNormalDay;

  /// The seconds in a normal day, i.e., a day with exactly 24 hours (no
  /// daylight savings time changes and no leap seconds).
  static const normalDay = Seconds(perNormalDay);

  /// The number of seconds in a normal week, i.e., a week where all days are
  /// exactly 24 hours long (no daylight savings time changes and no leap
  /// seconds).
  static const perNormalWeek = perMinute * Minutes.perNormalWeek;

  /// The seconds in a normal week, i.e., a week where all days are exactly
  /// 24 hours long (no daylight savings time changes and no leap seconds).
  static const normalWeek = Seconds(perNormalWeek);

  /// The number of seconds in a normal (non-leap) year (365 days), i.e., a year
  /// where all days are exactly 24 hours long (no daylight savings time changes
  /// and no leap seconds).
  static const perNormalYear = perMinute * Minutes.perNormalYear;

  /// The seconds in a normal (non-leap) year (365 days), i.e., a year where all
  /// days are exactly 24 hours long (no daylight savings time changes and no
  /// leap seconds).
  static const normalYear = Seconds(perNormalYear);

  /// The number of seconds in a leap year (366 days), i.e., a year where all
  /// days are exactly 24 hours long (no daylight savings time changes and no
  /// leap seconds).
  static const perNormalLeapYear = perMinute * Minutes.perNormalLeapYear;

  /// The seconds in a leap year (366 days), i.e., a year where all days are
  /// exactly 24 hours long (no daylight savings time changes and no leap
  /// seconds).
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

/// Base class for [Minutes] and [Hours].
abstract class MinutesDuration extends SecondsDuration {
  const MinutesDuration();

  Minutes get asMinutes;
  int get inMinutes => asMinutes.inMinutes;
  @override
  Seconds get asSeconds => Seconds.minute * inMinutes;

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

/// An integer number of minutes.
final class Minutes extends MinutesDuration {
  const Minutes(this.inMinutes);

  /// The number of minutes in an hour.
  static const perHour = 60;

  /// The minutes in an hour.
  static const hour = Minutes(perHour);

  /// The number of minutes in a normal day, i.e., a day with exactly 24 hours
  /// (no daylight savings time changes and no leap seconds).
  static const perNormalDay = perHour * Hours.perNormalDay;

  /// The minutes in a normal day, i.e., a day with exactly 24 hours (no
  /// daylight savings time changes and no leap seconds).
  static const normalDay = Minutes(perNormalDay);

  /// The number of minutes in a normal week, i.e., a week where all days are
  /// exactly 24 hours long (no daylight savings time changes and no leap
  /// seconds).
  static const perNormalWeek = perHour * Hours.perNormalWeek;

  /// The minutes in a normal week, i.e., a week where all days are exactly
  /// 24 hours long (no daylight savings time changes and no leap seconds).
  static const normalWeek = Minutes(perNormalWeek);

  /// The number of minutes in a normal (non-leap) year (365 days), i.e., a year
  /// where all days are exactly 24 hours long (no daylight savings time changes
  /// and no leap seconds).
  static const perNormalYear = perHour * Hours.perNormalYear;

  /// The minutes in a normal (non-leap) year (365 days), i.e., a year where all
  /// days are exactly 24 hours long (no daylight savings time changes and no
  /// leap seconds).
  static const normalYear = Minutes(perNormalYear);

  /// The number of minutes in a leap year (366 days), i.e., a year where all
  /// days are exactly 24 hours long (no daylight savings time changes and no
  /// leap seconds).
  static const perNormalLeapYear = perHour * Hours.perNormalLeapYear;

  /// The minutes in a leap year (366 days), i.e., a year where all days are
  /// exactly 24 hours long (no daylight savings time changes and no leap
  /// seconds).
  static const normalLeapYear = Minutes(perNormalLeapYear);

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

/// An integer number of hours.
final class Hours extends MinutesDuration {
  const Hours(this.inHours);

  /// The number of hours in a normal day, i.e., a day with exactly 24 hours
  /// no daylight savings time changes and no leap seconds).
  static const perNormalDay = 24;

  /// The hours in a normal day, i.e., a day with exactly 24 hours (no daylight
  /// savings time changes and no leap seconds).
  static const normalDay = Hours(perNormalDay);

  /// The number of hours in a normal week, i.e., a week where all days are
  /// exactly 24 hours long (no daylight savings time changes and no leap
  /// seconds).
  static const perNormalWeek = perNormalDay * Days.perWeek;

  /// The hours in a normal week, i.e., a week where all days are exactly
  /// 24 hours long (no daylight savings time changes and no leap seconds).
  static const normalWeek = Hours(perNormalWeek);

  /// The number of hours in a normal (non-leap) year (365 days), i.e., a year
  /// where all days are exactly 24 hours long (no daylight savings time changes
  /// and no leap seconds).
  static const perNormalYear = perNormalDay * Days.perNormalYear;

  /// The hours in a normal (non-leap) year (365 days), i.e., a year where all
  /// days are exactly 24 hours long (no daylight savings time changes and no
  /// leap seconds).
  static const normalYear = Hours(perNormalYear);

  /// The number of hours in a leap year (366 days), i.e., a year where all days
  /// are exactly 24 hours long (no daylight savings time changes and no leap
  /// seconds).
  static const perNormalLeapYear = perNormalDay * Days.perLeapYear;

  /// The hours in a leap year (366 days), i.e., a year where all days are
  /// exactly 24 hours long (no daylight savings time changes and no leap
  /// seconds).
  static const normalLeapYear = Hours(perNormalLeapYear);

  final int inHours;

  @override
  Minutes get asMinutes => Minutes.hour * inHours;

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
