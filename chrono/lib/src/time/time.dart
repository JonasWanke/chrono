import 'package:clock/clock.dart';
import 'package:meta/meta.dart';

import '../codec.dart';
import '../date/duration.dart';
import '../date_time/date_time.dart';
import '../offset/fixed.dart';
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
  Time.from(
    int hour, [
    int minute = 0,
    int second = 0,
    int millis = 0,
    int micros = 0,
    int nanos = 0,
  ]) : this._unchecked(
         RangeError.checkValueInInterval(
           hour,
           0,
           TimeDelta.hoursPerNormalDay - 1,
           'hour',
         ),
         RangeError.checkValueInInterval(
           minute,
           0,
           TimeDelta.minutesPerHour - 1,
           'minute',
         ),
         RangeError.checkValueInInterval(
           second,
           0,
           TimeDelta.secondsPerMinute - 1,
           'second',
         ),
         RangeError.checkValueInInterval(
           millis * TimeDelta.nanosPerMilli +
               micros * TimeDelta.nanosPerMicro +
               nanos,
           0,
           TimeDelta.nanosPerSecond - 1,
           'millis, micros, and nanos',
         ),
       );

  const Time._unchecked(
    this.hour,
    this.minute,
    this.second,
    this.subSecondNanos,
  );

  factory Time.fromTimeSinceMidnight(TimeDelta timeSinceMidnight) {
    if (timeSinceMidnight.isNegative) {
      throw ArgumentError.value(
        timeSinceMidnight,
        'timeSinceMidnight',
        'Time since midnight must not be negative.',
      );
    }
    if (timeSinceMidnight >= TimeDelta(normalDays: 1)) {
      throw ArgumentError.value(
        timeSinceMidnight,
        'timeSinceMidnight',
        'Time since midnight must not be ≥ a day.',
      );
    }

    final (hours, minutes, seconds, nanos) = timeSinceMidnight
        .splitHoursMinutesSecondsNanos();
    return Time._unchecked(hours, minutes, seconds, nanos);
  }

  factory Time.nowInLocalZone({Clock? clock}) =>
      CDateTime.nowInLocalZone(clock: clock).time;
  factory Time.nowInUtc({Clock? clock}) =>
      CDateTime.nowInUtc(clock: clock).time;

  // TODO(JonasWanke): comments
  static Time? lerpNullable(
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

  factory Time.lerp(
    Time a,
    Time b,
    double t, {
    Rounding rounding = Rounding.nearestAwayFromZero,
  }) => Time.fromTimeSinceMidnight(
    TimeDelta.lerp(
      a.timeSinceMidnight,
      b.timeSinceMidnight,
      t,
      rounding: rounding,
    ),
  );

  static const Time midnight = Time._unchecked(0, 0, 0, 0);
  static const Time noon = Time._unchecked(12, 0, 0, 0);
  static const Time _dayEnd = Time._unchecked(
    TimeDelta.hoursPerNormalDay - 1,
    TimeDelta.minutesPerHour - 1,
    TimeDelta.secondsPerMinute - 1,
    TimeDelta.nanosPerSecond - 1,
  );

  final int hour;
  final int minute;
  final int second;
  final int subSecondNanos;
  TimeDelta get subSecond => TimeDelta(nanos: subSecondNanos);
  // TODO(JonasWanke): store only `secondsSinceMidnight` & `subSecondNanos`

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

  Time operator +(TimeDelta duration) =>
      Time.fromTimeSinceMidnight(timeSinceMidnight + duration);
  Time operator -(TimeDelta duration) => this + (-duration);

  Time? addChecked(TimeDelta duration) {
    final result = timeSinceMidnight + duration;
    if (result.isNegative || result >= TimeDelta(normalDays: 1)) return null;
    return Time.fromTimeSinceMidnight(result);
  }

  Time? subtractChecked(TimeDelta duration) => addChecked(-duration);

  Time addSaturating(TimeDelta duration) {
    final result = timeSinceMidnight + duration;
    if (result.isNegative) {
      return midnight;
    } else if (result >= TimeDelta(normalDays: 1)) {
      return _dayEnd;
    } else {
      return Time.fromTimeSinceMidnight(result);
    }
  }

  Time subtractSaturating(TimeDelta duration) => addSaturating(-duration);

  Time addWrapping(TimeDelta duration) {
    return Time.fromTimeSinceMidnight(
      (timeSinceMidnight + duration) % TimeDelta(normalDays: 1),
    );
  }

  Time subtractWrapping(TimeDelta duration) => addWrapping(-duration);

  /// Adds given [FixedOffset] to the current time, and returns the number of
  /// days that should be added to a date as a result of the offset (either
  /// `-1`, `0`, or `1` because the offset is always less than 24h).
  ///
  // TODO(JonasWanke): support leap seconds
  // This method is similar to [overflowingAddSigned], but preserves leap
  // seconds.
  @useResult
  (Time, Days) overflowingAddOffset(FixedOffset offset) {
    final rawSeconds = secondsSinceMidnight + offset.localMinusUtcSeconds;
    final seconds = rawSeconds % TimeDelta.secondsPerNormalDay;
    final days = Days((rawSeconds - seconds) ~/ TimeDelta.secondsPerNormalDay);
    final (hour, minute, second, _) = TimeDelta(
      seconds: seconds,
    ).splitHoursMinutesSecondsNanos();
    return (Time.from(hour, minute, second, subSecondNanos), days);
  }

  /// Subtracts given [FixedOffset] from the current time, and returns the
  /// number of days that should be added to a date as a result of the offset
  /// (either `-1`, `0`, or `1` because the offset is always less than 24h).
  ///
  // TODO(JonasWanke): support leap seconds
  // This method is similar to [overflowingSubSigned], but preserves leap
  // seconds.
  @useResult
  (Time, Days) overflowingSubOffset(FixedOffset offset) {
    final rawSeconds = secondsSinceMidnight - offset.localMinusUtcSeconds;
    final seconds = rawSeconds % TimeDelta.secondsPerNormalDay;
    final days = Days((rawSeconds - seconds) ~/ TimeDelta.secondsPerNormalDay);
    final (hour, minute, second, _) = TimeDelta(
      seconds: seconds,
    ).splitHoursMinutesSecondsNanos();
    return (Time.from(hour, minute, second, subSecondNanos), days);
  }

  /// Returns `this - other`.
  TimeDelta difference(Time other) =>
      timeSinceMidnight - other.timeSinceMidnight;

  Time roundToMultipleOf(
    TimeDelta duration, {
    Rounding rounding = Rounding.nearestAwayFromZero,
  }) {
    final timeSinceMidnight = this.timeSinceMidnight.roundToMultipleOf(
      duration,
      rounding: rounding,
    );
    if (timeSinceMidnight >= TimeDelta(normalDays: 1)) {
      // Rounding could round up the value to, e.g., 24 hours. In that case, we
      // floor the value to return the closest value in our range.
      return Time.fromTimeSinceMidnight(
        timeSinceMidnight.roundToMultipleOf(duration, rounding: Rounding.down),
      );
    }
    return Time.fromTimeSinceMidnight(timeSinceMidnight);
  }

  Time copyWith({int? hour, int? minute, int? second, int? subSecondNanos}) {
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
class TimeAsIsoStringCodec extends CodecAndJsonConverter<Time, String> {
  const TimeAsIsoStringCodec();

  @override
  String encode(Time input) => input.toString();
  @override
  Time decode(String encoded) => Parser.parseTime(encoded);
}
