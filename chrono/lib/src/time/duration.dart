import 'package:meta/meta.dart';

import '../codec.dart';
import '../date/duration.dart';
import '../date_time/duration.dart';
import '../rounding.dart';
import '../utils.dart';

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
        millis.remainder(millisPerSecond) * nanosPerMilli +
        micros.remainder(microsPerSecond) * nanosPerMicro +
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
  static const nanosPerMicro = 1000;

  /// The number of nanoseconds in a millisecond.
  static const nanosPerMilli = nanosPerMicro * microsPerMilli;

  /// The number of nanoseconds in a second.
  static const nanosPerSecond = nanosPerMicro * microsPerSecond;

  /// The number of nanoseconds in a minute.
  static const nanosPerMinute = nanosPerMicro * microsPerMinute;

  /// The number of nanoseconds in an hour.
  static const nanosPerHour = nanosPerMicro * microsPerHour;

  /// The number of nanoseconds in a normal day, i.e., a day with exactly
  /// 24 hours (no daylight savings time changes and no leap seconds).
  static const nanosPerNormalDay = nanosPerMicro * microsPerNormalDay;

  /// The number of nanoseconds in a normal week, i.e., a week where all days
  /// are exactly 24 hours long (no daylight savings time changes and no leap
  /// seconds).
  static const nanosPerNormalWeek = nanosPerMicro * microsPerNormalWeek;

  /// The number of nanoseconds in a normal (non-leap) year (365 days), i.e., a
  /// year where all days are exactly 24 hours long (no daylight savings time
  /// changes and no leap seconds).
  static const nanosPerNormalYear = nanosPerMicro * microsPerNormalYear;

  /// The number of nanoseconds in a leap year (366 days), i.e., a year where
  /// all days are exactly 24 hours long (no daylight savings time changes and
  /// no leap seconds).
  static const nanosPerNormalLeapYear = nanosPerMicro * microsPerNormalLeapYear;

  // Micros

  /// The number of microseconds in a millisecond.
  static const microsPerMilli = 1000;

  /// The number of microseconds in a second.
  static const microsPerSecond = microsPerMilli * millisPerSecond;

  /// The number of microseconds in a minute.
  static const microsPerMinute = microsPerMilli * millisPerMinute;

  /// The number of microseconds in an hour.
  static const microsPerHour = microsPerMilli * millisPerHour;

  /// The number of microseconds in a normal day, i.e., a day with exactly
  /// 24 hours (no daylight savings time changes and no leap seconds).
  static const microsPerNormalDay = microsPerMilli * millisPerNormalDay;

  /// The number of microseconds in a normal week, i.e., a week where all days
  /// are exactly 24 hours long (no daylight savings time changes and no leap
  /// seconds).
  static const microsPerNormalWeek = microsPerMilli * millisPerNormalWeek;

  /// The number of microseconds in a normal (non-leap) year (365 days), i.e., a
  /// year where all days are exactly 24 hours long (no daylight savings time
  /// changes and no leap seconds).
  static const microsPerNormalYear = microsPerMilli * millisPerNormalYear;

  /// The number of microseconds in a leap year (366 days), i.e., a year where
  /// all days are exactly 24 hours long (no daylight savings time changes and
  /// no leap seconds).
  static const microsPerNormalLeapYear =
      microsPerMilli * millisPerNormalLeapYear;

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
      totalSeconds * millisPerSecond + subSecondNanos ~/ nanosPerMilli;
  int get totalMicros =>
      totalSeconds * microsPerSecond + subSecondNanos ~/ nanosPerMicro;
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

  (int, int) splitHoursMinutes({
    Rounding rounding = Rounding.nearestAwayFromZero,
  }) {
    final (hours, minutes, _) = TimeDelta(
      minutes: roundToMinutes(rounding: rounding),
    )._splitSecondsInHoursMinutesSeconds();
    return (hours, minutes);
  }

  (int, int, int) splitHoursMinutesSeconds({
    Rounding rounding = Rounding.nearestAwayFromZero,
  }) {
    return TimeDelta(
      seconds: roundToSeconds(rounding: rounding),
    )._splitSecondsInHoursMinutesSeconds();
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
    final micros = subSecondNanos ~/ nanosPerMicro;
    return (micros, subSecondNanos - micros * nanosPerMicro);
  }

  (int, int, int) _splitNanosInMillisMicrosNanos() {
    final (rawMicros, nanos) = _splitNanosInMicrosNanos();
    final millis = rawMicros ~/ microsPerMilli;
    return (millis, rawMicros - millis * microsPerMilli, nanos);
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
  TimeDelta operator %(TimeDelta divisor) =>
      TimeDelta(nanos: totalNanos % divisor.totalNanos);
  // TODO(JonasWanke): avoid `totalNanos` to avoid overflows
  TimeDelta remainder(TimeDelta divisor) =>
      TimeDelta(nanos: totalNanos.remainder(divisor.totalNanos));

  int roundToMicros({Rounding rounding = Rounding.nearestAwayFromZero}) =>
      rounding.round(totalNanos / nanosPerMicro);
  int roundToMillis({Rounding rounding = Rounding.nearestAwayFromZero}) =>
      rounding.round(totalNanos / nanosPerMilli);
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
  }) => Duration(microseconds: roundToMicros(rounding: rounding));
  TimeDelta roundToMultipleOf(
    TimeDelta duration, {
    Rounding rounding = Rounding.nearestAwayFromZero,
  }) => duration * rounding.round(dividedByTimeDelta(duration));
  Days roundToMultipleOfNormalDays(
    DaysDuration duration, {
    Rounding rounding = Rounding.nearestAwayFromZero,
  }) => duration.asDays * rounding.round(dividedByTimeDelta(duration.asTime));
  Weeks roundToMultipleOfNormalWeeks(
    Weeks duration, {
    Rounding rounding = Rounding.nearestAwayFromZero,
  }) => duration * rounding.round(dividedByTimeDelta(duration.asTime));
  Years roundToMultipleOfNormalYears(
    Years duration, {
    Rounding rounding = Rounding.nearestAwayFromZero,
  }) => duration * rounding.round(dividedByTimeDelta(duration.asNormalTime));
  Years roundToMultipleOfNormalLeapYears(
    Years duration, {
    Rounding rounding = Rounding.nearestAwayFromZero,
  }) =>
      duration * rounding.round(dividedByTimeDelta(duration.asNormalLeapTime));

  /// Returns a [Future] that completes after this duration has passed.
  Future<void> get wait => Future<void>.delayed(roundToCoreDuration());

  @override
  int compareTo(TimeDelta other) {
    final result = totalSeconds.compareTo(other.totalSeconds);
    if (result != 0) return result;

    return subSecondNanos.compareTo(other.subSecondNanos);
  }

  @override
  String toString() {
    // TODO(JonasWanke): ISO 8601
    final buffer = StringBuffer('TimeDelta(');
    var isFirst = true;

    void writePart(int value, String suffix) {
      if (!isFirst) buffer.write(', ');
      buffer.write('$value $suffix');
      isFirst = false;
    }

    final (hours, minutes, seconds, millis, micros, nanos) =
        splitHoursMinutesSecondsMillisMicrosNanos();
    if (hours != 0) writePart(hours, 'h');
    if (minutes != 0) writePart(minutes, 'm');
    if (seconds != 0) writePart(seconds, 's');
    if (millis != 0) writePart(millis, 'ms');
    if (micros != 0) writePart(micros, 'µs');
    if (nanos != 0) writePart(nanos, 'ns');

    buffer.write(')');
    return buffer.toString();
  }
}

extension IntToTimeDeltaExtension on int {
  /// Creates a [TimeDelta] representing this many nanoseconds.
  TimeDelta get nanos => TimeDelta(nanos: this);

  /// Creates a [TimeDelta] representing this many microseconds.
  TimeDelta get micros => TimeDelta(micros: this);

  /// Creates a [TimeDelta] representing this many milliseconds.
  TimeDelta get millis => TimeDelta(millis: this);

  /// Creates a [TimeDelta] representing this many seconds.
  TimeDelta get seconds => TimeDelta(seconds: this);

  /// Creates a [TimeDelta] representing this many minutes.
  TimeDelta get minutes => TimeDelta(minutes: this);

  /// Creates a [TimeDelta] representing this many hours.
  TimeDelta get hours => TimeDelta(hours: this);

  /// Creates a [TimeDelta] representing this many normal days.
  TimeDelta get normalDays => TimeDelta(normalDays: this);

  /// Creates a [TimeDelta] representing this many normal weeks.
  TimeDelta get normalWeeks => TimeDelta(normalWeeks: this);

  /// Creates a [TimeDelta] representing this many normal years.
  TimeDelta get normalYears => TimeDelta(normalYears: this);

  /// Creates a [TimeDelta] representing this many normal leap years.
  TimeDelta get normalLeapYears => TimeDelta(normalLeapYears: this);
}

// TODO(JonasWanke): `TimeDeltaAsIsoStringCodec`, `TimeDeltaAsMillisIntCodec`,
// `TimeDeltaAsMicrosIntCodec`, `TimeDeltaAsNanosIntCodec`

/// Encodes [TimeDelta] as a map: `{'seconds': <seconds>, 'nanos': <nanos>}`.
@immutable
class TimeDeltaAsMapCodec
    extends CodecAndJsonConverter<TimeDelta, Map<String, dynamic>> {
  const TimeDeltaAsMapCodec();

  @override
  Map<String, dynamic> encode(TimeDelta input) => {
    'seconds': input.totalSeconds,
    'nanos': input.subSecondNanos,
  };
  @override
  TimeDelta decode(Map<String, dynamic> encoded) {
    return TimeDelta(
      seconds: encoded['seconds']! as int,
      nanos: encoded['nanos']! as int,
    );
  }
}

/// Encodes [TimeDelta] as a (rounded) integer number of seconds.
@immutable
class TimeDeltaAsSecondsIntCodec extends CodecAndJsonConverter<TimeDelta, int> {
  const TimeDeltaAsSecondsIntCodec({
    this.rounding = Rounding.nearestAwayFromZero,
  });

  final Rounding rounding;

  @override
  int encode(TimeDelta input) => input.roundToSeconds(rounding: rounding);
  @override
  TimeDelta decode(int encoded) => TimeDelta(seconds: encoded);
}
