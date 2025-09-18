import 'package:clock/clock.dart';
import 'package:meta/meta.dart';
import 'package:oxidized/oxidized.dart';

import '../codec.dart';
import '../date_time/date_time.dart';
import '../parser.dart';
import '../rounding.dart';
import '../utils.dart';
import 'duration.dart';

/// A specific time of a day, e.g., 18:24:20.
///
/// This class doesn't store or care about timezones, each day is exactly
/// 24 hours long.
@immutable
final class Time
    with ComparisonOperatorsFromComparable<Time>
    implements Comparable<Time> {
  static Result<Time, String> from(
    int hour, [
    int minute = 0,
    int second = 0,
    int millis = 0,
    int micros = 0,
    int nanos = 0,
  ]) {
    if (hour < 0 || hour >= TimeDelta.hoursPerNormalDay) {
      return Err('Invalid hour: $hour');
    }
    if (minute < 0 || minute >= TimeDelta.minutesPerHour) {
      return Err('Invalid minute: $minute');
    }
    if (second < 0 || second >= TimeDelta.secondsPerMinute) {
      return Err('Invalid second: $second');
    }
    final actualNanos =
        millis * TimeDelta.nanosPerMillisecond +
        micros * TimeDelta.nanosPerMicrosecond +
        nanos;
    if (actualNanos < 0 || actualNanos >= TimeDelta.nanosPerSecond) {
      return Err('Invalid millis + micros + nanos: $actualNanos');
    }

    return Ok(Time._(hour, minute, second, actualNanos));
  }

  const Time._(this.hour, this.minute, this.second, this.subSecondNanos);

  static Result<Time, String> fromTimeSinceMidnight(
    TimeDelta timeSinceMidnight,
  ) {
    if (timeSinceMidnight.isNegative) {
      return Err(
        'Time since midnight must not be negative, but was: $timeSinceMidnight',
      );
    }
    if (timeSinceMidnight >= TimeDelta(normalDays: 1)) {
      return Err(
        'Time since midnight must not be ≥ a day, but was: $timeSinceMidnight',
      );
    }

    final (hours, minutes, seconds, nanos) = timeSinceMidnight
        .splitHoursMinutesSecondsNanos();
    final time = Time._(hours, minutes, seconds, nanos);
    return Ok(time);
  }

  factory Time.nowInLocalZone({Clock? clock}) =>
      CDateTime.nowInLocalZone(clock: clock).time;
  factory Time.nowInUtc({Clock? clock}) =>
      CDateTime.nowInUtc(clock: clock).time;

  // TODO(JonasWanke): comments
  static Result<Time, String>? lerpNullable(
    Time? a,
    Time? b,
    double t, {
    Rounding rounding = Rounding.nearestAwayFromZero,
  }) {
    final duration = TimeDelta.lerpNullable(
      a?.timeSinceMidnight,
      b?.timeSinceMidnight,
      t,
      rounding: rounding,
    );
    if (duration == null) return null;

    return Time.fromTimeSinceMidnight(duration);
  }

  static Result<Time, String> lerp(
    Time a,
    Time b,
    double t, {
    Rounding rounding = Rounding.nearestAwayFromZero,
  }) {
    return Time.fromTimeSinceMidnight(
      TimeDelta.lerp(
        a.timeSinceMidnight,
        b.timeSinceMidnight,
        t,
        rounding: rounding,
      ),
    );
  }

  static final Time midnight = Time.from(0).unwrap();
  static final Time noon = Time.from(12).unwrap();

  final int hour;
  final int minute;
  final int second;
  final int subSecondNanos;

  bool get isAm => hour < 12;
  bool get isPm => !isAm;
  bool get isMidnight => this == midnight;
  bool get isNoon => this == noon;

  int get hoursSinceMidnight => hour;
  int get minutesSinceMidnight =>
      minute + hoursSinceMidnight * TimeDelta.minutesPerHour;
  int get secondsSinceMidnight =>
      second + minutesSinceMidnight * TimeDelta.secondsPerMinute;
  TimeDelta get timeSinceMidnight =>
      TimeDelta.raw(secondsSinceMidnight, subSecondNanos);

  Result<Time, String> add(TimeDelta duration) {
    return Time.fromTimeSinceMidnight(timeSinceMidnight + duration);
  }

  Result<Time, String> subtract(TimeDelta duration) => add(-duration);

  /// Returns `this - other`.
  TimeDelta difference(Time other) =>
      timeSinceMidnight - other.timeSinceMidnight;

  Time roundToMultipleOf(
    TimeDelta duration, {
    Rounding rounding = Rounding.nearestAwayFromZero,
  }) {
    return Time.fromTimeSinceMidnight(
      timeSinceMidnight.roundToMultipleOf(duration, rounding: rounding),
    ).unwrapOrElse((_) {
      // Rounding could round up the value to, e.g., 24 hours. In that case, we
      // floor the value to return the closest value in our range.
      return Time.fromTimeSinceMidnight(
        timeSinceMidnight.roundToMultipleOf(duration, rounding: Rounding.down),
      ).unwrap();
    });
  }

  Result<Time, String> copyWith({
    int? hour,
    int? minute,
    int? second,
    int? subSecondNanos,
  }) {
    return Time.from(
      hour ?? this.hour,
      minute ?? this.minute,
      second ?? this.second,
      subSecondNanos ?? this.subSecondNanos,
    );
  }

  @override
  int compareTo(Time other) {
    if (hour != other.hour) return hour.compareTo(other.hour);
    if (minute != other.minute) return minute.compareTo(other.minute);
    if (second != other.second) return second.compareTo(other.second);
    return subSecondNanos.compareTo(other.subSecondNanos);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is Time &&
            hour == other.hour &&
            minute == other.minute &&
            second == other.second &&
            subSecondNanos == other.subSecondNanos);
  }

  @override
  int get hashCode => Object.hash(hour, minute, second, subSecondNanos);

  @override
  String toString() {
    final hour = this.hour.toString().padLeft(2, '0');
    final minute = this.minute.toString().padLeft(2, '0');
    final second = this.second.toString().padLeft(2, '0');
    final subSecondNanos = this.subSecondNanos.toString().padLeft(9, '0');
    return '$hour:$minute:$second.$subSecondNanos';
  }
}

/// Encodes a [Time] as an ISO 8601 string, e.g., “18:24:20.12”.
class TimeAsIsoStringCodec extends CodecWithParserResult<Time, String> {
  const TimeAsIsoStringCodec();

  @override
  String encode(Time input) => input.toString();
  @override
  Result<Time, FormatException> decodeAsResult(String encoded) =>
      Parser.parseTime(encoded);
}
