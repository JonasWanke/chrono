import 'dart:core' as core;
import 'dart:core';

import 'package:clock/clock.dart';
import 'package:meta/meta.dart';
import 'package:oxidized/oxidized.dart';

import '../date_time/date_time.dart';
import '../json.dart';
import '../parser.dart';
import '../rounding.dart';
import '../utils.dart';
import 'duration.dart';

/// A specific time of a day, e.g., 18:24:20.
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

    return Ok(Time._(hour, minute, second, fraction));
  }

  const Time._(this.hour, this.minute, this.second, this.fraction);

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

    final (asSeconds, fraction) = timeSinceMidnight.asSecondsAndFraction;
    final (hours, minutes, seconds) = asSeconds.asHoursAndMinutesAndSeconds;
    final time =
        Time._(hours.inHours, minutes.inMinutes, seconds.inSeconds, fraction);
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
    int factorPrecisionAfterComma = 8,
  }) {
    final duration = TimeDuration.lerpNullable(
      a?.fractionalSecondsSinceMidnight,
      b?.fractionalSecondsSinceMidnight,
      t,
      factorPrecisionAfterComma: factorPrecisionAfterComma,
    );
    if (duration == null) return null;

    return Time.fromTimeSinceMidnight(duration);
  }

  static Result<Time, String> lerp(
    Time a,
    Time b,
    double t, {
    int factorPrecisionAfterComma = 8,
  }) {
    return Time.fromTimeSinceMidnight(
      TimeDuration.lerp(
        a.fractionalSecondsSinceMidnight,
        b.fractionalSecondsSinceMidnight,
        t,
        factorPrecisionAfterComma: factorPrecisionAfterComma,
      ),
    );
  }

  static String? _validateFraction(FractionalSeconds? fraction) {
    if (fraction != null &&
        (fraction.isNegative || fraction >= FractionalSeconds.second)) {
      return 'Invalid fraction of a second: $fraction';
    }
    return null;
  }

  static final Time midnight = Time.from(0).unwrap();
  static final Time noon = Time.from(12).unwrap();

  final int hour;
  final int minute;
  final int second;
  final FractionalSeconds fraction;

  Hours get hoursSinceMidnight => Hours(hour);
  Minutes get minutesSinceMidnight => Minutes(minute) + hoursSinceMidnight;
  Seconds get secondsSinceMidnight => Seconds(second) + minutesSinceMidnight;
  FractionalSeconds get fractionalSecondsSinceMidnight =>
      fraction + secondsSinceMidnight;

  Result<Time, String> add(TimeDuration duration) {
    return Time.fromTimeSinceMidnight(
      fractionalSecondsSinceMidnight + duration.asFractionalSeconds,
    );
  }

  Result<Time, String> subtract(TimeDuration duration) => add(-duration);

  /// Returns `this - other`.
  FractionalSeconds difference(Time other) =>
      fractionalSecondsSinceMidnight - other.fractionalSecondsSinceMidnight;

  Time roundToMultipleOf(
    TimeDuration duration, {
    Rounding rounding = Rounding.nearestAwayFromZero,
  }) {
    return Time.fromTimeSinceMidnight(
      fractionalSecondsSinceMidnight.roundToMultipleOf(
        duration,
        rounding: rounding,
      ),
    ).unwrapOrElse((_) {
      // Rounding could round up the value to, e.g., 24 hours. In that case, we
      // floor the value to return the closest value in our range.
      return Time.fromTimeSinceMidnight(
        fractionalSecondsSinceMidnight.roundToMultipleOf(
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
    FractionalSeconds? fraction,
  }) {
    return Time.from(
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
    final fraction = this.fraction.inFractionalSeconds.scale == 0
        ? ''
        : this.fraction.inFractionalSeconds.toString().substring(1);
    return '$hour:$minute:$second$fraction';
  }
}

class TimeAsIsoStringJsonConverter
    extends JsonConverterWithParserResult<Time, String> {
  const TimeAsIsoStringJsonConverter();

  @override
  Result<Time, FormatException> resultFromJson(String json) =>
      Parser.parseTime(json);
  @override
  String toJson(Time object) => object.toString();
}
