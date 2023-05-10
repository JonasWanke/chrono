import 'package:clock/clock.dart';
import 'package:fixed/fixed.dart';
import 'package:meta/meta.dart';
import 'package:oxidized/oxidized.dart';

import 'parser.dart';
import 'period_time.dart';
import 'utils.dart';

@immutable
final class PlainTime
    with ComparisonOperatorsFromComparable<PlainTime>
    implements Comparable<PlainTime> {
  static Result<PlainTime, String> from(
    int hour, [
    int minute = 0,
    int second = 0,
    Fixed? fraction,
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
    fraction ??= FixedPlainDateTimeInternal.zero;

    return Ok(PlainTime.fromUnchecked(hour, minute, second, fraction));
  }

  factory PlainTime.fromThrowing(
    int hour, [
    int minute = 0,
    int second = 0,
    Fixed? fraction,
  ]) =>
      from(hour, minute, second, fraction).unwrap();
  PlainTime.fromUnchecked(this.hour, this.minute, this.second, this.fraction);

  static Result<PlainTime, String> fromTimeSinceMidnight(
    TimePeriod time, [
    Fixed? fraction,
  ]) {
    if (time.isNegative) {
      return Err('Time since midnight must not be negative, but was: $time');
    }
    if (time.inSeconds.value >= Seconds.perDay.value) {
      return Err(
        'Time since midnight must not be greater than a day, but was: $time',
      );
    }

    final fractionError = _validateFraction(fraction);
    if (fractionError != null) return Err(fractionError);

    return Ok(PlainTime.fromTimeSinceMidnightUnchecked(time, fraction));
  }

  factory PlainTime.fromTimeSinceMidnightThrowing(
    TimePeriod time, [
    Fixed? fraction,
  ]) =>
      fromTimeSinceMidnight(time, fraction).unwrap();
  factory PlainTime.fromTimeSinceMidnightUnchecked(
    TimePeriod time, [
    Fixed? fraction,
  ]) {
    final inSeconds = time.inSeconds;
    return PlainTime.fromUnchecked(
      inSeconds.value ~/ Seconds.perHour.value,
      (inSeconds.value % Seconds.perHour.value) ~/ Seconds.perMinute.value,
      inSeconds.value % Seconds.perMinute.value,
      fraction ?? Fixed.zero,
    );
  }

  PlainTime.fromDateTime(DateTime dateTime)
      : this.fromUnchecked(
          dateTime.hour,
          dateTime.minute,
          dateTime.second,
          Fixed.fromInt(
            dateTime.millisecond * Duration.microsecondsPerMillisecond +
                dateTime.microsecond,
            scale: 6,
          ),
        );
  PlainTime.nowInLocalZone({Clock? clockOverride})
      : this.fromDateTime((clockOverride ?? clock).now().toLocal());
  PlainTime.nowInUtc({Clock? clockOverride})
      : this.fromDateTime((clockOverride ?? clock).now().toUtc());

  factory PlainTime.fromJson(String json) => unwrapParserResult(parse(json));
  static Result<PlainTime, FormatException> parse(String value) =>
      Parser.parseTime(value);

  static String? _validateFraction(Fixed? fraction) {
    if (fraction != null &&
        (fraction.isNegative || fraction >= FixedPlainDateTimeInternal.one)) {
      return 'Invalid fraction of a second: $fraction';
    }
    return null;
  }

  static final PlainTime midnight = PlainTime.fromThrowing(0);
  static final PlainTime noon = PlainTime.fromThrowing(12);

  final int hour;
  final int minute;
  final int second;
  final Fixed fraction;

  Hours get hoursSinceMidnight => Hours(hour);
  Minutes get minutesSinceMidnight =>
      hoursSinceMidnight.inMinutes + Minutes(minute);
  Seconds get secondsSinceMidnight =>
      minutesSinceMidnight.inSeconds + Seconds(second);

  Result<PlainTime, String> copyWith({
    int? hour,
    int? minute,
    int? second,
    Fixed? fraction,
  }) {
    return PlainTime.from(
      hour ?? this.hour,
      minute ?? this.minute,
      second ?? this.second,
      fraction ?? this.fraction,
    );
  }

  PlainTime copyWithThrowing({
    int? hour,
    int? minute,
    int? second,
    Fixed? fraction,
  }) {
    return PlainTime.fromThrowing(
      hour ?? this.hour,
      minute ?? this.minute,
      second ?? this.second,
      fraction ?? this.fraction,
    );
  }

  PlainTime copyWithUnchecked({
    int? hour,
    int? minute,
    int? second,
    Fixed? fraction,
  }) {
    return PlainTime.fromUnchecked(
      hour ?? this.hour,
      minute ?? this.minute,
      second ?? this.second,
      fraction ?? this.fraction,
    );
  }

  @override
  int compareTo(PlainTime other) {
    if (hour != other.hour) return hour.compareTo(other.hour);
    if (minute != other.minute) return minute.compareTo(other.minute);
    if (second != other.second) return second.compareTo(other.second);
    return fraction.compareTo(other.fraction);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is PlainTime &&
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
    final fraction =
        this.fraction.isZero ? '' : this.fraction.toString().substring(1);
    return 'T$hour:$minute:$second$fraction';
  }

  String toJson() => toString();
}
