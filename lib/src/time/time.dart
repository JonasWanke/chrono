import 'package:clock/clock.dart';
import 'package:meta/meta.dart';
import 'package:oxidized/oxidized.dart';

import '../parser.dart';
import '../utils.dart';
import 'period.dart';

@immutable
final class PlainTime
    with ComparisonOperatorsFromComparable<PlainTime>
    implements Comparable<PlainTime> {
  static Result<PlainTime, String> from(
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

    return Ok(PlainTime.fromUnchecked(hour, minute, second, fraction));
  }

  factory PlainTime.fromThrowing(
    int hour, [
    int minute = 0,
    int second = 0,
    FractionalSeconds? fraction,
  ]) =>
      from(hour, minute, second, fraction).unwrap();
  PlainTime.fromUnchecked(this.hour, this.minute, this.second, this.fraction);

  static Result<PlainTime, String> fromTimeSinceMidnight(TimePeriod time) {
    if (time.isNegative) {
      return Err('Time since midnight must not be negative, but was: $time');
    }
    if (time.inFractionalSeconds.value >= FractionalSeconds.perDay.value) {
      return Err(
        'Time since midnight must not be ≥ a day, but was: $time',
      );
    }

    return Ok(PlainTime.fromTimeSinceMidnightUnchecked(time));
  }

  factory PlainTime.fromTimeSinceMidnightThrowing(TimePeriod time) =>
      fromTimeSinceMidnight(time).unwrap();
  factory PlainTime.fromTimeSinceMidnightUnchecked(TimePeriod time) {
    final (inSeconds, fraction) = time.inSecondsAndFraction;
    final (hours, minutes, seconds) = inSeconds.inHoursAndMinutesAndSeconds;
    return PlainTime.fromUnchecked(
      hours.value,
      minutes.value,
      seconds.value,
      fraction,
    );
  }

  PlainTime.fromDateTime(DateTime dateTime)
      : this.fromUnchecked(
          dateTime.hour,
          dateTime.minute,
          dateTime.second,
          FractionalSeconds.millisecond * dateTime.millisecond +
              FractionalSeconds.microsecond * dateTime.microsecond,
        );
  PlainTime.nowInLocalZone({Clock? clockOverride})
      : this.fromDateTime((clockOverride ?? clock).now().toLocal());
  PlainTime.nowInUtc({Clock? clockOverride})
      : this.fromDateTime((clockOverride ?? clock).now().toUtc());

  factory PlainTime.fromJson(String json) => unwrapParserResult(parse(json));
  static Result<PlainTime, FormatException> parse(String value) =>
      Parser.parseTime(value);

  static String? _validateFraction(FractionalSeconds? fraction) {
    if (fraction != null &&
        (fraction.isNegative || fraction >= FractionalSeconds.second)) {
      return 'Invalid fraction of a second: $fraction';
    }
    return null;
  }

  static final PlainTime midnight = PlainTime.fromThrowing(0);
  static final PlainTime noon = PlainTime.fromThrowing(12);

  final int hour;
  final int minute;
  final int second;
  final FractionalSeconds fraction;

  Hours get hoursSinceMidnight => Hours(hour);
  Minutes get minutesSinceMidnight =>
      hoursSinceMidnight.inMinutes + Minutes(minute);
  Seconds get secondsSinceMidnight =>
      minutesSinceMidnight.inSeconds + Seconds(second);
  FractionalSeconds get fractionalSecondsSinceMidnight =>
      secondsSinceMidnight.inFractionalSeconds + fraction;

  Result<PlainTime, String> add(TimePeriod period) =>
      PlainTime.fromTimeSinceMidnight(_add(period));
  PlainTime addThrowing(TimePeriod period) =>
      PlainTime.fromTimeSinceMidnightThrowing(_add(period));
  PlainTime addUnchecked(TimePeriod period) =>
      PlainTime.fromTimeSinceMidnightUnchecked(_add(period));
  FractionalSeconds _add(TimePeriod period) =>
      fractionalSecondsSinceMidnight + period.inFractionalSeconds;

  Result<PlainTime, String> subtract(TimePeriod period) => add(-period);
  PlainTime subtractThrowing(TimePeriod period) => addThrowing(-period);
  PlainTime subtractUnchecked(TimePeriod period) => addUnchecked(-period);

  Result<PlainTime, String> copyWith({
    int? hour,
    int? minute,
    int? second,
    FractionalSeconds? fraction,
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
    FractionalSeconds? fraction,
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
    FractionalSeconds? fraction,
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
    final fraction = this.fraction == FractionalSeconds.zero
        ? ''
        : this.fraction.toString().substring(1);
    return 'T$hour:$minute:$second$fraction';
  }

  String toJson() => toString();
}
