import 'dart:core';
import 'dart:core' as core;

import 'package:clock/clock.dart';
import 'package:meta/meta.dart';
import 'package:oxidized/oxidized.dart';

import '../parser.dart';
import '../utils.dart';
import 'period.dart';

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
  Time.fromUnchecked(this.hour, this.minute, this.second, this.fraction);

  static Result<Time, String> fromTimeSinceMidnight(TimePeriod time) {
    if (time.isNegative) {
      return Err('Time since midnight must not be negative, but was: $time');
    }
    if (time.inFractionalSeconds.value >= FractionalSeconds.perDay.value) {
      return Err(
        'Time since midnight must not be ≥ a day, but was: $time',
      );
    }

    return Ok(Time.fromTimeSinceMidnightUnchecked(time));
  }

  factory Time.fromTimeSinceMidnightThrowing(TimePeriod time) =>
      fromTimeSinceMidnight(time).unwrap();
  factory Time.fromTimeSinceMidnightUnchecked(TimePeriod time) {
    final (inSeconds, fraction) = time.inSecondsAndFraction;
    final (hours, minutes, seconds) = inSeconds.inHoursAndMinutesAndSeconds;
    return Time.fromUnchecked(
      hours.value,
      minutes.value,
      seconds.value,
      fraction,
    );
  }

  Time.fromDart(core.DateTime dateTime)
      : this.fromUnchecked(
          dateTime.hour,
          dateTime.minute,
          dateTime.second,
          FractionalSeconds.millisecond * dateTime.millisecond +
              FractionalSeconds.microsecond * dateTime.microsecond,
        );
  Time.nowInLocalZone({Clock? clockOverride})
      : this.fromDart((clockOverride ?? clock).now().toLocal());
  Time.nowInUtc({Clock? clockOverride})
      : this.fromDart((clockOverride ?? clock).now().toUtc());

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

  Result<Time, String> add(TimePeriod period) =>
      Time.fromTimeSinceMidnight(_add(period));
  Time addThrowing(TimePeriod period) =>
      Time.fromTimeSinceMidnightThrowing(_add(period));
  Time addUnchecked(TimePeriod period) =>
      Time.fromTimeSinceMidnightUnchecked(_add(period));
  FractionalSeconds _add(TimePeriod period) =>
      fractionalSecondsSinceMidnight + period.inFractionalSeconds;

  Result<Time, String> subtract(TimePeriod period) => add(-period);
  Time subtractThrowing(TimePeriod period) => addThrowing(-period);
  Time subtractUnchecked(TimePeriod period) => addUnchecked(-period);

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
