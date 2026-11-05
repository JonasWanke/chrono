import 'package:meta/meta.dart';

import '../codec.dart';
import '../date/duration.dart';
import '../date_time/duration.dart';
import '../rounding.dart';
import '../utils.dart';

/// A unit of the time family: a length that is an exact, context-free multiple
/// of a nanosecond.
///
/// There is no `years` member: unlike a normal or leap year individually, "a
/// year" has no single exact factor to nanoseconds. Use
/// [IntToTimeDeltaChrono.normalYears]/[IntToTimeDeltaChrono.normalLeapYears] to
/// construct such a duration explicitly instead.
///
/// [centis] and [decis] exist so timer-style displays (`05:03.25`) are exact
/// rather than `millis ~/ 10`.
enum TimeUnit {
  nanos(1),
  micros(TimeDelta.nanosPerMicro),
  millis(TimeDelta.nanosPerMicro * TimeDelta.microsPerMilli),
  centis(TimeDelta.nanosPerMicro * TimeDelta.microsPerMilli * 10),
  decis(TimeDelta.nanosPerMicro * TimeDelta.microsPerMilli * 100),
  seconds(TimeDelta.nanosPerSecond),
  minutes(TimeDelta.nanosPerSecond * TimeDelta.secondsPerMinute),
  hours(
    TimeDelta.nanosPerSecond *
        TimeDelta.secondsPerMinute *
        TimeDelta.minutesPerHour,
  ),
  normalDays(
    TimeDelta.nanosPerSecond *
        TimeDelta.secondsPerMinute *
        TimeDelta.minutesPerHour *
        TimeDelta.hoursPerNormalDay,
  ),
  normalWeeks(
    TimeDelta.nanosPerSecond *
        TimeDelta.secondsPerMinute *
        TimeDelta.minutesPerHour *
        TimeDelta.hoursPerNormalDay *
        Days.perWeek,
  );

  const TimeUnit(this.nanosPer);

  /// Nanoseconds in one of this unit. Derived from the primitives, never
  /// hand-written as an independent product.
  final int nanosPer;

  /// How many of `this` fit in one [larger] — e.g.,
  /// `TimeUnit.normalDays.per(.normalWeeks) == 7`.
  int per(TimeUnit larger) {
    assert(larger.nanosPer >= nanosPer, 'Argument must be the larger unit.');
    return larger.nanosPer ~/ nanosPer;
  }
}

/// The result of [TimeDelta.split]: one value per requested [TimeUnit].
///
/// Reading a unit that wasn't requested throws instead of returning zero, since
/// that is almost certainly a bug and zero would hide it. Use [maybe] or [has]
/// when the requested set isn't statically known.
///
/// All components share the sign of the duration they were split from.
@immutable
final class TimeParts extends ChronoParts<TimeUnit> {
  const TimeParts._(super.values);

  @override
  List<TimeUnit> get allUnitsOrdered => TimeUnit.values;

  int get nanos => get(.nanos);
  int get micros => get(.micros);
  int get millis => get(.millis);
  int get centis => get(.centis);
  int get decis => get(.decis);
  int get seconds => get(.seconds);
  int get minutes => get(.minutes);
  int get hours => get(.hours);
  int get normalDays => get(.normalDays);
  int get normalWeeks => get(.normalWeeks);
}

/// A [ChronoDelta] that is of a fixed length.
///
/// See also:
///
/// - [CalendarDelta], which covers durations based on an integer number of
///   days or months.
/// - [ChronoDelta], which is the base class for all durations.
class TimeDelta extends ChronoDelta
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
    final secondsPerNormalDay = TimeUnit.seconds.per(.normalDays);
    final microsPerSecond = TimeUnit.micros.per(.seconds);
    var wholeSeconds =
        normalLeapYears * Days.perLeapYear * secondsPerNormalDay +
        normalYears * Days.perNormalYear * secondsPerNormalDay +
        normalWeeks * TimeUnit.seconds.per(.normalWeeks) +
        normalDays * secondsPerNormalDay +
        hours * TimeUnit.seconds.per(.hours) +
        minutes * secondsPerMinute +
        seconds +
        millis ~/ millisPerSecond +
        micros ~/ microsPerSecond +
        nanos ~/ nanosPerSecond;
    var subSecondNanos =
        millis.remainder(millisPerSecond) * TimeUnit.millis.nanosPer +
        micros.remainder(microsPerSecond) * nanosPerMicro +
        nanos.remainder(nanosPerSecond);
    wholeSeconds += subSecondNanos ~/ nanosPerSecond;
    subSecondNanos = subSecondNanos.remainder(nanosPerSecond);
    if (wholeSeconds > 0 && subSecondNanos < 0) {
      wholeSeconds -= 1;
      subSecondNanos += nanosPerSecond;
    } else if (wholeSeconds < 0 && subSecondNanos > 0) {
      wholeSeconds += 1;
      subSecondNanos -= nanosPerSecond;
    }
    return TimeDelta.raw(wholeSeconds, subSecondNanos);
  }
  const TimeDelta.raw(this.wholeSeconds, this.subSecondNanos)
    : assert(
        wholeSeconds >= 0 && subSecondNanos >= 0 ||
            wholeSeconds <= 0 && subSecondNanos <= 0,
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

  // Only the six primitives below are kept as public constants; every derived
  // factor (e.g. seconds per hour) is available through [TimeUnit.per], so it
  // is never hand-written as a product — see `docs/…/duration-redesign-design.md`
  // for the incident that motivated this.
  //
  // `nanosPerSecond` is the one derived factor kept anyway: [Time] needs it in
  // a `const` context (`Time._dayEnd`), and `per()` cannot be `const`.

  /// The number of nanoseconds in a microsecond.
  static const nanosPerMicro = 1000;

  /// The number of microseconds in a millisecond.
  static const microsPerMilli = 1000;

  /// The number of milliseconds in a second.
  static const millisPerSecond = 1000;

  /// The number of seconds in a minute.
  static const secondsPerMinute = 60;

  /// The number of minutes in an hour.
  static const minutesPerHour = 60;

  /// The number of hours in a normal day, i.e., a day with exactly 24 hours
  /// (no daylight savings time changes and no leap seconds).
  static const hoursPerNormalDay = 24;

  /// The number of nanoseconds in a second.
  static const nanosPerSecond =
      nanosPerMicro * microsPerMilli * millisPerSecond;

  // TODO(JonasWanke): avoid `_totalNanos` to avoid overflows
  int get _totalNanos => wholeSeconds * nanosPerSecond + subSecondNanos;

  /// The whole seconds in this duration, truncated towards zero.
  ///
  /// This is one of the two canonical stored fields — the other is
  /// [subSecondNanos]. Neither can be misread as the total: use [totalIn] for
  /// that.
  final int wholeSeconds;

  /// The sub-second nanoseconds in this duration, in `-999_999_999 …
  /// 999_999_999`, with the same sign as [wholeSeconds] (or either sign if
  /// [wholeSeconds] is zero).
  final int subSecondNanos;

  /// This duration expressed in [unit], including a fractional part.
  double totalIn(TimeUnit unit) => _totalNanos / unit.nanosPer;

  /// This duration rounded to a whole number of [unit].
  int roundTo(
    TimeUnit unit, {
    Rounding rounding = Rounding.nearestAwayFromZero,
  }) => roundDivide(_totalNanos, unit.nanosPer, rounding);

  /// This duration rounded to a multiple of [increment] × [unit].
  TimeDelta round(
    TimeUnit unit, {
    int increment = 1,
    Rounding rounding = Rounding.nearestAwayFromZero,
  }) {
    final step = unit.nanosPer * increment;
    return TimeDelta(nanos: roundDivide(_totalNanos, step, rounding) * step);
  }

  /// Whether this duration is a whole multiple of [increment] × [unit], i.e.,
  /// whether [round] with the same arguments would leave it unchanged.
  bool isMultipleOf(TimeUnit unit, {int increment = 1}) =>
      _totalNanos % (unit.nanosPer * increment) == 0;

  /// Decomposes this duration into the given [units].
  ///
  /// The largest listed unit absorbs everything above it; the smallest absorbs
  /// everything below it, rounded according to [rounding]. All components share
  /// the sign of this duration.
  ///
  /// ```dart
  /// delta.split({.hours, .minutes, .seconds, .nanos});
  /// ```
  TimeParts split(
    Set<TimeUnit> units, {
    Rounding rounding = Rounding.nearestAwayFromZero,
  }) => TimeParts._(
    splitIntoUnits(_totalNanos, units, (it) => it.nanosPer, rounding),
  );

  @override
  DateTimeDelta get asDateTimeDelta => DateTimeDelta(time: this);

  @override
  bool get isZero => wholeSeconds == 0 && subSecondNanos == 0;
  bool get isPositive => wholeSeconds > 0 || subSecondNanos > 0;
  bool get isNonPositive => !isPositive;
  bool get isNegative => wholeSeconds < 0 || subSecondNanos < 0;
  bool get isNonNegative => !isNegative;

  TimeDelta operator +(TimeDelta other) {
    return TimeDelta(
      seconds: wholeSeconds + other.wholeSeconds,
      nanos: subSecondNanos + other.subSecondNanos,
    );
  }

  TimeDelta operator -(TimeDelta other) {
    return TimeDelta(
      seconds: wholeSeconds - other.wholeSeconds,
      nanos: subSecondNanos - other.subSecondNanos,
    );
  }

  @override
  TimeDelta operator -() => TimeDelta.raw(-wholeSeconds, -subSecondNanos);
  TimeDelta get absolute => isNegative ? -this : this;

  @override
  TimeDelta operator *(int factor) =>
      TimeDelta(seconds: wholeSeconds * factor, nanos: subSecondNanos * factor);
  TimeDelta timesDouble(
    double factor, {
    Rounding rounding = Rounding.nearestAwayFromZero,
  }) => TimeDelta(nanos: rounding.round(_totalNanos * factor));

  @override
  TimeDelta operator ~/(int divisor) {
    final wholeSeconds = this.wholeSeconds ~/ divisor;
    final carry = this.wholeSeconds - wholeSeconds * divisor;
    final subSecondNanos =
        (carry * nanosPerSecond + this.subSecondNanos) ~/ divisor;
    return TimeDelta(seconds: wholeSeconds, nanos: subSecondNanos);
  }

  // TODO(JonasWanke): avoid `_totalNanos` to avoid overflows
  double operator /(TimeDelta divisor) => _totalNanos / divisor._totalNanos;
  // Nanoseconds dividedByInt(
  //   int divisor, {
  //   Rounding rounding = Rounding.nearestAwayFromZero,
  // }) => Nanoseconds(rounding.round(inNanoseconds / divisor));
  // Nanoseconds dividedByDouble(
  //   double divisor, {
  //   Rounding rounding = Rounding.nearestAwayFromZero,
  // }) => Nanoseconds(rounding.round(inNanoseconds.toDouble() / divisor));

  @override
  TimeDelta operator %(TimeDelta divisor) =>
      TimeDelta(nanos: _totalNanos % divisor._totalNanos);
  @override
  TimeDelta remainder(TimeDelta divisor) =>
      TimeDelta(nanos: _totalNanos.remainder(divisor._totalNanos));

  /// The number of whole normal (24 h) days in this duration.
  ///
  /// The `Normal` qualifier is load-bearing: it marks the 24-hour assumption
  /// being made when this exact duration is reinterpreted as a calendar one.
  Days roundToNormalDays({Rounding rounding = Rounding.nearestAwayFromZero}) =>
      Days(roundTo(.normalDays, rounding: rounding));
  Duration roundToCoreDuration({
    Rounding rounding = Rounding.nearestAwayFromZero,
  }) => Duration(microseconds: roundTo(.micros, rounding: rounding));

  /// This duration rounded to a multiple of [duration].
  ///
  /// Unlike [round], [duration] can be any [TimeDelta], not just a whole
  /// number of a single [TimeUnit].
  TimeDelta roundToMultipleOf(
    TimeDelta duration, {
    Rounding rounding = Rounding.nearestAwayFromZero,
  }) => duration * rounding.round(this / duration);

  /// Returns a [Future] that completes after this duration has passed.
  Future<void> get wait => Future<void>.delayed(roundToCoreDuration());

  @override
  int compareTo(TimeDelta other) {
    final result = wholeSeconds.compareTo(other.wholeSeconds);
    if (result != 0) return result;

    return subSecondNanos.compareTo(other.subSecondNanos);
  }

  @override
  String toString() => const TimeDeltaAsSimpleStringCodec().encode(this);
}

extension IntToTimeDeltaChrono on int {
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

extension IterableOfTimeDeltaChrono on Iterable<TimeDelta> {
  TimeDelta get sum => fold(TimeDelta(), (sum, it) => sum + it);
}

// TODO(JonasWanke): `TimeDeltaAsMillisIntCodec`, `TimeDeltaAsMicrosIntCodec`,
// `TimeDeltaAsNanosIntCodec`

/// Encodes a [TimeDelta] as an ISO 8601 string, e.g., “PT123.456S”.
class TimeDeltaAsIsoStringCodec
    extends CodecAndJsonConverter<TimeDelta, String> {
  const TimeDeltaAsIsoStringCodec();

  @override
  String encode(TimeDelta input) {
    final (value, sign) = input.isNegative ? (-input, '-') : (input, '');
    final buffer = StringBuffer(sign);
    buffer.write('PT');

    final parts = value.split({.seconds, .millis, .micros, .nanos});
    buffer.write(parts.seconds);
    buffer.writeNonZeroMillisMicrosNanos(
      parts.millis,
      parts.micros,
      parts.nanos,
    );
    return buffer.toString();
  }

  // TODO(JonasWanke): implement
  @override
  TimeDelta decode(String encoded) => throw UnimplementedError();
}

/// Encodes a [TimeDelta] as a simple string, e.g., “01:00:12.001002”.
class TimeDeltaAsSimpleStringCodec
    extends CodecAndJsonConverter<TimeDelta, String> {
  const TimeDeltaAsSimpleStringCodec();

  @override
  String encode(TimeDelta input) {
    final (value, sign) = input.isNegative ? (-input, '-') : (input, '');
    final buffer = StringBuffer(sign);

    final parts = value.split({
      .hours,
      .minutes,
      .seconds,
      .millis,
      .micros,
      .nanos,
    });
    buffer.write(parts.hours.toString().padLeft(2, '0'));
    buffer.write(':');
    buffer.write(parts.minutes.toString().padLeft(2, '0'));
    buffer.write(':');
    buffer.write(parts.seconds.toString().padLeft(2, '0'));
    buffer.writeNonZeroMillisMicrosNanos(
      parts.millis,
      parts.micros,
      parts.nanos,
    );
    return buffer.toString();
  }

  @override
  TimeDelta decode(String encoded) {
    final pattern = RegExp(
      r'^(?<sign>-)?(?<hours>\d{2,}):(?<minutes>\d{2}):(?<seconds>\d{2})(?:\.(?<subsecond>\d{1,9}))?$',
    );
    final match = pattern.firstMatch(encoded);
    if (match == null) {
      throw FormatException('Invalid TimeDelta string: $encoded');
    }

    final sign = match.namedGroup('sign') != null ? -1 : 1;
    final hours = int.parse(match.namedGroup('hours')!);
    final minutes = int.parse(match.namedGroup('minutes')!);
    final seconds = int.parse(match.namedGroup('seconds')!);
    final subsecondString = match.namedGroup('subsecond');
    final nanos = subsecondString == null
        ? 0
        : int.parse(subsecondString.padRight(9, '0'));
    return TimeDelta(
      hours: sign * hours,
      minutes: sign * minutes,
      seconds: sign * seconds,
      nanos: sign * nanos,
    );
  }
}

extension on StringBuffer {
  void writeNonZeroMillisMicrosNanos(int millis, int micros, int nanos) {
    if (millis == 0 && micros == 0 && nanos == 0) return;

    write('.');
    write(millis.toString().padLeft(3, '0'));
    if (micros == 0 && nanos == 0) return;

    write(micros.toString().padLeft(3, '0'));
    if (nanos == 0) return;

    write(nanos.toString().padLeft(3, '0'));
  }
}

/// Encodes [TimeDelta] as a map: `{'seconds': <seconds>, 'nanos': <nanos>}`.
@immutable
class TimeDeltaAsMapCodec
    extends CodecAndJsonConverter<TimeDelta, Map<String, dynamic>> {
  const TimeDeltaAsMapCodec();

  @override
  Map<String, dynamic> encode(TimeDelta input) => {
    'seconds': input.wholeSeconds,
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
  int encode(TimeDelta input) => input.roundTo(.seconds, rounding: rounding);
  @override
  TimeDelta decode(int encoded) => TimeDelta(seconds: encoded);
}

/// Encodes [TimeDelta] as a (rounded) integer number of minutes.
@immutable
class TimeDeltaAsMinutesIntCodec extends CodecAndJsonConverter<TimeDelta, int> {
  const TimeDeltaAsMinutesIntCodec({
    this.rounding = Rounding.nearestAwayFromZero,
  });

  final Rounding rounding;

  @override
  int encode(TimeDelta input) => input.roundTo(.minutes, rounding: rounding);
  @override
  TimeDelta decode(int encoded) => TimeDelta(minutes: encoded);
}

/// Encodes [TimeDelta] as a (rounded) integer number of hours.
@immutable
class TimeDeltaAsHoursIntCodec extends CodecAndJsonConverter<TimeDelta, int> {
  const TimeDeltaAsHoursIntCodec({
    this.rounding = Rounding.nearestAwayFromZero,
  });

  final Rounding rounding;

  @override
  int encode(TimeDelta input) => input.roundTo(.hours, rounding: rounding);
  @override
  TimeDelta decode(int encoded) => TimeDelta(hours: encoded);
}
