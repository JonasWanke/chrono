import 'dart:core';
import 'dart:core' as core;

import 'package:clock/clock.dart';
import 'package:meta/meta.dart';
import 'package:oxidized/oxidized.dart';

import '../date_time/date_time.dart';
import '../parser.dart';
import '../utils.dart';
import 'duration.dart';

@immutable
final class Time
    with ComparisonOperatorsFromComparable<Time>
    implements Comparable<Time> {
  static Result<Time, String> from(
    int hour, [
    int minute = 0,
    int second = 0,
    FractionalSeconds? fraction,
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

    final fractionError = _validateFraction(fraction);
    if (fractionError != null) return Err(fractionError);
    fraction ??= FractionalSeconds.zero;

    return Ok(Time.fromUnchecked(hour, minute, second, fraction));
  }

  factory Time.fromThrowing(
    int hour, [
    int minute = 0,
    int second = 0,
    FractionalSeconds? fraction,
  ]) =>
      from(hour, minute, second, fraction).unwrap();
  const Time.fromUnchecked(this.hour, this.minute, this.second, this.fraction);

  static Result<Time, String> fromTimeSinceMidnight(TimeDuration time) {
    if (time.isNegative) {
      return Err('Time since midnight must not be negative, but was: $time');
    }
    if (time.asFractionalSeconds.value >=
        FractionalSeconds.perNormalDay.value) {
      return Err(
        'Time since midnight must not be ≥ a day, but was: $time',
      );
    }

    return Ok(Time.fromTimeSinceMidnightUnchecked(time));
  }

  factory Time.fromTimeSinceMidnightThrowing(TimeDuration time) =>
      fromTimeSinceMidnight(time).unwrap();
  factory Time.fromTimeSinceMidnightUnchecked(TimeDuration time) {
    final (asSeconds, fraction) = time.asSecondsAndFraction;
    final (hours, minutes, seconds) = asSeconds.asHoursAndMinutesAndSeconds;
    return Time.fromUnchecked(
      hours.inHours,
      minutes.inMinutes,
      seconds.inSeconds,
      fraction,
    );
  }

  factory Time.nowInLocalZone({Clock? clock}) =>
      DateTime.nowInLocalZone(clock: clock).time;
  factory Time.nowInUtc({Clock? clock}) => DateTime.nowInUtc(clock: clock).time;

  factory Time.fromJson(String json) => unwrapParserResult(parse(json));
  static Result<Time, FormatException> parse(String value) =>
      Parser.parseTime(value);

  static String? _validateFraction(FractionalSeconds? fraction) {
    if (fraction != null &&
        (fraction.isNegative || fraction >= FractionalSeconds.second)) {
      return 'Invalid fraction of a second: $fraction';
    }
    return null;
  }

  static final Time midnight = Time.fromThrowing(0);
  static final Time noon = Time.fromThrowing(12);

  final int hour;
  final int minute;
  final int second;
  final FractionalSeconds fraction;

  Hours get hoursSinceMidnight => Hours(hour);
  Minutes get minutesSinceMidnight => Minutes(minute) + hoursSinceMidnight;
  Seconds get secondsSinceMidnight => Seconds(second) + minutesSinceMidnight;
  FractionalSeconds get fractionalSecondsSinceMidnight =>
      fraction + secondsSinceMidnight;

  Result<Time, String> add(TimeDuration duration) =>
      Time.fromTimeSinceMidnight(_add(duration));
  Time addThrowing(TimeDuration duration) =>
      Time.fromTimeSinceMidnightThrowing(_add(duration));
  Time addUnchecked(TimeDuration duration) =>
      Time.fromTimeSinceMidnightUnchecked(_add(duration));
  FractionalSeconds _add(TimeDuration duration) =>
      fractionalSecondsSinceMidnight + duration.asFractionalSeconds;

  Result<Time, String> subtract(TimeDuration duration) => add(-duration);
  Time subtractThrowing(TimeDuration duration) => addThrowing(-duration);
  Time subtractUnchecked(TimeDuration duration) => addUnchecked(-duration);

  Result<Time, String> copyWith({
    int? hour,
    int? minute,
    int? second,
    FractionalSeconds? fraction,
  }) {
    return Time.from(
      hour ?? this.hour,
      minute ?? this.minute,
      second ?? this.second,
      fraction ?? this.fraction,
    );
  }

  Time copyWithThrowing({
    int? hour,
    int? minute,
    int? second,
    FractionalSeconds? fraction,
  }) {
    return Time.fromThrowing(
      hour ?? this.hour,
      minute ?? this.minute,
      second ?? this.second,
      fraction ?? this.fraction,
    );
  }

  Time copyWithUnchecked({
    int? hour,
    int? minute,
    int? second,
    FractionalSeconds? fraction,
  }) {
    return Time.fromUnchecked(
      hour ?? this.hour,
      minute ?? this.minute,
      second ?? this.second,
      fraction ?? this.fraction,
    );
  }

  @override
  int compareTo(Time other) {
    if (hour != other.hour) return hour.compareTo(other.hour);
    if (minute != other.minute) return minute.compareTo(other.minute);
    if (second != other.second) return second.compareTo(other.second);
    return fraction.compareTo(other.fraction);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is Time &&
            hour == other.hour &&
            minute == other.minute &&
            second == other.second &&
            fraction == other.fraction);
  }

  @override
  int get hashCode => Object.hash(hour, minute, second, fraction);

  @override
  String toString() {
    final hour = this.hour.toString().padLeft(2, '0');
    final minute = this.minute.toString().padLeft(2, '0');
    final second = this.second.toString().padLeft(2, '0');
    final fraction = this.fraction == FractionalSeconds.zero
        ? ''
        : this.fraction.value.toString().substring(1);
    return '$hour:$minute:$second$fraction';
  }

  String toJson() => toString();
}
