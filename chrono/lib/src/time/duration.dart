import 'dart:core' as core;
import 'dart:core';

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
/// - [Nanoseconds], which is the subclass with the highest precision.
abstract class TimeDuration extends Duration
    with ComparisonOperatorsFromComparable<TimeDuration>
    implements Comparable<TimeDuration> {
  const TimeDuration();

  // TODO(JonasWanke): add `lerp(…)`, `lerpNullable(…)` in other classes
  // TODO(JonasWanke): comments
  static Nanoseconds? lerpNullable(
    TimeDuration? a,
    TimeDuration? b,
    double t, {
    Rounding rounding = Rounding.nearestAwayFromZero,
  }) {
    return switch ((a?.asNanoseconds, b?.asNanoseconds)) {
      (null, null) => null,
      (null, final b?) => b.timesDouble(t, rounding: rounding),
      (final a?, null) => a.timesDouble(1 - t, rounding: rounding),
      (final a?, final b?) => lerp(a, b, t, rounding: rounding),
    };
  }

  static Nanoseconds lerp(
    TimeDuration a,
    TimeDuration b,
    double t, {
    Rounding rounding = Rounding.nearestAwayFromZero,
  }) {
    return a.asNanoseconds.timesDouble(1 - t, rounding: rounding) +
        b.asNanoseconds.timesDouble(t, rounding: rounding);
  }

  Nanoseconds get asNanoseconds;
  BigInt get inNanoseconds => asNanoseconds.inNanoseconds;

  (Microseconds, Nanoseconds) get splitMicrosNanos {
    final inNanoseconds = this.inNanoseconds;
    final microseconds =
        inNanoseconds ~/ BigInt.from(Nanoseconds.perMicrosecond);
    final nanoseconds =
        inNanoseconds - microseconds * BigInt.from(Nanoseconds.perMicrosecond);
    return (
      Microseconds(microseconds.toInt()),
      Nanoseconds.fromBigInt(nanoseconds)
    );
  }

  (Milliseconds, Microseconds, Nanoseconds) get splitMillisMicrosNanos {
    final (rawMicroseconds, nanoseconds) = splitMicrosNanos;
    final (milliseconds, microseconds) = rawMicroseconds.splitMillisMicros;
    return (milliseconds, microseconds, nanoseconds);
  }

  (Seconds, Nanoseconds) get splitSecondsNanos {
    final inNanoseconds = this.inNanoseconds;
    final seconds = inNanoseconds ~/ BigInt.from(Nanoseconds.perSecond);
    final nanoseconds =
        inNanoseconds - seconds * BigInt.from(Nanoseconds.perSecond);
    return (Seconds(seconds.toInt()), Nanoseconds.fromBigInt(nanoseconds));
  }

  (Seconds, Milliseconds, Microseconds, Nanoseconds)
      get splitSecondsMillisMicrosNanos {
    final (rawMilliseconds, microseconds, nanoseconds) = splitMillisMicrosNanos;
    final (seconds, milliseconds) = rawMilliseconds.splitSecondsMillis;
    return (seconds, milliseconds, microseconds, nanoseconds);
  }

  (Minutes, Seconds, Milliseconds, Microseconds, Nanoseconds)
      get splitMinutesSecondsMillisMicrosNanos {
    final (rawMilliseconds, microseconds, nanoseconds) = splitMillisMicrosNanos;
    final (minutes, seconds, milliseconds) =
        rawMilliseconds.splitMinutesSecondsMillis;
    return (minutes, seconds, milliseconds, microseconds, nanoseconds);
  }

  (Hours, Minutes, Seconds, Milliseconds, Microseconds, Nanoseconds)
      get splitHoursMinutesSecondsMillisMicrosNanos {
    final (rawMilliseconds, microseconds, nanoseconds) = splitMillisMicrosNanos;
    final (hours, minutes, seconds, milliseconds) =
        rawMilliseconds.splitHoursMinutesSecondsMillis;
    return (hours, minutes, seconds, milliseconds, microseconds, nanoseconds);
  }

  @override
  CompoundDuration get asCompoundDuration =>
      CompoundDuration(seconds: asNanoseconds);

  bool get isPositive => inNanoseconds > BigInt.zero;
  bool get isNonPositive => !isPositive;
  bool get isNegative => inNanoseconds.isNegative;
  bool get isNonNegative => !isNegative;

  @override
  TimeDuration operator -();

  @override
  TimeDuration operator *(int factor);
  Nanoseconds timesDouble(
    double factor, {
    Rounding rounding = Rounding.nearestAwayFromZero,
  }) =>
      Nanoseconds(rounding.round(inNanoseconds.toDouble() * factor));
  Nanoseconds timesBigInt(
    BigInt factor, {
    Rounding rounding = Rounding.nearestAwayFromZero,
  }) =>
      Nanoseconds.fromBigInt(inNanoseconds * factor);

  @override
  TimeDuration operator ~/(int divisor);
  double dividedByTimeDuration(TimeDuration divisor) =>
      inNanoseconds / divisor.inNanoseconds;
  Nanoseconds dividedByInt(
    int divisor, {
    Rounding rounding = Rounding.nearestAwayFromZero,
  }) =>
      dividedByBigInt(BigInt.from(divisor));
  Nanoseconds dividedByBigInt(
    BigInt divisor, {
    Rounding rounding = Rounding.nearestAwayFromZero,
  }) =>
      Nanoseconds(rounding.round(inNanoseconds / divisor));
  Nanoseconds dividedByDouble(
    double divisor, {
    Rounding rounding = Rounding.nearestAwayFromZero,
  }) =>
      Nanoseconds(rounding.round(inNanoseconds.toDouble() / divisor));

  @override
  TimeDuration operator %(int divisor);
  @override
  TimeDuration remainder(int divisor);

  TimeDuration get absolute => isNegative ? -this : this;

  Microseconds roundToMicroseconds({
    Rounding rounding = Rounding.nearestAwayFromZero,
  }) {
    return Microseconds(
      rounding.round(inNanoseconds / BigInt.from(Nanoseconds.perMicrosecond)),
    );
  }

  Milliseconds roundToMilliseconds({
    Rounding rounding = Rounding.nearestAwayFromZero,
  }) {
    return Milliseconds(
      rounding.round(inNanoseconds / BigInt.from(Nanoseconds.perMillisecond)),
    );
  }

  Seconds roundToSeconds({Rounding rounding = Rounding.nearestAwayFromZero}) {
    return Seconds(
      rounding.round(inNanoseconds / BigInt.from(Nanoseconds.perSecond)),
    );
  }

  Minutes roundToMinutes({Rounding rounding = Rounding.nearestAwayFromZero}) {
    return Minutes(
      rounding.round(inNanoseconds / BigInt.from(Nanoseconds.perMinute)),
    );
  }

  Hours roundToHours({Rounding rounding = Rounding.nearestAwayFromZero}) {
    return Hours(
      rounding.round(inNanoseconds / BigInt.from(Nanoseconds.perHour)),
    );
  }

  Days roundToNormalDays({Rounding rounding = Rounding.nearestAwayFromZero}) {
    return Days(
      rounding.round(inNanoseconds / BigInt.from(Nanoseconds.perNormalDay)),
    );
  }

  Weeks roundToNormalWeeks({
    Rounding rounding = Rounding.nearestAwayFromZero,
  }) {
    return Weeks(
      rounding.round(inNanoseconds / BigInt.from(Nanoseconds.perNormalWeek)),
    );
  }

  Years roundToNormalYears({
    Rounding rounding = Rounding.nearestAwayFromZero,
  }) {
    return Years(
      rounding.round(inNanoseconds / BigInt.from(Nanoseconds.perNormalYear)),
    );
  }

  Years roundToNormalLeapYears({
    Rounding rounding = Rounding.nearestAwayFromZero,
  }) {
    return Years(
      rounding
          .round(inNanoseconds / BigInt.from(Nanoseconds.perNormalLeapYear)),
    );
  }

  core.Duration roundToCoreDuration({
    Rounding rounding = Rounding.nearestAwayFromZero,
  }) {
    return core.Duration(
      microseconds: roundToMicroseconds(rounding: rounding).inMicroseconds,
    );
  }

  Nanoseconds roundToMultipleOf(
    TimeDuration duration, {
    Rounding rounding = Rounding.nearestAwayFromZero,
  }) =>
      duration.asNanoseconds * rounding.round(dividedByTimeDuration(duration));
  Microseconds roundToMultipleOfMicroseconds(
    MicrosecondsDuration duration, {
    Rounding rounding = Rounding.nearestAwayFromZero,
  }) =>
      duration.asMicroseconds * rounding.round(dividedByTimeDuration(duration));
  Milliseconds roundToMultipleOfMilliseconds(
    MillisecondsDuration duration, {
    Rounding rounding = Rounding.nearestAwayFromZero,
  }) =>
      duration.asMilliseconds * rounding.round(dividedByTimeDuration(duration));
  Seconds roundToMultipleOfSeconds(
    SecondsDuration duration, {
    Rounding rounding = Rounding.nearestAwayFromZero,
  }) =>
      duration.asSeconds * rounding.round(dividedByTimeDuration(duration));
  Minutes roundToMultipleOfMinutes(
    MinutesDuration duration, {
    Rounding rounding = Rounding.nearestAwayFromZero,
  }) =>
      duration.asMinutes * rounding.round(dividedByTimeDuration(duration));
  Hours roundToMultipleOfHours(
    Hours duration, {
    Rounding rounding = Rounding.nearestAwayFromZero,
  }) =>
      duration * rounding.round(dividedByTimeDuration(duration));

  Days roundToMultipleOfNormalDays(
    FixedDaysDuration duration, {
    Rounding rounding = Rounding.nearestAwayFromZero,
  }) {
    return duration.asDays *
        rounding.round(dividedByTimeDuration(duration.asNormalHours));
  }

  Weeks roundToMultipleOfNormalWeeks(
    Weeks duration, {
    Rounding rounding = Rounding.nearestAwayFromZero,
  }) {
    return duration *
        rounding.round(dividedByTimeDuration(duration.asNormalHours));
  }

  Years roundToMultipleOfNormalYears(
    Years duration, {
    Rounding rounding = Rounding.nearestAwayFromZero,
  }) {
    return duration *
        rounding.round(dividedByTimeDuration(duration.asNormalHours));
  }

  Years roundToMultipleOfNormalLeapYears(
    Years duration, {
    Rounding rounding = Rounding.nearestAwayFromZero,
  }) {
    return duration *
        rounding.round(dividedByTimeDuration(duration.asNormalHours));
  }

  /// Returns a [Future] that completes after this duration has passed.
  Future<void> get wait =>
      Future<void>.delayed(roundToMicroseconds().asCoreDuration);

  @override
  int compareTo(TimeDuration other) =>
      inNanoseconds.compareTo(other.inNanoseconds);
}

/// Base class for [Nanoseconds] and larger durations like [Microseconds].
// TODO(JonasWanke): Remove
abstract class NanosecondsDuration extends TimeDuration {
  const NanosecondsDuration();

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
  Nanoseconds(int inNanoseconds) : inNanoseconds = BigInt.from(inNanoseconds);
  const Nanoseconds.fromBigInt(this.inNanoseconds);

  /// The number of nanoseconds in a microsecond.
  static const perMicrosecond = 1000;

  /// The nanoseconds in a microsecond.
  static final microsecond = Nanoseconds(perMicrosecond);

  /// The number of nanoseconds in a millisecond.
  static const perMillisecond = perMicrosecond * Microseconds.perMillisecond;

  /// The nanoseconds in a millisecond.
  static final millisecond = Nanoseconds(perMillisecond);

  /// The number of nanoseconds in a second.
  static const perSecond = perMicrosecond * Microseconds.perSecond;

  /// The nanoseconds in a second.
  static final second = Nanoseconds(perSecond);

  /// The number of nanoseconds in a minute.
  static const perMinute = perMicrosecond * Microseconds.perMinute;

  /// The nanoseconds in a minute.
  static final minute = Nanoseconds(perMinute);

  /// The number of nanoseconds in an hour.
  static const perHour = perMicrosecond * Microseconds.perHour;

  /// The nanoseconds in an hour.
  static final hour = Nanoseconds(perHour);

  /// The number of nanoseconds in a normal day, i.e., a day with exactly
  /// 24 hours (no daylight savings time changes and no leap seconds).
  static const perNormalDay = perMicrosecond * Microseconds.perNormalDay;

  /// The nanoseconds in a normal day, i.e., a day with exactly 24 hours (no
  /// daylight savings time changes and no leap seconds).
  static final normalDay = Nanoseconds(perNormalDay);

  /// The number of nanoseconds in a normal week, i.e., a week where all days
  /// are exactly 24 hours long (no daylight savings time changes and no leap
  /// seconds).
  static const perNormalWeek = perMicrosecond * Microseconds.perNormalWeek;

  /// The nanoseconds in a normal week, i.e., a week where all days are exactly
  /// 24 hours long (no daylight savings time changes and no leap seconds).
  static final normalWeek = Nanoseconds(perNormalWeek);

  /// The number of nanoseconds in a normal (non-leap) year (365 days), i.e., a
  /// year where all days are exactly 24 hours long (no daylight savings time
  /// changes and no leap seconds).
  static const perNormalYear = perMicrosecond * Microseconds.perNormalYear;

  /// The nanoseconds in a normal (non-leap) year (365 days), i.e., a year where
  /// all days are exactly 24 hours long (no daylight savings time changes and
  /// no leap seconds).
  static final normalYear = Nanoseconds(perNormalYear);

  /// The number of nanoseconds in a leap year (366 days), i.e., a year where
  /// all days are exactly 24 hours long (no daylight savings time changes and
  /// no leap seconds).
  static const perNormalLeapYear =
      perMicrosecond * Microseconds.perNormalLeapYear;

  /// The nanoseconds in a leap year (366 days), i.e., a year where all days are
  /// exactly 24 hours long (no daylight savings time changes and no leap
  /// seconds).
  static final normalLeapYear = Nanoseconds(perNormalLeapYear);

  @override
  final BigInt inNanoseconds;

  @override
  Nanoseconds get asNanoseconds => this;

  Nanoseconds operator +(TimeDuration duration) =>
      Nanoseconds.fromBigInt(inNanoseconds + duration.inNanoseconds);
  Nanoseconds operator -(TimeDuration duration) =>
      Nanoseconds.fromBigInt(inNanoseconds - duration.inNanoseconds);
  @override
  Nanoseconds operator -() => Nanoseconds.fromBigInt(-inNanoseconds);
  @override
  Nanoseconds operator *(int factor) =>
      Nanoseconds.fromBigInt(inNanoseconds * BigInt.from(factor));
  @override
  Nanoseconds operator ~/(int divisor) =>
      Nanoseconds.fromBigInt(inNanoseconds ~/ BigInt.from(divisor));

  @override
  Nanoseconds operator %(int divisor) =>
      Nanoseconds.fromBigInt(inNanoseconds % BigInt.from(divisor));
  @override
  Nanoseconds remainder(int divisor) =>
      Nanoseconds.fromBigInt(inNanoseconds.remainder(BigInt.from(divisor)));

  @override
  Nanoseconds get absolute => isNegative ? -this : this;

  @override
  String toString() {
    return inNanoseconds.abs() == BigInt.one
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

  (Milliseconds, Microseconds) get splitMillisMicros {
    final inMicroseconds = this.inMicroseconds;
    final milliseconds = inMicroseconds ~/ Microseconds.perMillisecond;
    final microseconds =
        inMicroseconds - milliseconds * Microseconds.perMillisecond;
    return (Milliseconds(milliseconds), Microseconds(microseconds));
  }

  (Seconds, Microseconds) get splitSecondsMicros {
    final inMicroseconds = this.inMicroseconds;
    final seconds = inMicroseconds ~/ Microseconds.perSecond;
    final microseconds = inMicroseconds - seconds * Microseconds.perSecond;
    return (Seconds(seconds), Microseconds(microseconds));
  }

  (Seconds, Milliseconds, Microseconds) get splitSecondsMillisMicros {
    final (rawMilliseconds, microseconds) = splitMillisMicros;
    final (seconds, milliseconds) = rawMilliseconds.splitSecondsMillis;
    return (seconds, milliseconds, microseconds);
  }

  (Minutes, Seconds, Milliseconds, Microseconds)
      get splitMinutesSecondsMillisMicros {
    final (rawMilliseconds, microseconds) = splitMillisMicros;
    final (minutes, seconds, milliseconds) =
        rawMilliseconds.splitMinutesSecondsMillis;
    return (minutes, seconds, milliseconds, microseconds);
  }

  (Hours, Minutes, Seconds, Milliseconds, Microseconds)
      get splitHoursMinutesSecondsMillisMicros {
    final (rawMilliseconds, microseconds) = splitMillisMicros;
    final (hours, minutes, seconds, milliseconds) =
        rawMilliseconds.splitHoursMinutesSecondsMillis;
    return (hours, minutes, seconds, milliseconds, microseconds);
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

  (Seconds, Milliseconds) get splitSecondsMillis {
    final inMilliseconds = this.inMilliseconds;
    final seconds = inMilliseconds ~/ Milliseconds.perSecond;
    final microseconds = inMilliseconds - seconds * Milliseconds.perSecond;
    return (Seconds(seconds), Milliseconds(microseconds));
  }

  (Minutes, Seconds, Milliseconds) get splitMinutesSecondsMillis {
    final (rawSeconds, milliseconds) = splitSecondsMillis;
    final (minutes, seconds) = rawSeconds.splitMinutesSeconds;
    return (minutes, seconds, milliseconds);
  }

  (Hours, Minutes, Seconds, Milliseconds) get splitHoursMinutesSecondsMillis {
    final (rawSeconds, milliseconds) = splitSecondsMillis;
    final (hours, minutes, seconds) = rawSeconds.splitHoursMinutesSeconds;
    return (hours, minutes, seconds, milliseconds);
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

  (Minutes, Seconds) get splitMinutesSeconds {
    final asSeconds = this.asSeconds;
    final minutes = Minutes(asSeconds.inSeconds ~/ Seconds.perMinute);
    final seconds = asSeconds.remainder(Seconds.perMinute);
    return (minutes, seconds);
  }

  (Hours, Minutes, Seconds) get splitHoursMinutesSeconds {
    final (asMinutes, seconds) = splitMinutesSeconds;
    final (hours, minutes) = asMinutes.splitHoursMinutes;
    return (hours, minutes, seconds);
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

  (Hours, Minutes) get splitHoursMinutes {
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
