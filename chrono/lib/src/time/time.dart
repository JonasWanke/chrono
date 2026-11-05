import 'package:clock/clock.dart';
import 'package:deranged/deranged.dart';
import 'package:meta/meta.dart';

import '../../chrono.dart';
import '../codec.dart';
import '../utils.dart';

/// A specific time of a day, e.g., 18:24:20.
///
/// This class doesn't store or care about timezones, each day is exactly
/// 24 hours long.
@immutable
final class const Time._unchecked(
  final int hour,
  final int minute,
  final int second,
  final int subSecondNanos,
) with ComparisonOperatorsFromComparable<Time>
    implements Comparable<Time>, ChronoFormattable<TimeFormatItem> {
  new from(
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
           millis * TimeUnit.millis.nanosPer +
               micros * TimeDelta.nanosPerMicro +
               nanos,
           0,
           TimeDelta.nanosPerSecond - 1,
           'millis, micros, and nanos',
         ),
       );

  factory fromTimeSinceMidnight(TimeDelta timeSinceMidnight) {
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

    final parts = timeSinceMidnight.split({.hours, .minutes, .seconds, .nanos});
    return Time._unchecked(
      parts.hours,
      parts.minutes,
      parts.seconds,
      parts.nanos,
    );
  }

  factory nowInLocalZone({Clock? clock}) =>
      CDateTime.nowInLocalZone(clock: clock).time;
  factory nowInUtc({Clock? clock}) => CDateTime.nowInUtc(clock: clock).time;

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

  factory lerp(
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

  /// The hour number from 1 to 12.
  int get hour12 {
    final hour = this.hour % 12;
    return hour == 0 ? 12 : hour;
  }

  AmPm get amPm => hour < 12 ? .am : .pm;
  bool get isAm => hour < 12;
  bool get isPm => !isAm;

  TimeDelta get subSecond => TimeDelta(nanos: subSecondNanos);
  // TODO(JonasWanke): store only `secondsSinceMidnight` & `subSecondNanos`

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
  // TODO(JonasWanke): test with negative offset and nanos
  @useResult
  (Time, Days) overflowingAddOffset(FixedOffset offset) =>
      _overflowingAdd(offset.localMinusUtc);

  /// Subtracts given [FixedOffset] from the current time, and returns the
  /// number of days that should be added to a date as a result of the offset
  /// (either `-1`, `0`, or `1` because the offset is always less than 24h).
  ///
  // TODO(JonasWanke): support leap seconds
  // This method is similar to [overflowingSubSigned], but preserves leap
  // seconds.
  // TODO(JonasWanke): test with negative offset and nanos
  @useResult
  (Time, Days) overflowingSubOffset(FixedOffset offset) =>
      _overflowingAdd(-offset.localMinusUtc);

  /// Adds [delta] and returns the resulting time of day plus the number of days
  /// that overflowed, rounded towards negative infinity, so the time is never
  /// negative.
  (Time, Days) _overflowingAdd(TimeDelta delta) {
    final total = timeSinceMidnight + delta;
    return (
      Time.fromTimeSinceMidnight(total % TimeDelta(normalDays: 1)),
      Days(total.roundTo(.normalDays, rounding: .down)),
    );
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

  /// Represents a [Time] as an ISO 8601 string, e.g., “18:24:20.123456789”
  static const isoFormat = <TimeFormatItem>[
    .hour(),
    .literal(':'),
    .minute(),
    .literal(':'),
    .second(),
    .subsecond(.variable),
  ];

  factory parse(String string, [List<TimeFormatItem> items = isoFormat]) =>
      ChronoParser.parse(string, items).toTime();
  static ({Time time, String rest}) parseAndRest(
    String string, [
    List<TimeFormatItem> items = isoFormat,
  ]) {
    final result = ChronoParser.parseAndRest(string, items);
    return (time: result.parsed.toTime(), rest: result.rest);
  }

  @override
  String toString([List<TimeFormatItem> items = isoFormat]) =>
      ChronoFormatter.format(items, time: this);
}

enum AmPm { am, pm }

/// Encodes a [Time] as a string, defaulting to [Time.isoFormat].
class const TimeAsStringCodec([
  final List<TimeFormatItem> formatItems = Time.isoFormat,
]) extends CodecAndJsonConverter<Time, String> {
  @override
  String encode(Time input) => input.toString(formatItems);
  @override
  Time decode(String encoded) => Time.parse(encoded, formatItems);
}

// Deranged

extension RangeOfTimeExtension on Range<Time> {
  Range<CDateTime> on(Date date) => Range(date.at(start), date.at(end));

  TimeDelta get timeDuration => end.difference(start);
}

/// Encodes a [Range] of [Time]s as a string `start/end`.
class const RangeOfTimeAsStringCodec({
  final List<TimeFormatItem> formatItems = Time.isoFormat,
  final String intervalDesignator = '/',
}) extends CodecAndJsonConverter<Range<Time>, String> {
  @override
  String encode(Range<Time> input) =>
      '${input.start.toString(formatItems)}$intervalDesignator'
      '${input.end.toString(formatItems)}';
  @override
  Range<Time> decode(String encoded) {
    final (time: start, :rest) = Time.parseAndRest(encoded, formatItems);

    if (rest.length < intervalDesignator.length) {
      throw const ChronoParseException(.tooShort);
    } else if (!rest.startsWith(intervalDesignator)) {
      throw const ChronoParseException(.invalid);
    }

    final end = Time.parse(
      rest.substring(intervalDesignator.length),
      formatItems,
    );
    return Range(start, end);
  }
}
