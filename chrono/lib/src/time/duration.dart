import '../date/duration.dart';
import '../date_time/duration.dart';
import '../rounding.dart';
import '../utils.dart';

// ignore_for_file: binary-expression-operand-order

/// A [CDuration] that is of a fixed length.
///
/// See also:
///
/// - [CalendarDuration], which covers durations based on an integer number of
///   days or months.
/// - [CDuration], which is the base class for all durations.
class TimeDelta extends CDuration
    with ComparisonOperatorsFromComparable<TimeDelta>
    implements Comparable<TimeDelta> {
  factory TimeDelta({
    int normalLeapYears = 0,
    int normalYears = 0,
    int normalWeeks = 0,
    int normalDays = 0,
    int hours = 0,
    int minutes = 0,
    int seconds = 0,
    int millis = 0,
    int micros = 0,
    int nanos = 0,
  }) {
    var totalSeconds =
        normalLeapYears * secondsPerNormalLeapYear +
        normalYears * secondsPerNormalYear +
        normalWeeks * secondsPerNormalWeek +
        normalDays * secondsPerNormalDay +
        hours * secondsPerHour +
        minutes * secondsPerMinute +
        seconds +
        millis ~/ millisPerSecond +
        micros ~/ microsPerSecond +
        nanos ~/ nanosPerSecond;
    var subSecondNanos =
        millis.remainder(millisPerSecond) * nanosPerMillisecond +
        micros.remainder(microsPerSecond) * nanosPerMicrosecond +
        nanos.remainder(nanosPerSecond);
    totalSeconds += subSecondNanos ~/ nanosPerSecond;
    subSecondNanos = subSecondNanos.remainder(nanosPerSecond);
    if (totalSeconds > 0 && subSecondNanos < 0) {
      totalSeconds -= 1;
      subSecondNanos += nanosPerSecond;
    } else if (totalSeconds < 0 && subSecondNanos > 0) {
      totalSeconds += 1;
      subSecondNanos -= nanosPerSecond;
    }
    return TimeDelta.raw(totalSeconds, subSecondNanos);
  }
  const TimeDelta.raw(this.totalSeconds, this.subSecondNanos)
    : assert(
        totalSeconds >= 0 && subSecondNanos >= 0 ||
            totalSeconds <= 0 && subSecondNanos <= 0,
      ),
      assert(
        (subSecondNanos < 0 ? -subSecondNanos : subSecondNanos) <
            nanosPerSecond,
      );

  factory TimeDelta.fromCore(Duration duration) =>
      TimeDelta(micros: duration.inMicroseconds);

  // TODO(JonasWanke): add `lerp(…)`, `lerpNullable(…)` in other classes
  // TODO(JonasWanke): comments
  static TimeDelta? lerpNullable(
    TimeDelta? a,
    TimeDelta? b,
    double t, {
    Rounding rounding = Rounding.nearestAwayFromZero,
  }) {
    return switch ((a, b)) {
      (null, null) => null,
      (null, final b?) => b.timesDouble(t, rounding: rounding),
      (final a?, null) => a.timesDouble(1 - t, rounding: rounding),
      (final a?, final b?) => lerp(a, b, t, rounding: rounding),
    };
  }

  static TimeDelta lerp(
    TimeDelta a,
    TimeDelta b,
    double t, {
    Rounding rounding = Rounding.nearestAwayFromZero,
  }) {
    return a.timesDouble(1 - t, rounding: rounding) +
        b.timesDouble(t, rounding: rounding);
  }

  // Nanos

  /// The number of nanoseconds in a microsecond.
  static const nanosPerMicrosecond = 1000;

  /// The number of nanoseconds in a millisecond.
  static const nanosPerMillisecond = nanosPerMicrosecond * microsPerMillisecond;

  /// The number of nanoseconds in a second.
  static const nanosPerSecond = nanosPerMicrosecond * microsPerSecond;

  /// The number of nanoseconds in a minute.
  static const nanosPerMinute = nanosPerMicrosecond * microsPerMinute;

  /// The number of nanoseconds in an hour.
  static const nanosPerHour = nanosPerMicrosecond * microsPerHour;

  /// The number of nanoseconds in a normal day, i.e., a day with exactly
  /// 24 hours (no daylight savings time changes and no leap seconds).
  static const nanosPerNormalDay = nanosPerMicrosecond * microsPerNormalDay;

  /// The number of nanoseconds in a normal week, i.e., a week where all days
  /// are exactly 24 hours long (no daylight savings time changes and no leap
  /// seconds).
  static const nanosPerNormalWeek = nanosPerMicrosecond * microsPerNormalWeek;

  /// The number of nanoseconds in a normal (non-leap) year (365 days), i.e., a
  /// year where all days are exactly 24 hours long (no daylight savings time
  /// changes and no leap seconds).
  static const nanosPerNormalYear = nanosPerMicrosecond * microsPerNormalYear;

  /// The number of nanoseconds in a leap year (366 days), i.e., a year where
  /// all days are exactly 24 hours long (no daylight savings time changes and
  /// no leap seconds).
  static const nanosPerNormalLeapYear =
      nanosPerMicrosecond * microsPerNormalLeapYear;

  // Micros

  /// The number of microseconds in a millisecond.
  static const microsPerMillisecond = 1000;

  /// The number of microseconds in a second.
  static const microsPerSecond = microsPerMillisecond * millisPerSecond;

  /// The number of microseconds in a minute.
  static const microsPerMinute = microsPerMillisecond * millisPerMinute;

  /// The number of microseconds in an hour.
  static const microsPerHour = microsPerMillisecond * millisPerHour;

  /// The number of microseconds in a normal day, i.e., a day with exactly
  /// 24 hours (no daylight savings time changes and no leap seconds).
  static const microsPerNormalDay = microsPerMillisecond * millisPerNormalDay;

  /// The number of microseconds in a normal week, i.e., a week where all days
  /// are exactly 24 hours long (no daylight savings time changes and no leap
  /// seconds).
  static const microsPerNormalWeek = microsPerMillisecond * millisPerNormalWeek;

  /// The number of microseconds in a normal (non-leap) year (365 days), i.e., a
  /// year where all days are exactly 24 hours long (no daylight savings time
  /// changes and no leap seconds).
  static const microsPerNormalYear = microsPerMillisecond * millisPerNormalYear;

  /// The number of microseconds in a leap year (366 days), i.e., a year where
  /// all days are exactly 24 hours long (no daylight savings time changes and
  /// no leap seconds).
  static const microsPerNormalLeapYear =
      microsPerMillisecond * millisPerNormalLeapYear;

  // Millis

  /// The number of milliseconds in a second.
  static const millisPerSecond = 1000;

  /// The number of milliseconds in a minute.
  static const millisPerMinute = millisPerSecond * secondsPerMinute;

  /// The number of milliseconds in an hour.
  static const millisPerHour = millisPerSecond * secondsPerHour;

  /// The number of milliseconds in a normal day, i.e., a day with exactly
  /// 24 hours (no daylight savings time changes and no leap seconds).
  static const millisPerNormalDay = millisPerSecond * secondsPerNormalDay;

  /// The number of milliseconds in a normal week, i.e., a week where all days
  /// are exactly 24 hours long (no daylight savings time changes and no leap
  /// seconds).
  static const millisPerNormalWeek = millisPerSecond * secondsPerNormalDay;

  /// The number of milliseconds in a normal (non-leap) year (365 days), i.e., a
  /// year where all days are exactly 24 hours long (no daylight savings time
  /// changes and no leap seconds).
  static const millisPerNormalYear = millisPerSecond * secondsPerNormalYear;

  /// The number of milliseconds in a leap year (366 days), i.e., a year where
  /// all days are exactly 24 hours long (no daylight savings time changes and
  /// no leap seconds).
  static const millisPerNormalLeapYear =
      millisPerSecond * secondsPerNormalLeapYear;

  // Seconds

  /// The number of seconds in a minute.
  static const secondsPerMinute = 60;

  /// The number of seconds in an hour.
  static const secondsPerHour = secondsPerMinute * minutesPerHour;

  /// The number of seconds in a normal day, i.e., a day with exactly 24 hours
  /// (no daylight savings time changes and no leap seconds).
  static const secondsPerNormalDay = secondsPerMinute * minutesPerNormalDay;

  /// The number of seconds in a normal week, i.e., a week where all days are
  /// exactly 24 hours long (no daylight savings time changes and no leap
  /// seconds).
  static const secondsPerNormalWeek = secondsPerMinute * minutesPerNormalWeek;

  /// The number of seconds in a normal (non-leap) year (365 days), i.e., a year
  /// where all days are exactly 24 hours long (no daylight savings time changes
  /// and no leap seconds).
  static const secondsPerNormalYear = secondsPerMinute * minutesPerNormalYear;

  /// The number of seconds in a leap year (366 days), i.e., a year where all
  /// days are exactly 24 hours long (no daylight savings time changes and no
  /// leap seconds).
  static const secondsPerNormalLeapYear =
      secondsPerMinute * minutesPerNormalLeapYear;

  // Minutes

  /// The number of minutes in an hour.
  static const minutesPerHour = 60;

  /// The number of minutes in a normal day, i.e., a day with exactly 24 hours
  /// (no daylight savings time changes and no leap seconds).
  static const minutesPerNormalDay = minutesPerHour * hoursPerNormalDay;

  /// The number of minutes in a normal week, i.e., a week where all days are
  /// exactly 24 hours long (no daylight savings time changes and no leap
  /// seconds).
  static const minutesPerNormalWeek = minutesPerHour * hoursPerNormalWeek;

  /// The number of minutes in a normal (non-leap) year (365 days), i.e., a year
  /// where all days are exactly 24 hours long (no daylight savings time changes
  /// and no leap seconds).
  static const minutesPerNormalYear = minutesPerHour * hoursPerNormalYear;

  /// The number of minutes in a leap year (366 days), i.e., a year where all
  /// days are exactly 24 hours long (no daylight savings time changes and no
  /// leap seconds).
  static const minutesPerNormalLeapYear =
      minutesPerHour * hoursPerNormalLeapYear;

  // Hours

  /// The number of hours in a normal day, i.e., a day with exactly 24 hours
  /// no daylight savings time changes and no leap seconds).
  static const hoursPerNormalDay = 24;

  /// The number of hours in a normal week, i.e., a week where all days are
  /// exactly 24 hours long (no daylight savings time changes and no leap
  /// seconds).
  static const hoursPerNormalWeek = hoursPerNormalDay * Days.perWeek;

  /// The number of hours in a normal (non-leap) year (365 days), i.e., a year
  /// where all days are exactly 24 hours long (no daylight savings time changes
  /// and no leap seconds).
  static const hoursPerNormalYear = hoursPerNormalDay * Days.perNormalYear;

  /// The number of hours in a leap year (366 days), i.e., a year where all days
  /// are exactly 24 hours long (no daylight savings time changes and no leap
  /// seconds).
  static const hoursPerNormalLeapYear = hoursPerNormalDay * Days.perLeapYear;

  int get totalHours => totalSeconds ~/ secondsPerHour;
  int get totalMinutes => totalSeconds ~/ secondsPerMinute;
  final int totalSeconds;
  int get totalMillis =>
      totalSeconds * millisPerSecond + subSecondNanos ~/ nanosPerMillisecond;
  int get totalMicros =>
      totalSeconds * microsPerSecond + subSecondNanos ~/ nanosPerMicrosecond;
  int get totalNanos => totalSeconds * nanosPerSecond + subSecondNanos;

  final int subSecondNanos;

  (int, int) splitMicrosNanos() {
    final (micros, nanos) = _splitNanosInMicrosNanos();
    return (totalSeconds * microsPerSecond + micros, nanos);
  }

  (int, int, int) splitMillisMicrosNanos() {
    final (millis, micros, nanos) = _splitNanosInMillisMicrosNanos();
    return (totalSeconds * millisPerSecond + millis, micros, nanos);
  }

  (int, int) splitSecondsNanos() => (totalSeconds, subSecondNanos);

  (int, int, int, int) splitSecondsMillisMicrosNanos() {
    final (millis, micros, nanos) = _splitNanosInMillisMicrosNanos();
    return (totalSeconds, millis, micros, nanos);
  }

  (int, int, int) splitMinutesSecondsNanos() {
    final (minutes, seconds) = _splitSecondsInMinutesSeconds();
    return (minutes, seconds, subSecondNanos);
  }

  (int, int, int, int, int) splitMinutesSecondsMillisMicrosNanos() {
    final (minutes, seconds) = _splitSecondsInMinutesSeconds();
    final (millis, micros, nanos) = _splitNanosInMillisMicrosNanos();
    return (minutes, seconds, millis, micros, nanos);
  }

  (int, int, int, int) splitHoursMinutesSecondsNanos() {
    final (hours, minutes, seconds) = _splitSecondsInHoursMinutesSeconds();
    return (hours, minutes, seconds, subSecondNanos);
  }

  (int, int, int, int, int, int) splitHoursMinutesSecondsMillisMicrosNanos() {
    final (hours, minutes, seconds) = _splitSecondsInHoursMinutesSeconds();
    final (millis, micros, nanos) = _splitNanosInMillisMicrosNanos();
    return (hours, minutes, seconds, millis, micros, nanos);
  }

  (int, int) _splitNanosInMicrosNanos() {
    final micros = subSecondNanos ~/ nanosPerMicrosecond;
    return (micros, subSecondNanos - micros * nanosPerMicrosecond);
  }

  (int, int, int) _splitNanosInMillisMicrosNanos() {
    final (rawMicros, nanos) = _splitNanosInMicrosNanos();
    final millis = rawMicros ~/ microsPerMillisecond;
    return (millis, rawMicros - millis * microsPerMillisecond, nanos);
  }

  (int, int) _splitSecondsInMinutesSeconds() {
    final minutes = totalSeconds ~/ secondsPerMinute;
    final seconds = totalSeconds - minutes * secondsPerMinute;
    return (minutes, seconds);
  }

  (int, int, int) _splitSecondsInHoursMinutesSeconds() {
    final (rawMinutes, seconds) = _splitSecondsInMinutesSeconds();
    final hours = totalMinutes ~/ minutesPerHour;
    return (hours, rawMinutes - hours * minutesPerHour, seconds);
  }

  @override
  CompoundDuration get asCompoundDuration => CompoundDuration(time: this);

  @override
  bool get isZero => totalSeconds == 0 && subSecondNanos == 0;
  bool get isPositive => totalSeconds > 0 || subSecondNanos > 0;
  bool get isNonPositive => !isPositive;
  bool get isNegative => totalSeconds < 0 || subSecondNanos < 0;
  bool get isNonNegative => !isNegative;

  TimeDelta operator +(TimeDelta other) {
    return TimeDelta(
      seconds: totalSeconds + other.totalSeconds,
      nanos: subSecondNanos + other.subSecondNanos,
    );
  }

  TimeDelta operator -(TimeDelta other) {
    return TimeDelta(
      seconds: totalSeconds - other.totalSeconds,
      nanos: subSecondNanos - other.subSecondNanos,
    );
  }

  @override
  TimeDelta operator -() => TimeDelta.raw(-totalSeconds, -subSecondNanos);
  TimeDelta get absolute => isNegative ? -this : this;

  @override
  TimeDelta operator *(int factor) =>
      TimeDelta(seconds: totalSeconds * factor, nanos: subSecondNanos * factor);
  // TODO(JonasWanke): avoid `totalNanos` to avoid overflows
  TimeDelta timesDouble(
    double factor, {
    Rounding rounding = Rounding.nearestAwayFromZero,
  }) => TimeDelta(nanos: rounding.round(totalNanos * factor));

  @override
  TimeDelta operator ~/(int divisor) {
    final totalSeconds = this.totalSeconds ~/ divisor;
    final carry = this.totalSeconds - totalSeconds * divisor;
    final subSecondNanos =
        (carry * nanosPerSecond + this.subSecondNanos) ~/ divisor;
    return TimeDelta(seconds: totalSeconds, nanos: subSecondNanos);
  }

  // TODO(JonasWanke): avoid `totalNanos` to avoid overflows
  double dividedByTimeDelta(TimeDelta divisor) =>
      totalNanos / divisor.totalNanos;
  // Nanoseconds dividedByInt(
  //   int divisor, {
  //   Rounding rounding = Rounding.nearestAwayFromZero,
  // }) => Nanoseconds(rounding.round(inNanoseconds / divisor));
  // Nanoseconds dividedByDouble(
  //   double divisor, {
  //   Rounding rounding = Rounding.nearestAwayFromZero,
  // }) => Nanoseconds(rounding.round(inNanoseconds.toDouble() / divisor));

  // TODO(JonasWanke): avoid `totalNanos` to avoid overflows
  @override
  TimeDelta operator %(int divisor) => TimeDelta(nanos: totalNanos % divisor);
  // TODO(JonasWanke): avoid `totalNanos` to avoid overflows
  @override
  TimeDelta remainder(int divisor) =>
      TimeDelta(nanos: totalNanos.remainder(divisor));

  int roundToMicroseconds({Rounding rounding = Rounding.nearestAwayFromZero}) =>
      rounding.round(totalNanos / nanosPerMicrosecond);
  int roundToMilliseconds({Rounding rounding = Rounding.nearestAwayFromZero}) =>
      rounding.round(totalNanos / nanosPerMillisecond);
  int roundToSeconds({Rounding rounding = Rounding.nearestAwayFromZero}) =>
      rounding.round(totalNanos / nanosPerSecond);
  int roundToMinutes({Rounding rounding = Rounding.nearestAwayFromZero}) =>
      rounding.round(totalNanos / nanosPerMinute);
  int roundToHours({Rounding rounding = Rounding.nearestAwayFromZero}) =>
      rounding.round(totalNanos / nanosPerHour);
  Days roundToNormalDays({Rounding rounding = Rounding.nearestAwayFromZero}) =>
      Days(rounding.round(totalNanos / nanosPerNormalDay));
  Weeks roundToNormalWeeks({
    Rounding rounding = Rounding.nearestAwayFromZero,
  }) => Weeks(rounding.round(totalNanos / nanosPerNormalWeek));
  Years roundToNormalYears({
    Rounding rounding = Rounding.nearestAwayFromZero,
  }) => Years(rounding.round(totalNanos / nanosPerNormalYear));
  Years roundToNormalLeapYears({
    Rounding rounding = Rounding.nearestAwayFromZero,
  }) => Years(rounding.round(totalNanos / nanosPerNormalLeapYear));

  Duration roundToCoreDuration({
    Rounding rounding = Rounding.nearestAwayFromZero,
  }) => Duration(microseconds: roundToMicroseconds(rounding: rounding));

  TimeDelta roundToMultipleOf(
    TimeDelta duration, {
    Rounding rounding = Rounding.nearestAwayFromZero,
  }) => duration * rounding.round(dividedByTimeDelta(duration));

  Days roundToMultipleOfNormalDays(
    DaysDuration duration, {
    Rounding rounding = Rounding.nearestAwayFromZero,
  }) {
    return duration.asDays *
        rounding.round(dividedByTimeDelta(duration.asTime));
  }

  Weeks roundToMultipleOfNormalWeeks(
    Weeks duration, {
    Rounding rounding = Rounding.nearestAwayFromZero,
  }) {
    return duration * rounding.round(dividedByTimeDelta(duration.asTime));
  }

  Years roundToMultipleOfNormalYears(
    Years duration, {
    Rounding rounding = Rounding.nearestAwayFromZero,
  }) {
    return duration * rounding.round(dividedByTimeDelta(duration.asNormalTime));
  }

  Years roundToMultipleOfNormalLeapYears(
    Years duration, {
    Rounding rounding = Rounding.nearestAwayFromZero,
  }) {
    return duration *
        rounding.round(dividedByTimeDelta(duration.asNormalLeapTime));
  }

  /// Returns a [Future] that completes after this duration has passed.
  Future<void> get wait => Future<void>.delayed(roundToCoreDuration());

  @override
  int compareTo(TimeDelta other) {
    final result = totalSeconds.compareTo(other.totalSeconds);
    if (result != 0) return result;

    return subSecondNanos.compareTo(other.subSecondNanos);
  }
}
