import 'dart:core' as core;
import 'dart:core';

import 'package:clock/clock.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
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
    Nanoseconds? nanoseconds,
  ]) {
    if (hour < 0 || hour >= Duration.hoursPerDay) {
      return Err('Invalid hour: $hour');
    }
    if (minute < 0 || minute >= Duration.minutesPerHour) {
      return Err('Invalid minute: $minute');
    }
    if (second < 0 || second >= Duration.secondsPerMinute) {
      return Err('Invalid second: $second');
    }

    final nanosecondsError = _validateNanoseconds(nanoseconds);
    if (nanosecondsError != null) return Err(nanosecondsError);
    nanoseconds ??= Nanoseconds(0);

    return Ok(Time._(hour, minute, second, nanoseconds));
  }

  const Time._(this.hour, this.minute, this.second, this.nanoseconds);

  static Result<Time, String> fromTimeSinceMidnight(
    TimeDuration timeSinceMidnight,
  ) {
    if (timeSinceMidnight.isNegative) {
      return Err(
        'Time since midnight must not be negative, but was: $timeSinceMidnight',
      );
    }
    if (timeSinceMidnight >= Hours.normalDay) {
      return Err(
        'Time since midnight must not be ≥ a day, but was: $timeSinceMidnight',
      );
    }

    final (asSeconds, nanoseconds) = timeSinceMidnight.splitSecondsNanos;
    final (hours, minutes, seconds) = asSeconds.splitHoursMinutesSeconds;
    final time = Time._(
      hours.inHours,
      minutes.inMinutes,
      seconds.inSeconds,
      nanoseconds,
    );
    return Ok(time);
  }

  factory Time.nowInLocalZone({Clock? clock}) =>
      DateTime.nowInLocalZone(clock: clock).time;
  factory Time.nowInUtc({Clock? clock}) => DateTime.nowInUtc(clock: clock).time;

  // TODO(JonasWanke): comments
  static Result<Time, String>? lerpNullable(
    Time? a,
    Time? b,
    double t, {
    Rounding rounding = Rounding.nearestAwayFromZero,
  }) {
    final duration = TimeDuration.lerpNullable(
      a?.nanosecondsSinceMidnight,
      b?.nanosecondsSinceMidnight,
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
      TimeDuration.lerp(
        a.nanosecondsSinceMidnight,
        b.nanosecondsSinceMidnight,
        t,
        rounding: rounding,
      ),
    );
  }

  static String? _validateNanoseconds(Nanoseconds? nanoseconds) {
    if (nanoseconds != null &&
        (nanoseconds.isNegative || nanoseconds >= Nanoseconds.second)) {
      return 'Invalid nanoseconds within a second: $nanoseconds';
    }
    return null;
  }

  static final Time midnight = Time.from(0).unwrap();
  static final Time noon = Time.from(12).unwrap();

  final int hour;
  final int minute;
  final int second;
  final Nanoseconds nanoseconds;

  bool get isAm => hour < 12;
  bool get isPm => !isAm;
  bool get isMidnight => this == midnight;
  bool get isNoon => this == noon;

  Hours get hoursSinceMidnight => Hours(hour);
  Minutes get minutesSinceMidnight => Minutes(minute) + hoursSinceMidnight;
  Seconds get secondsSinceMidnight => Seconds(second) + minutesSinceMidnight;
  Nanoseconds get nanosecondsSinceMidnight =>
      nanoseconds + secondsSinceMidnight;

  Result<Time, String> add(TimeDuration duration) {
    return Time.fromTimeSinceMidnight(
      nanosecondsSinceMidnight + duration.asNanoseconds,
    );
  }

  Result<Time, String> subtract(TimeDuration duration) => add(-duration);

  /// Returns `this - other`.
  Nanoseconds difference(Time other) =>
      nanosecondsSinceMidnight - other.nanosecondsSinceMidnight;

  Time roundToMultipleOf(
    TimeDuration duration, {
    Rounding rounding = Rounding.nearestAwayFromZero,
  }) {
    return Time.fromTimeSinceMidnight(
      nanosecondsSinceMidnight.roundToMultipleOf(duration, rounding: rounding),
    ).unwrapOrElse((_) {
      // Rounding could round up the value to, e.g., 24 hours. In that case, we
      // floor the value to return the closest value in our range.
      return Time.fromTimeSinceMidnight(
        nanosecondsSinceMidnight.roundToMultipleOf(
          duration,
          rounding: Rounding.down,
        ),
      ).unwrap();
    });
  }

  Result<Time, String> copyWith({
    int? hour,
    int? minute,
    int? second,
    Nanoseconds? nanoseconds,
  }) {
    return Time.from(
      hour ?? this.hour,
      minute ?? this.minute,
      second ?? this.second,
      nanoseconds ?? nanoseconds,
    );
  }

  @override
  int compareTo(Time other) {
    if (hour != other.hour) return hour.compareTo(other.hour);
    if (minute != other.minute) return minute.compareTo(other.minute);
    if (second != other.second) return second.compareTo(other.second);
    return nanoseconds.compareTo(other.nanoseconds);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is Time &&
            hour == other.hour &&
            minute == other.minute &&
            second == other.second &&
            nanoseconds == other.nanoseconds);
  }

  @override
  int get hashCode => Object.hash(hour, minute, second, nanoseconds);

  @override
  String toString() {
    final hour = this.hour.toString().padLeft(2, '0');
    final minute = this.minute.toString().padLeft(2, '0');
    final second = this.second.toString().padLeft(2, '0');
    final nanoseconds =
        this.nanoseconds.inNanoseconds.toString().padLeft(9, '0');
    return '$hour:$minute:$second.$nanoseconds';
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

// class LocalizedTimeFormatter implements Formatter<Time> {
//   LocalizedTimeFormatter(Intl intl, TimeFormatStyle style)
//       : _format = intl.datetimeFormat(
//           DateTimeFormatOptions(
//             calendar: Calendar.gregory,
//             timeFormatStyle: style,
//           ),
//         );
//   LocalizedTimeFormatter.components(
//     Intl intl, {
//     TimeStyle? hour,
//     TimeStyle? minute,
//     TimeStyle? second,
//   }) : _format = intl.datetimeFormat(
//           DateTimeFormatOptions(
//             calendar: Calendar.gregory,
//             hour: hour,
//             minute: minute,
//             second: second,
//           ),
//         );

//   final DateTimeFormat _format;

//   @override
//   String format(Time value) =>
//       _format.format(Date.unixEpoch.at(value).asCoreDateTimeInUtc);
// }
